#!/bin/bash
# ============================================
# Local AI Stack - Docker Start/Stop Script
# ============================================
# Usage:
#   ./start-docker.sh          # Start the stack
#   ./start-docker.sh stop     # Stop the stack
#   ./start-docker.sh restart  # Restart the stack
#   ./start-docker.sh status   # Show container status
#   ./start-docker.sh logs     # Tail container logs
#   ./start-docker.sh pull     # Pull a model (interactive)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

case "${1:-start}" in
    start)
        echo -e "\033[36m========================================\033[0m"
        echo -e "\033[36m  Starting Local AI Stack (Docker)\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""
        docker compose up -d
        echo ""
        echo -e "\033[32m  Open WebUI: http://localhost:8080\033[0m"
        echo -e "\033[32m  Ollama API: http://localhost:11434\033[0m"
        echo ""
        docker compose ps
        ;;
    stop)
        echo "Stopping Local AI Stack..."
        docker compose down
        echo -e "\033[32mStopped.\033[0m"
        ;;
    restart)
        echo "Restarting Local AI Stack..."
        docker compose restart
        echo ""
        docker compose ps
        ;;
    status)
        docker compose ps
        echo ""
        echo "Models loaded:"
        docker exec ollama ollama list 2>/dev/null || echo "  Ollama container is not running"
        ;;
    logs)
        docker compose logs -f
        ;;
    pull)
        if [ -z "$2" ]; then
            echo "Usage: ./start-docker.sh pull <model-name>"
            echo "Example: ./start-docker.sh pull llama3.1:8b"
            exit 1
        fi
        echo "Pulling model: $2"
        docker exec ollama ollama pull "$2"
        ;;
    *)
        echo "Usage: ./start-docker.sh {start|stop|restart|status|logs|pull <model>}"
        exit 1
        ;;
esac
