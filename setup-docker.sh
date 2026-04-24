#!/bin/bash
# ================================================================
# Local AI Stack - Docker Setup Script
# ================================================================
# Installs Docker (if needed), pulls images, starts containers,
# and downloads AI models into the Ollama container.
#
# Requirements: Ubuntu/Debian-based Linux, Internet, 16+ GB RAM
# Run as: chmod +x setup-docker.sh && ./setup-docker.sh
# ================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODELS=("deepseek-r1:1.5b" "deepseek-r1:7b" "qwen2.5:7b")
OPEN_WEBUI_PORT=8080

# ---- Helper Functions ----
write_step() {
    echo ""
    echo -e "\033[33m[$1] $2\033[0m"
    echo "--------------------------------------------------"
}

write_ok() {
    echo -e "  \033[32m[OK] $1\033[0m"
}

write_info() {
    echo -e "  \033[37m$1\033[0m"
}

write_err() {
    echo -e "  \033[31m[ERROR] $1\033[0m"
}

command_exists() {
    command -v "$1" &> /dev/null
}

# ---- Start ----
echo ""
echo -e "\033[36m================================================================\033[0m"
echo -e "\033[36m  Local AI Stack - Docker Setup\033[0m"
echo -e "\033[36m================================================================\033[0m"
echo "  Install Dir : $SCRIPT_DIR"
echo "  Models      : ${MODELS[*]}"
echo "  Frontend    : Open WebUI on port $OPEN_WEBUI_PORT"
echo -e "\033[36m================================================================\033[0m"

# ================================================================
# STEP 1: Check prerequisites
# ================================================================
write_step "1/4" "Checking prerequisites..."

TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 8 ]; then
    write_err "Only ${TOTAL_RAM} GB RAM detected. Minimum 8 GB required (16 GB recommended)."
    exit 1
fi
write_ok "RAM: ${TOTAL_RAM} GB detected"

# ================================================================
# STEP 2: Install Docker
# ================================================================
write_step "2/4" "Checking Docker installation..."

if command_exists docker; then
    DOCKER_VER=$(docker --version 2>&1)
    write_ok "Docker already installed ($DOCKER_VER)"
else
    write_info "Installing Docker via official script..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    write_ok "Docker installed. You may need to log out and back in for group changes."
fi

# Check docker compose
if docker compose version &> /dev/null; then
    write_ok "Docker Compose is available"
elif command_exists docker-compose; then
    write_ok "Docker Compose (standalone) is available"
else
    write_info "Installing Docker Compose plugin..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    write_ok "Docker Compose plugin installed"
fi

# Ensure Docker daemon is running
if ! docker info &> /dev/null; then
    write_info "Starting Docker daemon..."
    sudo systemctl start docker
    sudo systemctl enable docker
    write_ok "Docker daemon started"
fi

# ================================================================
# STEP 3: Start containers
# ================================================================
write_step "3/4" "Starting Ollama + Open WebUI containers..."

cd "$SCRIPT_DIR"
docker compose pull
write_ok "Docker images pulled"

docker compose up -d
write_ok "Containers started"

# Wait for Ollama to be ready
write_info "Waiting for Ollama to be ready..."
for i in $(seq 1 30); do
    if docker exec ollama ollama list &> /dev/null; then
        break
    fi
    sleep 2
done
write_ok "Ollama is ready"

# ================================================================
# STEP 4: Download AI models
# ================================================================
write_step "4/4" "Downloading AI models into Ollama container..."

for MODEL in "${MODELS[@]}"; do
    write_info "Checking model: $MODEL"
    if docker exec ollama ollama list 2>&1 | grep -q "${MODEL%%:*}"; then
        write_ok "$MODEL already downloaded"
    else
        write_info "Downloading $MODEL (this may take a while)..."
        if docker exec ollama ollama pull "$MODEL"; then
            write_ok "$MODEL downloaded successfully"
        else
            write_err "Failed to download $MODEL. Retry later with: docker exec ollama ollama pull $MODEL"
        fi
    fi
done

# ================================================================
# DONE
# ================================================================
echo ""
echo -e "\033[32m================================================================\033[0m"
echo -e "\033[32m  Docker Setup Complete!\033[0m"
echo -e "\033[32m================================================================\033[0m"
echo ""
echo "  Installed Models:"
docker exec ollama ollama list 2>&1 | while IFS= read -r line; do echo "    $line"; done
echo ""
echo "  Containers:"
docker compose ps 2>&1 | while IFS= read -r line; do echo "    $line"; done
echo ""
echo "  Open WebUI: http://localhost:$OPEN_WEBUI_PORT"
echo "  Ollama API: http://localhost:11434"
echo "  (Create an admin account on first visit - fully local, no cloud)"
echo ""
echo "  Useful commands:"
echo "    docker compose up -d       # Start the stack"
echo "    docker compose down        # Stop the stack"
echo "    docker compose logs -f     # View logs"
echo "    ./start-docker.sh          # Quick start/stop helper"
echo ""
echo "  To add more models later:"
echo "    docker exec ollama ollama pull phi4-mini"
echo "    docker exec ollama ollama pull codellama:7b"
echo "    docker exec ollama ollama pull llama3.1:8b"
echo ""
echo -e "\033[32m================================================================\033[0m"
