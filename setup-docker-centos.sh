#!/bin/bash
# ================================================================
# Local AI Stack - Docker Setup Script (CentOS 7, 7 GB RAM)
# ================================================================
# Installs Docker via yum, pulls images, starts containers,
# and downloads only the 1.5B model (safe for 7 GB RAM).
#
# Requirements: CentOS 7, Internet connection, 4+ GB RAM
# Run as: chmod +x setup-docker-centos.sh && ./setup-docker-centos.sh
# ================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose-centos.yml"
# Only 1.5B model for 7 GB RAM — 7B models need 12+ GB
MODELS=("deepseek-r1:1.5b")
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

write_warn() {
    echo -e "  \033[33m[WARN] $1\033[0m"
}

write_err() {
    echo -e "  \033[31m[ERROR] $1\033[0m"
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Detect compose command (standalone docker-compose for CentOS 7)
get_compose_cmd() {
    if command_exists docker-compose; then
        echo "docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo ""
    fi
}

# ---- Start ----
echo ""
echo -e "\033[36m================================================================\033[0m"
echo -e "\033[36m  Local AI Stack - Docker Setup (CentOS 7)\033[0m"
echo -e "\033[36m================================================================\033[0m"
echo "  Install Dir : $SCRIPT_DIR"
echo "  Models      : ${MODELS[*]}"
echo "  Frontend    : Open WebUI on port $OPEN_WEBUI_PORT"
echo "  Compose File: $COMPOSE_FILE"
echo -e "\033[36m================================================================\033[0m"

# ================================================================
# STEP 1: Check prerequisites
# ================================================================
write_step "1/4" "Checking prerequisites..."

if ! command_exists curl; then
    write_info "Installing curl..."
    sudo yum install -y curl
fi
write_ok "curl is available"

TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 4 ]; then
    write_err "Only ${TOTAL_RAM} GB RAM detected. Minimum 4 GB required."
    exit 1
fi
if [ "$TOTAL_RAM" -lt 8 ]; then
    write_warn "${TOTAL_RAM} GB RAM detected. Only 1.5B models will work reliably."
    write_warn "7B models need 12+ GB RAM. Do NOT pull 7B models on this system."
fi
write_ok "RAM: ${TOTAL_RAM} GB detected"

# ================================================================
# STEP 2: Install Docker & Docker Compose
# ================================================================
write_step "2/4" "Checking Docker installation..."

if command_exists docker; then
    DOCKER_VER=$(docker --version 2>&1)
    write_ok "Docker already installed ($DOCKER_VER)"
else
    write_info "Installing Docker CE on CentOS 7..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    write_ok "Docker installed successfully"
    write_warn "You may need to log out and back in for docker group to take effect."
fi

# Ensure Docker daemon is running
if ! docker info &> /dev/null 2>&1; then
    write_info "Starting Docker daemon..."
    sudo systemctl start docker
    sudo systemctl enable docker
    write_ok "Docker daemon started"
else
    write_ok "Docker daemon is running"
fi

# Install docker-compose (standalone binary for CentOS 7)
COMPOSE_CMD=$(get_compose_cmd)
if [ -n "$COMPOSE_CMD" ]; then
    COMPOSE_VER=$($COMPOSE_CMD version 2>&1 | head -1)
    write_ok "Docker Compose already available ($COMPOSE_VER)"
else
    write_info "Installing Docker Compose (standalone binary)..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    COMPOSE_CMD="docker-compose"
    write_ok "Docker Compose installed ($($COMPOSE_CMD version 2>&1 | head -1))"
fi

# ================================================================
# STEP 3: Start containers
# ================================================================
write_step "3/4" "Starting Ollama + Open WebUI containers..."

cd "$SCRIPT_DIR"
$COMPOSE_CMD -f "$COMPOSE_FILE" pull
write_ok "Docker images pulled"

$COMPOSE_CMD -f "$COMPOSE_FILE" up -d
write_ok "Containers started (memory-limited: Ollama 4G, WebUI 2G)"

# Wait for Ollama to be ready
write_info "Waiting for Ollama to be ready..."
for i in $(seq 1 30); do
    if docker exec ollama ollama list &> /dev/null 2>&1; then
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
        write_info "Downloading $MODEL (~1.1 GB)..."
        if docker exec ollama ollama pull "$MODEL"; then
            write_ok "$MODEL downloaded successfully"
        else
            write_err "Failed to download $MODEL. Retry with: docker exec ollama ollama pull $MODEL"
        fi
    fi
done

# ================================================================
# DONE
# ================================================================
echo ""
echo -e "\033[32m================================================================\033[0m"
echo -e "\033[32m  Docker Setup Complete! (CentOS 7)\033[0m"
echo -e "\033[32m================================================================\033[0m"
echo ""
echo "  Installed Models:"
docker exec ollama ollama list 2>&1 | while IFS= read -r line; do echo "    $line"; done
echo ""
echo "  Containers:"
$COMPOSE_CMD -f "$COMPOSE_FILE" ps 2>&1 | while IFS= read -r line; do echo "    $line"; done
echo ""
echo "  Open WebUI: http://localhost:$OPEN_WEBUI_PORT"
echo "  Ollama API: http://localhost:11434"
echo "  (Create an admin account on first visit - fully local, no cloud)"
echo ""
echo -e "\033[33m  RAM WARNING (7 GB system):\033[0m"
echo "    - Use ONLY deepseek-r1:1.5b (already installed)"
echo "    - Do NOT pull 7B models — they will crash with OOM"
echo "    - Close other heavy apps before using AI"
echo ""
echo "  Useful commands:"
echo "    ./start-docker-centos.sh          # Start the stack"
echo "    ./start-docker-centos.sh stop     # Stop the stack"
echo "    ./start-docker-centos.sh logs     # View logs"
echo "    docker exec ollama ollama list    # List models"
echo ""
echo -e "\033[32m================================================================\033[0m"
