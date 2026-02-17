# ClawBot 6-Agent Expansion Plan

Expand from single **main (Sawish)** to a 6-agent team of technical specialists. Free/local models for routine agents; paid (gpt-5.2) only for reasoning-heavy agents.

**Hardware:** Mac M1 · 32GB RAM · 1TB SSD

---

## Pre-requisite: Free/Local Model Research ✅ (Done)

OpenClaw **supports** all of the following. Use `openclaw models list` after adding auth to see discovered models.

| Provider | Support | Auth / config | Notes |
|----------|--------|----------------|-------|
| **Ollama** | ✅ Yes | `OLLAMA_API_KEY="ollama-local"` or `openclaw config set models.providers.ollama.apiKey "ollama-local"` | Local, $0. Auto-discovers tool-capable models from `http://127.0.0.1:11434`. Doc: `docs/providers/ollama.md`. |
| **Groq** | ✅ Yes | `GROQ_API_KEY` (built-in) | Free tier, fast. |
| **DeepSeek** | ✅ Via Hugging Face or OpenRouter | Hugging Face: `HUGGINGFACE_HUB_TOKEN`, model e.g. `huggingface/deepseek-ai/DeepSeek-R1`. OpenRouter: `openrouter/deepseek/deepseek-r1:free` | Cheap/free options. |
| **Google Gemini** | ✅ Yes | `GEMINI_API_KEY`, provider `google`. CLI: `openclaw onboard --auth-choice gemini-api-key` | Free tier, 1M context. |
| **OpenRouter** | ✅ Yes | `OPENROUTER_API_KEY`. Model refs: `openrouter/<provider>/<model>` | Aggregator, many free/cheap models. |

**Ollama quick start (from OpenClaw docs):**
1. Install Ollama from https://ollama.ai
2. `ollama pull llama3.3` (or `qwen2.5-coder:32b`, `deepseek-r1:32b`, etc.)
3. `export OLLAMA_API_KEY="ollama-local"` (or set in `~/.openclaw/.env`)
4. Do **not** define `models.providers.ollama` explicitly if you want auto-discovery
5. Use model refs like `ollama/llama3.3`, `ollama/qwen2.5-coder:32b`
6. `openclaw models list` shows discovered Ollama models (only those with tool support are listed)

**Goal:** Free/local for mailbot, taskbot, contentbot; paid (gpt-5.2) for main, devbot, webbot.

**Ollama on 32GB:** Run ONE model at a time. Llama 4 Scout 17B (~12GB) if available, or e.g. `llama3.3` / `qwen2.5-coder:32b` as default for mailbot/taskbot/contentbot. No Maverick 400B.

---

## Final Model Assignments

| Agent | Model | Provider | Cost |
|-------|--------|----------|------|
| main (Sawish) | gpt-5.2 | OpenAI | ~$1.50/day |
| mailbot | llama4-scout:17b | Ollama (local) | $0 |
| taskbot | llama4-scout:17b | Ollama (local) | $0 |
| webbot | gemini-2.5-pro | Google | ~$0.30/day |
| devbot | gpt-5.2 | OpenAI | ~$0.75/day |
| contentbot | llama4-scout:17b | Ollama (local) | $0 |

**Estimated total:** ~$2.55/day (≈50% savings vs all gpt-5.2).

**Fallback:** If Ollama not supported, use codex-mini for mailbot/taskbot/contentbot (≈40% savings).

---

## Implementation Order

1. Check full Mac hardware specs  
2. Install Ollama + pull `llama4-scout:17b`  
3. Test OpenClaw → Ollama integration  
4. If Ollama works: proceed with plan using free models; if not: codex-mini for routine agents  
5. **Phase 1** — mailbot, taskbot, main upgrade (Week 1)  
6. **Phase 2** — webbot, devbot, contentbot (Week 2–3)  
7. **Phase 3** — Cost tracking, observability, memory hierarchy, governance (Week 3–4)  

---

## Phase 1 Progress (done)

- **Ollama:** `OLLAMA_API_KEY=ollama-local` added to `~/.openclaw/.env`. Use `ollama/llama3.3` in agent config when Ollama is running; until then mailbot/taskbot use **codex-mini**.
- **Models:** mailbot and taskbot set to `openai/codex-mini-latest` in `openclaw.json`; main remains gpt-5.2.
- **Workspaces & SOUL:** mailbot and taskbot workspaces and SOUL.md in place; main SOUL.md has team delegation; taskbot has `tasks.json`.
- **Cron:** Email digests (08:00, 17:00 IL) assigned to **mailbot**; taskbot jobs added (07:30 morning briefing, 20:00 EOD IL).
- **Tools:** `tools.agentToAgent.enabled: true` in `openclaw.json` for delegation.
- **Verification:** `openclaw agents list` shows main (gpt-5.2), mailbot (codex-mini), taskbot (codex-mini); `openclaw cron list` shows 4 jobs; `openclaw cron run <jobId>` ran successfully.

---

## Phase 1 — Foundation (Week 1)

### 1.1 mailbot — Email Specialist
- **Model:** codex-mini or Ollama (llama4-scout:17b)
- **Workspace:** `~/.openclaw/workspace/agents/mailbot/`
- **Skills:** clawmail, session-logs
- **Scripts:** graph_mail_pull.py, mail_action_digest.py (symlinked)
- **Cron:** 08:00 IL, 17:00 IL
- **CLI:** `openclaw agents add mailbot --workspace ~/.openclaw/workspace/agents/mailbot`

### 1.2 taskbot — Calendar & Tasks
- **Model:** codex-mini or Ollama
- **Workspace:** `~/.openclaw/workspace/agents/taskbot/`
- **Skills:** goplaces, session-logs
- **Scripts:** graph_calendar_pull.py, graph_calendar_create_event.py; tasks.json
- **Cron:** 07:30 IL, 20:00 IL
- **CLI:** `openclaw agents add taskbot --workspace ~/.openclaw/workspace/agents/taskbot`

### 1.3 main (Sawish) — Orchestrator Upgrade
- **Model:** gpt-5.2 (unchanged)
- **Changes:** SOUL.md team awareness + delegation; remove email cron (→ mailbot); delegate via sessions_spawn to mailbot/taskbot

**Config:** `openclaw.json` — agents.list (main, mailbot, taskbot), bindings, tools.agentToAgent.  
**Cron:** `cron/jobs.json` — migrate email jobs to mailbot, add taskbot jobs.  
**Create:** mailbot/SOUL.md, taskbot/SOUL.md, taskbot/tasks.json.

---

## Phase 2 — Expansion (Week 2–3)

### 2.1 webbot — Web Research
- **Model:** gpt-5.2 (or gemini-2.5-pro)
- **Skills:** goplaces, file-analyze, web fetch/search. On-demand via main.

### 2.2 devbot — Full-Stack DevOps & Engineering
- **Model:** gpt-5.2
- **Skills:** coding-agent-e3, session-logs, system.run
- **Depth:** microservices, CI/CD, Docker, K8s, IaC, observability, etc.

### 2.3 contentbot — Technical Content & Docs
- **Model:** codex-mini or Ollama
- **Skills:** file-analyze, web fetch (read-only). On-demand.

---

## Phase 3 — Infrastructure (Week 3–4)

- **Cost:** cost_tracker.py → analytics/costs/YYYY-MM-DD.json; weekly report.
- **Observability:** health.json per agent; HEARTBEAT.md; session_analytics.py.
- **Memory:** daily → memory/YYYY-MM-DD.md; weekly → memory/weekly/YYYY-Www.md; MEMORY.md curation.
- **Governance:** tools.allow / tools.deny per agent (mailbot: email only; taskbot: calendar only; contentbot: read-only; main: full).

---

## Communication Pattern

```
User (WhatsApp/Telegram) → main (Sawish)
  ├─ "check email"     → sessions_spawn(mailbot)
  ├─ "calendar tomorrow" → sessions_spawn(taskbot)
  ├─ "research X"      → sessions_spawn(webbot)
  ├─ "fix this code"   → sessions_spawn(devbot)
  ├─ "draft a post"    → sessions_spawn(contentbot)
  └─ "tell me a joke"  → main handles directly
```

---

## Rollback

- **Phase 1:** Cron agentId → main, remove mailbot/taskbot from agents.list.
- **Phase 2:** Remove webbot/devbot/contentbot from agents.list.
- **Phase 3:** Disable analytics crons.

---

## Verification

- `openclaw agents list` — all agents
- `openclaw cron list` — jobs per agent
- `openclaw cron trigger mailbot-morning-digest`
- WhatsApp: "check my email" → main → mailbot
- WhatsApp: "what's on my calendar" → main → taskbot
- Governance: mailbot cannot use coding-agent
- Devbot test: "design a microservices architecture for real-time notifications" → proper terminology

---

## Immediate Action Items

1. **Kill stuck 90-min session** — OpenClaw has no CLI to kill a single session. Options: (a) Close the chat tab / start a new conversation in the dashboard; (b) Restart the gateway: `openclaw gateway stop` then `openclaw gateway --force`. That clears in-flight turns.
2. **Research free model providers** — ✅ Done (see table above). Ollama, Groq, DeepSeek (via HF/OpenRouter), Gemini, OpenRouter all supported.
3. **Start Phase 1** — You already have `main`, `mailbot`, `taskbot` agents (`openclaw agents list`). Next: switch mailbot/taskbot to Ollama or codex-mini, set workspaces/cron/SOUL.md per plan, then add webbot/devbot/contentbot in Phase 2.

**Design principle:** All agents operate with engineering-grade depth (proper terminology, multi-tech stacks, architecture trade-offs, SOUL.md technical domains).

---

## Killing a stuck session

OpenClaw does not expose a “kill session” CLI. To clear a stuck “thinking” turn:

1. **Dashboard:** Close the chat tab or open a new conversation.
2. **Restart gateway:** `openclaw gateway stop` then `openclaw gateway --force` (or start in background). This aborts in-flight LLM requests.
3. **Prevent long runs:** Prefer shorter prompts or chunked requests (“list 5 steps” then “expand step 2”); consider timeouts in config if documented.
