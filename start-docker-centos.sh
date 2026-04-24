#!/bin/bash
# ============================================
# Local AI Stack - Docker Start/Stop (CentOS 7)
# ============================================
# Usage:
#   ./start-docker-centos.sh              # Start
#   ./start-docker-centos.sh stop         # Stop
#   ./start-docker-centos.sh restart      # Restart
#   ./start-docker-centos.sh status       # Status + models
#   ./start-docker-centos.sh logs         # Tail logs
#   ./start-docker-centos.sh pull <model> # Pull a model
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose-centos.yml"

# Detect compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "ERROR: docker-compose not found. Run setup-docker-centos.sh first."
    exit 1
fi

cd "$SCRIPT_DIR"

case "${1:-start}" in
    start)
        echo -e "\033[36m========================================\033[0m"
        echo -e "\033[36m  Starting Local AI Stack (CentOS 7)\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""
        $COMPOSE_CMD -f "$COMPOSE_FILE" up -d
        echo ""
        echo -e "\033[32m  Open WebUI: http://localhost:8080\033[0m"
        echo -e "\033[32m  Ollama API: http://localhost:11434\033[0m"
        echo ""
        $COMPOSE_CMD -f "$COMPOSE_FILE" ps
        ;;
    stop)
        echo "Stopping Local AI Stack..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" down
        echo -e "\033[32mStopped.\033[0m"
        ;;
    restart)
        echo "Restarting Local AI Stack..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" restart
        echo ""
        $COMPOSE_CMD -f "$COMPOSE_FILE" ps
        ;;
    status)
        $COMPOSE_CMD -f "$COMPOSE_FILE" ps
        echo ""
        echo "Models loaded:"
        docker exec ollama ollama list 2>/dev/null || echo "  Ollama container is not running"
        echo ""
        echo "Memory usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" ollama open-webui 2>/dev/null || true
        ;;
    logs)
        $COMPOSE_CMD -f "$COMPOSE_FILE" logs -f
        ;;
    pull)
        if [ -z "$2" ]; then
            echo "Usage: ./start-docker-centos.sh pull <model-name>"
            echo "Example: ./start-docker-centos.sh pull deepseek-r1:1.5b"
            echo ""
            echo "WARNING: With 7 GB RAM, only use 1.5B or smaller models!"
            exit 1
        fi
        echo "Pulling model: $2"
        docker exec ollama ollama pull "$2"
        ;;
    *)
        echo "Usage: ./start-docker-centos.sh {start|stop|restart|status|logs|pull <model>}"
        exit 1
        ;;
esac
