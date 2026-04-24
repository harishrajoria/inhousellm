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
