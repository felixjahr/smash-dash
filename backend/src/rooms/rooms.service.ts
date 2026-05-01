import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { spawn } from 'child_process';
import { randomBytes, createHash, randomInt } from 'crypto';
import { RoomsGateway } from './rooms.gateway';
import { Room } from './room.types';

const ROOM_SIZE = 2;
const GAME_IP = '34.159.203.1';
const GAME_BASE_PORT = 9000;
const GAME_PORT_RANGE_SIZE = 1000;

@Injectable()
export class RoomsService {
  private readonly rooms = new Map<string, Room>();
  private nextGamePort = GAME_BASE_PORT;

  constructor(private readonly roomsGateway: RoomsGateway) {}

  createRoom(playerId: string): { code: string } {
    if (!this.roomsGateway.hasPlayer(playerId)) {
      throw new BadRequestException('Player websocket not connected');
    }

    const code = this.generateRoomCode();

    const room: Room = {
      code,
      gameId: 'draft',
      mapId: this.pickRandomMap(),
      members: [playerId],
      status: 'waiting',
    };

    this.rooms.set(code, room);

    return { code };
  }

  joinRoom(code: string, playerId: string): void {
    if (!this.roomsGateway.hasPlayer(playerId)) {
      throw new BadRequestException('Player websocket not connected');
    }

    const room = this.rooms.get(code);
    if (!room) {
      throw new NotFoundException('Room not found');
    }

    if (room.status !== 'waiting') {
      throw new BadRequestException('Room already started');
    }

    if (room.members.includes(playerId)) {
      throw new BadRequestException('Player already in room');
    }

    if (room.members.length >= ROOM_SIZE) {
      throw new BadRequestException('Room is full');
    }

    room.members.push(playerId);

    if (room.members.length === ROOM_SIZE) {
      this.startServer(room);
    }
  }

  startRoom(code: string): void {
    const room = this.rooms.get(code);
    if (!room) {
      throw new NotFoundException('Room not found');
    }

    if (!room.ip || !room.port) {
      throw new BadRequestException('Room has no allocated endpoint');
    }

    room.status = 'ready';

    for (const playerId of room.members) {
      const gameToken = room.gameTokens![playerId];
      this.roomsGateway.sendRoomStart(playerId, room.ip, room.port, gameToken);
    }
  }

  endRoom(code: string): void {
    const room = this.rooms.get(code);
    if (!room) {
      throw new NotFoundException('Room not found');
    }

    spawn('docker', ['stop', room.code], {
      stdio: 'inherit',
    });

    this.rooms.delete(code);
  }

  private startServer(room: Room): void {
    room.status = 'starting';
    room.port = this.allocatePort();
    room.ip = GAME_IP;

    const gameTokens: Record<string, string> = {};
    const allowedPlayers: Record<string, string> = {};
    for (const playerId of room.members) {
      const gameToken = randomBytes(32).toString('base64url');
      gameTokens[playerId] = gameToken;
      const gameTokenHash = createHash('sha256').update(gameToken).digest('hex');
      allowedPlayers[gameTokenHash] = playerId;
    }
    room.gameTokens = gameTokens;

    const args = [
      'run',
      '-d',
      '--name',
      room.code,

      '--platform',
      'linux/amd64',

      '--network',
      'stickman-server_default',

      '-p',
      `${room.port}:${room.port}/udp`,

      'stickman-godot-server:latest',

      '--headless',
      `port=${room.port}`,
      `code=${room.code}`,
      `game_id=${room.gameId}`,
      `map_id=${room.mapId}`,
      `allowed_players=${JSON.stringify(allowedPlayers)}`,
    ];

    spawn('docker', args, { stdio: 'inherit' });
  }

  private allocatePort(): number {
    const port = this.nextGamePort;
    this.nextGamePort =
      GAME_BASE_PORT +
      ((this.nextGamePort - GAME_BASE_PORT + 1) % GAME_PORT_RANGE_SIZE);

    return port;
  }

  private generateRoomCode(): string {
    let code = '';

    do {
      code = randomInt(0, 10000).toString().padStart(4, '0');
    } while (this.rooms.has(code));

    return code;
  }

  private pickRandomMap(): string {
    const maps = ['forest', 'mountains'];
    return maps[Math.floor(Math.random() * maps.length)];
  }
}