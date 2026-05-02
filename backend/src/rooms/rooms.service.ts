import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { spawn } from 'child_process';
import { randomBytes, createHash, randomInt } from 'crypto';
import { RoomsGateway } from './rooms.gateway';
import { Room } from './room.types';
import { ConfigService } from '@nestjs/config';

const ROOM_SIZE = 2;
const GAME_IP = '34.159.203.1';
const GAME_BASE_PORT = 9000;
const GAME_PORT_RANGE_SIZE = 1000;
const GAME_START_TIMEOUT_MS = 45_000;

@Injectable()
export class RoomsService {
  private readonly rooms = new Map<string, Room>();
  private nextGamePort = GAME_BASE_PORT;

  constructor(
    private readonly roomsGateway: RoomsGateway,
    private readonly config: ConfigService,
  ) {
    this.roomsGateway.onPlayerDisconnected((playerId) => {
      this.handlePlayerDisconnected(playerId);
    });
  }

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

  joinRoom(code: string, playerId: string): { ok: true } {
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

    return { ok: true };
  }

  startRoom(code: string): { ok: true } {
    const room = this.rooms.get(code);
    if (!room) {
      throw new NotFoundException('Room not found');
    }

    if (room.status === 'ready') {
      return { ok: true };
    }

    if (room.status !== 'starting') {
      throw new BadRequestException('Room is not starting');
    }

    if (!room.ip || !room.port) {
      throw new BadRequestException('Room has no allocated endpoint');
    }

    if (!room.gameTokens) {
      throw new BadRequestException('Room has no game tokens');
    }

    if (room.startupTimer) {
      clearTimeout(room.startupTimer);
      delete room.startupTimer;
    }

    room.status = 'ready';

    let delivered = true;
    for (const playerId of room.members) {
      const gameToken = room.gameTokens![playerId];
      delivered =
        this.roomsGateway.sendRoomStart(playerId, room.ip, room.port, gameToken) &&
        delivered;
    }
    if (!delivered) {
      this.failRoom(room, true);
    }

    return { ok: true };
  }

  endRoom(code: string): { ok: true } {
    const room = this.rooms.get(code);
    if (!room) {
      return { ok: true };
    }

    spawn('docker', ['stop', room.code], {
      stdio: 'inherit',
    });
    if (room.startupTimer) {
      clearTimeout(room.startupTimer);
    }

    this.rooms.delete(code);

    return { ok: true };
  }

  private handlePlayerDisconnected(playerId: string): void {
    for (const room of this.rooms.values()) {
      if (!room.members.includes(playerId)) continue;
      if (room.status === 'waiting') {
        for (const memberId of room.members) {
          if (memberId !== playerId) {
            this.roomsGateway.sendRoomFailed(memberId);
          }
        }
        this.rooms.delete(room.code);
        continue;
      }
      if (room.status === 'starting') {
        this.failRoom(room, true);
      }
    }
  }

  private startServer(room: Room): void {
    if (room.status !== 'waiting') {
      return;
    }
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
    room.startupTimer = setTimeout(() => {
      if (room.status !== 'starting') return;
      this.failRoom(room, true);
    }, GAME_START_TIMEOUT_MS);
    
    const serverCallbackSecret = this.config.getOrThrow<string>('SERVER_CALLBACK_SECRET');

    const args = [
      'run',
      '-d',
      '--rm',
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
      `server_callback_secret=${serverCallbackSecret}`,
    ];

    let cleanupFinished = false;
    const cleanup = spawn('docker', ['rm', '-f', room.code], {
      stdio: 'ignore',
    });
    cleanup.once('error', () => {
      if (cleanupFinished) return;
      cleanupFinished = true;
      this.runServerContainer(room, args);
    });
    cleanup.once('close', () => {
      if (cleanupFinished) return;
      cleanupFinished = true;
      this.runServerContainer(room, args);
    });
  }

  private runServerContainer(room: Room, args: string[]): void {
    if (room.status !== 'starting') return;
    const child = spawn('docker', args, { stdio: 'inherit' });
    child.once('error', () => {
      this.failRoom(room, false);
    });
    child.once('exit', (code) => {
      if (code !== 0 && room.status === 'starting') {
        this.failRoom(room, false);
      }
    });
  }

  private failRoom(room: Room, stopContainer: boolean): void {
    room.status = 'failed';
    if (room.startupTimer) {
      clearTimeout(room.startupTimer);
      delete room.startupTimer;
    }
    for (const playerId of room.members) {
      this.roomsGateway.sendRoomFailed(playerId);
    }
    if (stopContainer) {
      spawn('docker', ['stop', room.code], { stdio: 'ignore' });
    }
    this.rooms.delete(room.code);
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
