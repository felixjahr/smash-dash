#!/bin/bash
set -e

# =========================
# CONFIG
# =========================

PROJECT_ID="stickman-draft-game-489210"
VM_NAME="stickman-server"
VM_ZONE="europe-west3-c"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="/tmp/stickman-deploy"

BACKEND_DIR="$REPO_ROOT/backend"
GODOT_PROJECT_DIR="$REPO_ROOT/godot"

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
GODOT_EXPORT_PRESET="Server"

REMOTE_DIR="~/stickman-server"

# =========================
# CLEAN TEMP FOLDER
# =========================

echo "Cleaning temp deploy folder..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR/backend"
mkdir -p "$TEMP_DIR/godot-server"

# =========================
# BUILD BACKEND
# =========================

echo "Building backend locally..."

cd "$BACKEND_DIR"
npm install
npm run build
cd "$REPO_ROOT"

# =========================
# COPY BACKEND SOURCE
# =========================

echo "Copying backend..."
rsync -a \
  --progress \
  --exclude node_modules \
  --exclude .git \
  "$BACKEND_DIR/" "$TEMP_DIR/backend/"
#--exclude dist \

# =========================
# EXPORT GODOT SERVER
# =========================

echo "Exporting Godot server..."

"$GODOT_BIN" \
  --headless \
  --path "$GODOT_PROJECT_DIR" \
  --export-release "$GODOT_EXPORT_PRESET" \
  "$TEMP_DIR/godot-server/server.x86_64"

# =========================
# COPY DEPLOY FILES
# =========================

echo "Copying deploy files..."

cp "$REPO_ROOT/deploy/docker-compose.yml" "$TEMP_DIR/docker-compose.yml"
cp "$REPO_ROOT/deploy/godot-server.Dockerfile" "$TEMP_DIR/godot-server/Dockerfile"
cp "$REPO_ROOT/deploy/godot-server.dockerignore" "$TEMP_DIR/godot-server/.dockerignore"
cp "$REPO_ROOT/deploy/backend.Dockerfile" "$TEMP_DIR/backend/Dockerfile"
cp "$REPO_ROOT/deploy/backend.dockerignore" "$TEMP_DIR/backend/.dockerignore"

# =========================
# UPLOAD TO VM
# =========================

echo "Uploading to VM..."

rsync -a \
  --progress \
  --delete \
  --exclude node_modules \
  --exclude .git \
  -e "ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=10" \
  "$TEMP_DIR/" \
  "$VM_NAME.$VM_ZONE.$PROJECT_ID:~/stickman-server/"
#--exclude dist \

# =========================
# DEPLOY ON VM
# =========================

echo "Deploying on VM..."

gcloud compute ssh "$VM_NAME" \
  --project="$PROJECT_ID" \
  --zone="$VM_ZONE" \
  --command="
    cd ~/stickman-server &&
    docker compose down &&
    docker compose build
    docker compose up backend postgres
  "

echo "Deployment complete."