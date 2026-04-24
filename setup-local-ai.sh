#!/bin/bash
# ================================================================
# Local AI Stack - Full Setup Script (From Scratch) - Linux
# ================================================================
# This script sets up a complete local AI stack on a Linux machine:
#   - Ollama (AI model backend)
#   - Open WebUI (ChatGPT-like frontend)
#   - DeepSeek-R1 & Qwen2.5 models
#
# Requirements: Ubuntu/Debian-based Linux, Internet connection, 16+ GB RAM
# Run as: chmod +x setup-local-ai.sh && ./setup-local-ai.sh
# ================================================================

set -e

# ---- Configuration ----
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_VERSION="3.11"
OPEN_WEBUI_PORT=8080
MODELS=("deepseek-r1:1.5b" "deepseek-r1:7b" "qwen2.5:7b")

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
echo -e "\033[36m  Local AI Stack - Automated Setup (Linux)\033[0m"
echo -e "\033[36m================================================================\033[0m"
echo "  Install Dir : $INSTALL_DIR"
echo "  Models      : ${MODELS[*]}"
echo "  Frontend    : Open WebUI on port $OPEN_WEBUI_PORT"
echo -e "\033[36m================================================================\033[0m"

# ================================================================
# STEP 1: Check prerequisites
# ================================================================
write_step "1/7" "Checking prerequisites..."

if ! command_exists curl; then
    write_err "curl is not available. Installing..."
    sudo apt-get update && sudo apt-get install -y curl
fi
write_ok "curl is available"

# Check RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 8 ]; then
    write_err "Only ${TOTAL_RAM} GB RAM detected. Minimum 8 GB required (16 GB recommended)."
    exit 1
fi
write_ok "RAM: ${TOTAL_RAM} GB detected"

# ================================================================
# STEP 2: Install Ollama
# ================================================================
write_step "2/7" "Installing Ollama (AI model backend)..."

if command_exists ollama; then
    OLLAMA_VER=$(ollama --version 2>&1 || true)
    write_ok "Ollama already installed ($OLLAMA_VER)"
else
    write_info "Installing Ollama via official install script..."
    curl -fsSL https://ollama.com/install.sh | sh
    if ! command_exists ollama; then
        write_err "Failed to install Ollama. Please install manually from https://ollama.com/download"
        exit 1
    fi
    write_ok "Ollama installed successfully"
fi

# Ensure Ollama is running
if ! pgrep -x "ollama" > /dev/null 2>&1; then
    write_info "Starting Ollama server..."
    ollama serve &> /dev/null &
    sleep 5
fi
write_ok "Ollama server is running"

# ================================================================
# STEP 3: Install Python 3.11
# ================================================================
write_step "3/7" "Installing Python ${PYTHON_VERSION}..."

PY_CMD=""

# Check if python3.11 is available
if command_exists python3.11; then
    PY_VER=$(python3.11 --version 2>&1)
    PY_CMD="python3.11"
    write_ok "Python 3.11 already installed ($PY_VER)"
elif command_exists python3 && python3 --version 2>&1 | grep -q "3\.11"; then
    PY_VER=$(python3 --version 2>&1)
    PY_CMD="python3"
    write_ok "Python 3.11 already installed ($PY_VER)"
else
    write_info "Installing Python 3.11 via apt..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
    if ! command_exists python3.11; then
        write_err "Failed to install Python 3.11. Please install manually."
        exit 1
    fi
    PY_CMD="python3.11"
    write_ok "Python 3.11 installed successfully"
fi

# ================================================================
# STEP 4: Create Python virtual environment
# ================================================================
write_step "4/7" "Setting up Python virtual environment..."

VENV_DIR="$INSTALL_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

if [ -f "$VENV_PYTHON" ]; then
    EXISTING_VER=$("$VENV_PYTHON" --version 2>&1)
    if echo "$EXISTING_VER" | grep -q "3\.11"; then
        write_ok "Virtual environment already exists ($EXISTING_VER)"
    else
        write_info "Existing venv is wrong Python version ($EXISTING_VER). Recreating..."
        rm -rf "$VENV_DIR"
        $PY_CMD -m venv "$VENV_DIR"
        write_ok "Virtual environment recreated with Python 3.11"
    fi
else
    write_info "Creating virtual environment..."
    $PY_CMD -m venv "$VENV_DIR"
    write_ok "Virtual environment created"
fi

# ================================================================
# STEP 5: Install Open WebUI
# ================================================================
write_step "5/7" "Installing Open WebUI (this may take 10-20 minutes on first run)..."

OPEN_WEBUI_BIN="$VENV_DIR/bin/open-webui"

if [ -f "$OPEN_WEBUI_BIN" ]; then
    write_ok "Open WebUI already installed"
else
    write_info "Upgrading pip..."
    "$VENV_PYTHON" -m pip install --upgrade pip 2>&1 | tail -1

    write_info "Installing Open WebUI + dependencies (PyTorch, Transformers, etc.)..."
    write_info "This downloads ~3 GB of packages. Please wait..."
    "$VENV_PIP" install open-webui 2>&1 | grep -E "^(Collecting|Downloading|Installing|Successfully)" || true

    if [ ! -f "$OPEN_WEBUI_BIN" ]; then
        write_err "Open WebUI installation failed. Try running manually:"
        echo "  $VENV_PIP install open-webui"
        exit 1
    fi
    write_ok "Open WebUI installed successfully"
fi

# Create data directory
DATA_DIR="$INSTALL_DIR/data"
mkdir -p "$DATA_DIR"
write_ok "Data directory ready: $DATA_DIR"

# ================================================================
# STEP 6: Download AI Models
# ================================================================
write_step "6/7" "Downloading AI models (this may take a while depending on internet speed)..."

for MODEL in "${MODELS[@]}"; do
    write_info "Checking model: $MODEL"
    if ollama list 2>&1 | grep -q "${MODEL%%:*}.*${MODEL##*:}"; then
        write_ok "$MODEL already downloaded"
    else
        write_info "Downloading $MODEL ..."
        if ollama pull "$MODEL"; then
            write_ok "$MODEL downloaded successfully"
        else
            write_err "Failed to download $MODEL. You can retry later with: ollama pull $MODEL"
        fi
    fi
done

# ================================================================
# STEP 7: Create startup script
# ================================================================
write_step "7/7" "Creating startup script..."

START_SCRIPT_PATH="$INSTALL_DIR/start-ai.sh"
cat > "$START_SCRIPT_PATH" << 'STARTSCRIPT'
#!/bin/bash
# ============================================
# Local AI Stack Startup Script
# ============================================
# This script starts Ollama and Open WebUI
# Open WebUI will be available at: http://localhost:8080
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "\033[36m========================================\033[0m"
echo -e "\033[36m  Starting Local AI Stack\033[0m"
echo -e "\033[36m========================================\033[0m"
echo ""

# Step 1: Check if Ollama is running
echo -e "\033[33m[1/2] Checking Ollama...\033[0m"
if ! pgrep -x "ollama" > /dev/null 2>&1; then
    echo "  Starting Ollama server..."
    ollama serve &> /dev/null &
    sleep 3
    echo -e "  \033[32mOllama started.\033[0m"
else
    echo -e "  \033[32mOllama is already running.\033[0m"
fi

# Step 2: Start Open WebUI
echo -e "\033[33m[2/2] Starting Open WebUI...\033[0m"
echo ""
echo -e "\033[36m========================================\033[0m"
echo -e "\033[32m  Open WebUI: http://localhost:8080\033[0m"
echo -e "\033[32m  Ollama API: http://localhost:11434\033[0m"
echo -e "\033[36m========================================\033[0m"
echo ""
echo "Press Ctrl+C to stop Open WebUI"
echo ""

# Set required environment variables
DATA_DIR="$SCRIPT_DIR/data"
mkdir -p "$DATA_DIR"
export DATA_DIR
export FROM_INIT_PY="true"

# Start Open WebUI
"$SCRIPT_DIR/.venv/bin/open-webui" serve --port 8080
STARTSCRIPT

chmod +x "$START_SCRIPT_PATH"
write_ok "Startup script created: $START_SCRIPT_PATH"

# ================================================================
# DONE
# ================================================================
echo ""
echo -e "\033[32m================================================================\033[0m"
echo -e "\033[32m  Setup Complete!\033[0m"
echo -e "\033[32m================================================================\033[0m"
echo ""
echo "  Installed Models:"
ollama list 2>&1 | while IFS= read -r line; do echo "    $line"; done
echo ""
echo "  To start your local AI:"
echo "    cd $INSTALL_DIR"
echo "    ./start-ai.sh"
echo ""
echo "  Then open: http://localhost:$OPEN_WEBUI_PORT"
echo "  (Create an admin account on first visit - fully local, no cloud)"
echo ""
echo "  To add more models later:"
echo "    ollama pull phi4-mini       # Fast & small"
echo "    ollama pull codellama:7b    # Coding specialist"
echo "    ollama pull llama3.1:8b     # Meta Llama 3.1"
echo ""
echo -e "\033[32m================================================================\033[0m"
