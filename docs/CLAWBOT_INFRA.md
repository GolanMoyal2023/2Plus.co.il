# ClawBot Infrastructure Summary
**Last updated:** 2026-02-16 | **Version:** OpenClaw v2026.2.15

---

## Current Stack

| Component | Status | Notes |
|-----------|--------|--------|
| **OpenClaw** | v2026.2.15 ✅ | Upgraded from v2026.2.13 |
| **Gateway** | pid 67236 · localhost:18789 ✅ | LaunchAgent supervised, auto-restarts |
| **Gateway token** | `2600ac3f8c52a4f2384c5a011de4bf1c2666689bf673348a` | Rotated by onboard on 2026-02-16 |
| **WhatsApp** | Linked ✅ | +972526111926, wacli-sync keepalive |
| **Telegram** | @GolanClawBot ✅ | Connected, streamMode: partial |
| **Gmail (ClawMail)** | golan.moyal@gmail.com, golan@moyal.net ✅ | OAuth tokens valid |
| **M365 Graph** | ✅ | Tenant: 620c4a2f, Client: 14d82eec |
| **Config** | `~/.openclaw/openclaw.json` | 6-agent architecture |
| **Workspace** | `~/.openclaw/workspace/` | SOUL.md, TOOLS.md, AGENTS.md, HEARTBEAT.md |
| **Agents** | 6 agents ✅ | main, mailbot, taskbot, webbot, devbot, contentbot |
| **Observability** | Grafana :3000, Prometheus :9090, Alloy :4318 ✅ | ClawBot dashboard created |
| **thinkingDefault** | `off` ✅ | Prevents 400 reasoning summaries error |

---

## 6-Agent Architecture (Live as of 2026-02-16)

```
User (WhatsApp / Telegram)
  └─> main (Sawish) — gpt-5.2 — Orchestrator
        ├─ email tasks     → mailbot  (codex-mini)
        ├─ calendar/tasks  → taskbot  (codex-mini)
        ├─ web research    → webbot   (gpt-5.2)
        ├─ code / devops   → devbot   (gpt-5.2)
        └─ content/docs    → contentbot (codex-mini)
```

| Agent | Model | Role | Cron |
|-------|-------|------|------|
| **main (Sawish)** | gpt-5.2 | Orchestrator, all channels | None |
| **mailbot** | codex-mini | M365 + Gmail digest | 08:00, 17:00 IL |
| **taskbot** | codex-mini | Calendar, todos | 07:30, 20:00 IL |
| **webbot** | gpt-5.2 | Web research | On-demand |
| **devbot** | gpt-5.2 | Code, DevOps, infra | On-demand |
| **contentbot** | codex-mini | Docs, write-ups | On-demand |

---

## Model Providers (Active)

| Provider | Auth | Status | Models |
|----------|------|--------|--------|
| **openai-codex** | OAuth | ✅ Active | gpt-5.2, codex-mini-latest |
| **google** | API key | ✅ Active | gemini-2.5-flash, gemini-2.5-pro |

**Fallback chain:** `gpt-5.2` → `codex-mini-latest` → `gemini-2.5-flash`

**thinkingDefault:** `off` — prevents OpenAI 400 error on gpt-5.2 requiring org verification for reasoning summaries.

---

## Observability Stack

All services run as Homebrew LaunchAgents (auto-start on boot):

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| **Grafana Alloy** | 4318 (OTLP), 12345 (UI) | ✅ | Receives OTel metrics from gateway |
| **Prometheus** | 9090 | ✅ | Stores metrics, remote_write receiver enabled |
| **Grafana** | 3000 | ✅ | Dashboard, admin/admin |

**Pipeline:** OpenClaw gateway → OTLP/HTTP → Alloy → Prometheus remote_write → Grafana

**Grafana datasource:** Prometheus at http://127.0.0.1:9090 (configured via API)
**ClawBot dashboard:** Created with panels for agent activity, model usage, sessions

**Missing npm deps (already fixed):**
```bash
cd /opt/homebrew/lib/node_modules/openclaw
npm install @opentelemetry/api @opentelemetry/sdk-node \
  @opentelemetry/exporter-trace-otlp-http \
  @opentelemetry/exporter-metrics-otlp-http
```

---

## Mailbot — Known Issues & Fixes

| Issue | Fix Applied |
|-------|------------|
| `python: command not found` | Use venv: `~/.openclaw/workspace/skills/clawmail/.venv/bin/python` |
| `ModuleNotFoundError: google` | Same — only clawmail venv has google packages |
| `browser tool: device token mismatch` | Gateway token rotated on 2026-02-16; TOOLS.md updated |
| `400 reasoning summaries` | `thinkingDefault: "off"` in agents.defaults |
| `session file locked` | Kill stale pid, clear `.lock` files, restart gateway |

**Correct python paths for mailbot:**
```bash
# Gmail via ClawMail (ALWAYS use this):
~/.openclaw/workspace/skills/clawmail/.venv/bin/python \
  ~/.openclaw/workspace/skills/clawmail/skill.py <cmd> <email>

# M365 Graph:
python3 ~/.openclaw/workspace/graph_mail_pull.py

# NEVER use bare `python` — does not exist on macOS
```

---

## Cron Jobs

```
07:30 IL  taskbot  — Morning calendar briefing
08:00 IL  mailbot  — Morning email digest (M365 + Gmail)
17:00 IL  mailbot  — Afternoon email digest
20:00 IL  taskbot  — End-of-day review
```

---

## Key File Locations

| File | Purpose |
|------|---------|
| `~/.openclaw/openclaw.json` | Master config (agents, models, channels, hooks) |
| `~/.openclaw/workspace/SOUL.md` | Main agent identity (Sawish) |
| `~/.openclaw/workspace/AGENTS.md` | Team overview |
| `~/.openclaw/workspace/agents/mailbot/SOUL.md` | Mailbot personality + python rules |
| `~/.openclaw/workspace/agents/mailbot/TOOLS.md` | Mailbot tool reference |
| `~/.openclaw/workspace/Z8-WSL-SETUP.md` | Z8 gateway setup guide |
| `~/.openclaw/cron/jobs.json` | Cron job definitions |
| `/opt/homebrew/etc/grafana-alloy/config.alloy` | Alloy OTLP pipeline config |
| `/opt/homebrew/etc/prometheus.args` | Prometheus startup flags |
| `~/.openclaw/logs/gateway.log` | Gateway LaunchAgent stdout |

---

## Z8 Machine (In Progress)

**Z8 status:** Ubuntu 22.04 WSL2, Node v22.22.0, OpenClaw installed, gateway NOT running yet.

**Plan:** See `Z8-TOMORROW.md` for full setup guide.

**Phase 1 (tomorrow):** Get Z8 gateway running with tmux (no systemd)
**Phase 2 (tomorrow):** Install Ollama + pull model based on Z8's GPU
**Phase 3 (future):** Connect Z8 Ollama to Mac ClawBot via Tailscale → save ~$1.50/day on API costs

---

## Cost Estimate (Current — Mac only)

| Agent | Model | Est. daily cost |
|-------|-------|----------------|
| main | gpt-5.2 | ~$1.50 |
| mailbot | codex-mini | ~$0.10 |
| taskbot | codex-mini | ~$0.07 |
| webbot | gpt-5.2 | ~$0.75 (on-demand) |
| devbot | gpt-5.2 | ~$0.75 (on-demand) |
| contentbot | codex-mini | ~$0.04 (on-demand) |
| **Total** | | **~$3.21/day** |

**After Z8 Ollama integration:** mailbot + taskbot + contentbot → Ollama (free) → **~$2.25/day saved**

---

## Disabled by Design

- **Slack:** plugin enabled, channel disabled (`enabled: false`)
- **iMessage:** plugin enabled, channel disabled
- **BlueBubbles:** plugin enabled, channel disabled
- **Web search:** `tools.web.search.enabled: false` (fetch is on)
- **Tailscale:** `gateway.tailscale.mode: "off"`
- **thinkingDefault:** `off` (prevents 400 error; re-enable when OpenAI propagates verification)
