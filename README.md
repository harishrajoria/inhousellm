# Local AI Setup - InHouseModel (Linux)

## Your System
- **CPU:** Intel i7-1255U (12th Gen, 10 cores, 12 threads)
- **RAM:** 16 GB
- **GPU:** Intel UHD (integrated only — CPU inference)
- **OS:** Linux (Ubuntu/Debian)

## Architecture

```
┌──────────────────────┐     ┌──────────────────────┐
│     Open WebUI       │────▶│       Ollama          │
│  (Frontend - :8080)  │     │  (Backend - :11434)   │
│  ChatGPT-like UI     │     │  Runs AI models       │
└──────────────────────┘     └──────────────────────┘
```

## Installed Models

| Model | Size | Best For |
|-------|------|----------|
| `deepseek-r1:1.5b` | ~1.1 GB | Fast responses, light tasks |
| `deepseek-r1:7b` | ~4.7 GB | Reasoning, coding, analysis |
| `qwen2.5:7b` | ~4.7 GB | General purpose, multilingual (Alibaba) |

## Quick Start

You have **two options**: Docker (recommended) or native install.

---

### Docker Setup (Recommended)

One command to set up everything — Docker, Ollama, Open WebUI, and models:

```bash
cd ~/INHOUSEMODELLINUX
chmod +x setup-docker.sh start-docker.sh
./setup-docker.sh
```

After setup, manage the stack with:

```bash
./start-docker.sh              # Start containers
./start-docker.sh stop         # Stop containers
./start-docker.sh restart      # Restart containers
./start-docker.sh status       # Show status & loaded models
./start-docker.sh logs         # Tail container logs
./start-docker.sh pull phi4-mini   # Pull a new model
```

Or use docker compose directly:

```bash
docker compose up -d           # Start
docker compose down            # Stop
docker compose logs -f         # View logs
docker exec ollama ollama pull codellama:7b   # Pull model
docker exec ollama ollama list                # List models
```

> **GPU Support (NVIDIA):** Uncomment the `deploy` section in `docker-compose.yml` and install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

---

### Native Install (No Docker)

#### Option 1: Full setup from scratch
```bash
cd ~/INHOUSEMODELLINUX
chmod +x setup-local-ai.sh start-ai.sh
./setup-local-ai.sh
```

#### Option 2: Run the startup script (after setup)
```bash
cd ~/INHOUSEMODELLINUX
./start-ai.sh
```

#### Option 3: Manual start
```bash
# Terminal 1 - Start Ollama (if not already running)
ollama serve

# Terminal 2 - Start Open WebUI
cd ~/INHOUSEMODELLINUX
./.venv/bin/open-webui serve --port 8080
```

Then open **http://localhost:8080** in your browser.

> **First time:** You'll need to create an admin account (local only, no cloud).

## Common Ollama Commands

```bash
# List installed models
ollama list

# Pull a new model
ollama pull <model-name>

# Remove a model (free disk space)
ollama rm <model-name>

# Chat directly in terminal (no UI needed)
ollama run deepseek-r1:7b

# Check Ollama is running
ollama ps
```

## Recommended Additional Models

With 16 GB RAM, stick to **7B or smaller** models:

```bash
# Coding specialist
ollama pull codellama:7b

# Fast & tiny (for quick answers)
ollama pull phi4-mini

# Llama 3.1 (Meta)
ollama pull llama3.1:8b
```

## Performance Tips

1. **Close other heavy apps** before running 7B models (they use ~5-6 GB RAM)
2. **Use 1.5B models** for quick tasks — they respond in seconds
3. **7B models** take 10-30 seconds per response on your CPU — this is normal
4. Ollama automatically unloads models after 5 minutes of inactivity to free RAM

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Open WebUI can't find models | Make sure Ollama is running (`ollama serve`) |
| Very slow responses | Try a smaller model (`deepseek-r1:1.5b`) |
| Out of memory | Close other apps, or use 1.5B/3B models |
| Port 8080 in use | Run `open-webui serve --port 3000` instead |
| Permission denied on scripts | Run `chmod +x setup-local-ai.sh start-ai.sh` |
| Python 3.11 not found | Install via: `sudo apt install python3.11 python3.11-venv` |
| Ollama install fails | Try manual install: `curl -fsSL https://ollama.com/install.sh \| sh` |
| venv creation fails | Install venv module: `sudo apt install python3.11-venv` |
| Docker permission denied | Run `sudo usermod -aG docker $USER` then log out/in |
| Container won't start | Check logs: `docker compose logs -f` |
| Models missing in Docker | Pull into container: `docker exec ollama ollama pull <model>` |
