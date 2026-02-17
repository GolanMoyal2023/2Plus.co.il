# Z8 ClawBot — Implementation Guide
**Written by:** Mac ClawBot (Sawish) | **Date:** 2026-02-16 | **For:** Tomorrow's Z8 session

---

## What You Are

You are **ClawBot on Z8** — a standalone OpenClaw agent running on a Windows 11 machine with WSL2 (Ubuntu 22.04). Your job is to be a **local AI powerhouse**: run heavy models via Ollama without paying API costs, and eventually act as a GPU inference backend for the Mac ClawBot (Sawish) as well.

**Z8 current state:**
- Ubuntu 22.04 on WSL2 ✅
- Node v22.22.0 via NVM ✅
- OpenClaw installed ✅
- Gateway: NOT running ❌
- No systemd user bus ❌ (use tmux workaround)
- Ollama: NOT installed ❌

---

## Phase 1 — Get Gateway Running (30 min)

### Step 1.1 — Configure openclaw.json

Create/edit `~/.openclaw/openclaw.json` on Z8:

```bash
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.2.15"
  },
  "auth": {
    "profiles": {
      "openai-codex:default": {
        "provider": "openai-codex",
        "mode": "oauth"
      },
      "google:default": {
        "provider": "google",
        "mode": "api_key"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.2",
        "fallbacks": ["openai/codex-mini-latest", "google/gemini-2.5-flash"]
      },
      "models": {
        "openai/codex-mini-latest": {},
        "openai-codex/gpt-5.2": {},
        "google/gemini-2.5-flash": {}
      },
      "thinkingDefault": "off",
      "maxConcurrent": 2
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "model": {
          "primary": "openai-codex/gpt-5.2"
        }
      }
    ]
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "Z8_TOKEN_PLACEHOLDER"
    }
  },
  "channels": {
    "telegram": {
      "enabled": false,
      "dmPolicy": "pairing",
      "botToken": "YOUR_TELEGRAM_BOT_TOKEN_HERE"
    }
  }
}
EOF
```

**Generate a unique gateway token for Z8:**
```bash
openssl rand -hex 24
# Copy output → replace Z8_TOKEN_PLACEHOLDER in the config above
```

> ⚠️ Do NOT reuse the Mac token (`2600ac3f8c52a4f2384c5a011de4bf1c2666689bf673348a`)

### Step 1.2 — Auth Setup (copy from Mac)

The Mac's OpenAI OAuth tokens can be reused on Z8. Copy them:

**On Mac** (run in Mac terminal):
```bash
# Pack the auth profiles for transfer
mkdir -p /tmp/z8-creds/agents/main/agent
cp ~/.openclaw/agents/main/agent/auth-profiles.json /tmp/z8-creds/agents/main/agent/
tar czf /tmp/z8-creds.tar.gz -C /tmp z8-creds/
```

**Transfer to Z8** — pick one method:
```bash
# Method A: via shared Windows folder (easiest on WSL)
cp /tmp/z8-creds.tar.gz /mnt/c/Users/YourWindowsUser/Desktop/

# Method B: via SCP if SSH is set up
scp /tmp/z8-creds.tar.gz user@z8-ip:~/
```

**On Z8** (WSL terminal):
```bash
cd ~
tar xzf z8-creds.tar.gz
mkdir -p ~/.openclaw/agents/main/agent
cp z8-creds/agents/main/agent/auth-profiles.json ~/.openclaw/agents/main/agent/

# Also add Google Gemini API key to auth-profiles.json
python3 << 'PYEOF'
import json, os

path = os.path.expanduser("~/.openclaw/agents/main/agent/auth-profiles.json")
with open(path) as f:
    data = json.load(f)

data["profiles"]["google:default"] = {
    "type": "api_key",
    "provider": "google",
    "key": "AIzaSyCCXVZcfbgtv4_g5zYrqZKCPnshFuRVRCA"
}
if "lastGood" not in data:
    data["lastGood"] = {}
data["lastGood"]["google"] = "google:default"

with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("✅ google:default added")
PYEOF
```

### Step 1.3 — Start Gateway (no systemd workaround)

```bash
# Install tmux
sudo apt-get install tmux -y

# Start gateway in tmux session
tmux new-session -d -s clawbot 'openclaw gateway --port 18789'

# Wait 3 seconds then verify
sleep 3 && openclaw gateway status
# Expected output: RPC probe: ok

# Quick sanity test
openclaw agent --agent main --message "ping"
# Expected: pong
```

### Step 1.4 — Auto-start on WSL open

Add to `~/.bashrc` so gateway starts whenever you open WSL:
```bash
echo '
# ClawBot auto-start
if ! tmux has-session -t clawbot 2>/dev/null; then
  tmux new-session -d -s clawbot "openclaw gateway --port 18789"
fi
' >> ~/.bashrc
```

---

## Phase 2 — Install Ollama + Pull Models (1-2 hours depending on download speed)

### Step 2.1 — Install Ollama in WSL2

```bash
curl -fsSL https://ollama.com/install.sh | sh

# Verify
ollama --version
```

### Step 2.2 — Pull the right model for Z8's hardware

**First, check Z8's GPU:**
```bash
# Check GPU (Windows)
nvidia-smi.exe 2>/dev/null || echo "No NVIDIA GPU detected"

# Check available RAM
free -h
```

**Model selection based on hardware:**

| Z8 Hardware | Recommended Model | VRAM/RAM needed | Quality |
|-------------|------------------|-----------------|---------|
| RTX 3080+ (10GB+) | `llama4-scout:17b` | ~12GB | Excellent |
| RTX 3060 (8GB) | `qwen2.5:7b` | ~6GB | Very good |
| No GPU / CPU only | `qwen2.5:3b` | ~3GB RAM | Good for simple tasks |
| 32GB+ RAM (CPU) | `mistral-nemo:12b` | ~10GB RAM | Good multilingual/Hebrew |

**Pull your chosen model:**
```bash
# Best all-rounder if you have the VRAM:
ollama pull llama4-scout:17b

# OR lighter option:
ollama pull qwen2.5:7b

# Test it works:
ollama run qwen2.5:7b "say hello in Hebrew"
```

### Step 2.3 — Configure Ollama to accept remote connections

By default Ollama only listens on localhost. To allow the Mac to use Z8's Ollama:

```bash
# Edit Ollama service config
sudo nano /etc/systemd/system/ollama.service
# OR for WSL without systemd, set env var before starting:

# Add to ~/.bashrc:
echo 'export OLLAMA_HOST=0.0.0.0' >> ~/.bashrc
source ~/.bashrc

# Restart Ollama
pkill ollama; sleep 1
tmux new-window -t clawbot 'ollama serve'
# OR if systemd is enabled:
# sudo systemctl restart ollama
```

Verify Ollama is listening on all interfaces:
```bash
curl http://localhost:11434/api/tags
# Should return JSON list of your models
```

### Step 2.4 — Add Ollama to Z8's openclaw.json

Edit `~/.openclaw/openclaw.json` to add Ollama as a model provider:

```bash
python3 << 'PYEOF'
import json

path = "/root/.openclaw/openclaw.json"  # or /home/user/.openclaw/openclaw.json
with open(path) as f:
    config = json.load(f)

# Add ollama to auth profiles
config["auth"]["profiles"]["ollama:local"] = {
    "provider": "ollama",
    "mode": "local"
}

# Add ollama models to configured models
config["agents"]["defaults"]["models"]["ollama/qwen2.5:7b"] = {}
config["agents"]["defaults"]["models"]["ollama/llama4-scout:17b"] = {}

# Update main agent to prefer Ollama for cheap tasks
# (or create dedicated agents later)
config["agents"]["defaults"]["model"]["fallbacks"].insert(0, "ollama/qwen2.5:7b")

with open(path, "w") as f:
    json.dump(config, f, indent=2)
print("✅ Ollama configured")
PYEOF
```

Test Ollama via OpenClaw:
```bash
openclaw models status
# Should show: ollama/qwen2.5:7b ok

openclaw agent --agent main --message "say shalom in Hebrew" --model ollama/qwen2.5:7b
```

---

## Phase 3 — Connect Z8 Ollama to Mac ClawBot (Advanced — do after Phase 2 works)

This makes the Mac ClawBot use Z8's GPU for inference, saving OpenAI costs.

### Step 3.1 — Setup Tailscale (if not already)

On Z8 (WSL):
```bash
# Install Tailscale in WSL
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Get Z8's Tailscale IP
tailscale ip -4
# Example: 100.x.x.x
```

### Step 3.2 — Update Mac's openclaw.json

On the **Mac**, add Z8 as a remote Ollama endpoint:

```json
"auth": {
  "profiles": {
    "ollama:z8": {
      "provider": "ollama",
      "baseUrl": "http://100.x.x.x:11434"
    }
  }
}
```

Add Z8 models to Mac's configured models:
```json
"models": {
  "ollama-z8/qwen2.5:7b": {},
  "ollama-z8/llama4-scout:17b": {}
}
```

Assign to cheap agents on Mac (mailbot, taskbot, contentbot):
```json
{
  "id": "mailbot",
  "model": {
    "primary": "ollama-z8/qwen2.5:7b",
    "fallbacks": ["openai/codex-mini-latest"]
  }
}
```

### Step 3.3 — Test cross-machine inference

```bash
# On Mac — test Z8 Ollama
openclaw models status
# Should show: ollama-z8/qwen2.5:7b ok · Xms

openclaw agent --agent mailbot --message "שלום" --model ollama-z8/qwen2.5:7b
```

---

## Quick Reference — Z8 Daily Commands

```bash
# Check gateway
openclaw gateway status

# Attach to live logs
tmux attach -t clawbot

# Detach from tmux (keep running)
Ctrl+B then D

# Test agent
openclaw agent --agent main --message "ping"

# Check Ollama models
ollama list

# Check Ollama running
curl http://localhost:11434/api/tags | python3 -m json.tool

# Gateway token (Z8-specific, generate your own)
# Store in ~/.openclaw/openclaw.json → gateway.auth.token
```

---

## Architecture After Z8 Setup

```
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│          MAC (M1 32GB)          │    │       Z8 (Windows/WSL2)         │
│                                 │    │                                  │
│  OpenClaw Gateway :18789        │    │  OpenClaw Gateway :18789         │
│  ├── main (Sawish) gpt-5.2      │    │  └── main agent                  │
│  ├── mailbot codex-mini         │◄───┤                                  │
│  ├── taskbot codex-mini         │    │  Ollama :11434                   │
│  ├── webbot gpt-5.2             │    │  └── qwen2.5:7b / llama4-scout   │
│  ├── devbot gpt-5.2             │    │       (GPU accelerated)          │
│  └── contentbot codex-mini      │    │                                  │
│                                 │    │  Telegram Bot (optional)         │
│  WhatsApp ✅  Telegram ✅        │    │  └── separate bot token          │
└─────────────────────────────────┘    └─────────────────────────────────┘
         │                                          │
         └──────────── Tailscale VPN ───────────────┘
                    (model inference traffic)
```

---

## Checklist for Tomorrow

```
Phase 1 — Gateway (must do first):
[ ] Create ~/.openclaw/openclaw.json with correct config
[ ] Generate unique Z8 gateway token (openssl rand -hex 24)
[ ] Copy auth-profiles.json from Mac (or fresh onboard)
[ ] Install tmux: sudo apt-get install tmux -y
[ ] Start gateway: tmux new-session -d -s clawbot 'openclaw gateway'
[ ] Verify: openclaw gateway status → RPC probe: ok
[ ] Test: openclaw agent --agent main --message "ping" → pong
[ ] Add auto-start to ~/.bashrc

Phase 2 — Ollama (do after Phase 1):
[ ] Check GPU: nvidia-smi.exe
[ ] Install Ollama: curl -fsSL https://ollama.com/install.sh | sh
[ ] Pull model based on GPU (see table above)
[ ] Test: ollama run <model> "say hello in Hebrew"
[ ] Set OLLAMA_HOST=0.0.0.0 for remote access
[ ] Add Ollama to openclaw.json
[ ] Verify: openclaw models status → ollama/model ok

Phase 3 — Mac Integration (do after Phase 2):
[ ] Install Tailscale on Z8
[ ] Get Z8 Tailscale IP
[ ] Update Mac openclaw.json with ollama:z8 provider
[ ] Test cross-machine: openclaw models status on Mac
[ ] Assign Ollama to mailbot/taskbot/contentbot on Mac
```

---

*Mac ClawBot (Sawish) · Generated 2026-02-16 · Tokens saved per day once Ollama active: ~$1.50*
