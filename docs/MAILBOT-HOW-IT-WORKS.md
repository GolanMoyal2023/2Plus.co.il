# ClawBot Mail System — How It Works
**Author:** Mac ClawBot (Sawish) | **Date:** 2026-02-17 | **Version:** Current

---

## Overview

ClawBot reads your email automatically, classifies it into categories, and pushes only what matters to your WhatsApp. No app to open, no inbox to check.

```
Gmail + M365 Inbox
      │
      ▼
  ClawMail skill (OAuth)
      │
      ▼
  AI Agent (mailbot / main)
  └─ classifies into: SECURITY | PAYMENTS | JOBS
      │
      ▼
  wacli → WhatsApp (your phone)
```

---

## Architecture

### Components

| Component | Role | Location |
|-----------|------|----------|
| `mailwa_run.sh` | Orchestrator script, runs on schedule | `~/.openclaw/bin/mailwa_run.sh` |
| `mailwa.env` | Config: mailboxes, WhatsApp JIDs | `~/.openclaw/config/mailwa.env` |
| `clawmail skill` | Gmail OAuth reader (Python venv) | `~/.openclaw/workspace/skills/clawmail/` |
| `graph_mail_pull.py` | M365 / Outlook reader (Graph API) | `~/.openclaw/workspace/agents/mailbot/` |
| `openclaw agent` | AI classification engine | OpenClaw gateway |
| `wacli` | WhatsApp message sender | system PATH |
| LaunchAgent: `mailwa.instant` | Runs every 15 min | `~/Library/LaunchAgents/` |
| LaunchAgent: `mailwa.daily` | Runs daily at 08:30 | `~/Library/LaunchAgents/` |

---

## Flow — Step by Step

### Step 1: Trigger (LaunchAgent)

Every **15 minutes**, macOS LaunchAgent fires:
```bash
~/.openclaw/bin/mailwa_run.sh instant
```

Daily at **08:30 IL**, it fires:
```bash
~/.openclaw/bin/mailwa_run.sh daily
```

### Step 2: Scan Each Mailbox

The script loops over both mailboxes (`golan@moyal.net`, `golan.moyal@gmail.com`) and for each one calls:

```bash
openclaw agent --local --agent main \
  --session-id "mailwa-golan_moyal_net-instant-20260217-0800" \
  -m "From the last 6 hours in golan@moyal.net, return ONLY emails that match..."
```

> ⚠️ **Critical:** Session ID is **timestamped** (`-20260217-0800`).
> This ensures every run starts a **fresh session** — never reusing old ones.
> Reusing caused a 312k-token overflow loop that burned both providers. Fixed 2026-02-17.

### Step 3: AI Classification

The agent reads emails using the ClawMail Gmail skill or M365 Graph script, then classifies:

```
(A) SECURITY
    └─ From: *@google.com, *@accounts.google.com
    └─ Subject contains: "Security" OR "Alert"

(B) PAYMENTS
    └─ Subject contains: Apple, AppleID, Payment, Invoice, Subscription, Charges
    └─ OR from: *@microsoft.com, *@office.com, *@azure.com + payment keywords

(C) JOBS
    └─ From contains: "jobnet"
    └─ OR sender: "הסוכן החכם של ג'ובנט"
```

Output format — one line per email:
```
CATEGORY | Subject | From | Date | Snippet
```

### Step 4: Route to WhatsApp

The script splits output by category and sends each to the correct WhatsApp thread:

```bash
🚨 SECURITY → WA_SECURITY_JID group (or fallback: your self-chat)
💳 PAYMENTS → WA_PAYMENTS_JID group (or fallback)
💼 JOBS     → WA_JOBS_JID group (or fallback)
```

Messages are trimmed to **3,500 characters** (WhatsApp safe limit).

If no matching emails found → **silent** (nothing sent).

---

## Email Reading — Technical Detail

### Gmail (ClawMail Skill)

Uses OAuth2 with per-account token files. **Must use venv python:**

```bash
# ✅ Correct
~/.openclaw/workspace/skills/clawmail/.venv/bin/python \
  ~/.openclaw/workspace/skills/clawmail/skill.py \
  latest golan.moyal@gmail.com 20

# ✅ Digest (last N hours)
~/.openclaw/workspace/skills/clawmail/.venv/bin/python \
  ~/.openclaw/workspace/skills/clawmail/skill.py \
  digest golan.moyal@gmail.com 6

# ❌ NEVER use bare python — does not exist on this machine
python skill.py ...
```

**Token files:**
- `golan.moyal@gmail.com` → `~/.clawmail/tokens/golan_moyal_at_gmail_com.json`
- `golan@moyal.net` → `~/.clawmail/tokens/golan_at_moyal_net.json`

### Microsoft 365 / Outlook (Graph API)

```bash
python3 ~/.openclaw/workspace/agents/mailbot/graph_mail_pull.py
```

Requires:
- `MS_TENANT_ID` = `620c4a2f-...`
- `MS_CLIENT_ID` = `14d82eec-...`
- Token cache: `~/.openclaw/credentials/msgraph_token_cache.bin`

---

## Classification Logic (mailbot SOUL)

The AI applies these priority rules:

| Priority | Condition | Action |
|----------|-----------|--------|
| 🔴 HIGH | `iai.co.il` domain | Always include |
| 🔴 HIGH | Meeting invites / calendar | Always include |
| 🔴 HIGH | Security alerts (Google, Microsoft) | Always include |
| 🟡 MEDIUM | Payment / invoice / renewal | Include |
| ⚫ DROP | LinkedIn, newsletters, job alerts, promos | Filter out completely |

**Output language:** Hebrew by default. Technical terms (domains, API names) stay in English.

**Conservative rule:** When unsure → **keep** the email. False negatives are worse than false positives.

---

## Schedule

| Mode | Trigger | Hours Scanned | Purpose |
|------|---------|--------------|---------|
| `instant` | Every 15 min | Last 6 hours | Real-time alerts |
| `daily` | 08:30 IL | Last 24 hours | Morning digest |

---

## Configuration File

`~/.openclaw/config/mailwa.env`:

```bash
# WhatsApp destination JIDs
WA_SECURITY_JID="GROUP_JID@g.us"     # Security alerts group
WA_PAYMENTS_JID="GROUP_JID@g.us"     # Payments group
WA_JOBS_JID="GROUP_JID@g.us"         # Jobs group
WA_FALLBACK_JID="972526111926@s.whatsapp.net"  # Your self-chat (fallback)

# Mailboxes to scan
MAILBOX_1="golan@moyal.net"
MAILBOX_2="golan.moyal@gmail.com"

# Hours window (optional overrides)
# HOURS_INSTANT=6
# HOURS_DAILY=24
```

> **Note:** WA group JIDs are currently set to placeholders → all messages go to `WA_FALLBACK_JID` (your self-chat). Fill in real group JIDs to route to specific threads.

---

## Known Issues & Fixes Applied

### ❌ Problem 1: Session overflow loop (Fixed 2026-02-17)
**What happened:** Fixed session ID → same session reused every 15 min → grew to 312k tokens (156% overflow) → infinite error loop → burned both API providers.

**Fix:** Session ID now timestamped:
```bash
# Before (bad):
--session-id "mailwa-golan_moyal_net-instant"

# After (fixed):
--session-id "mailwa-golan_moyal_net-instant-20260217-0800"
```

### ❌ Problem 2: `python: command not found`
**What happened:** Agent called bare `python` which doesn't exist on macOS.

**Fix:** Always use full venv path:
```bash
~/.openclaw/workspace/skills/clawmail/.venv/bin/python
```

### ❌ Problem 3: `ModuleNotFoundError: No module named 'google'`
**What happened:** System `python3` doesn't have Google API packages.

**Fix:** Same — use clawmail venv which has all dependencies.

### ❌ Problem 4: `device token mismatch`
**What happened:** Gateway token rotated (by `openclaw onboard`) but agent session cached old token.

**Fix:** Updated TOOLS.md with current token. Gateway token: `2600ac3f8c52a4f2384c5a011de4bf1c2666689bf673348a`

### ❌ Problem 5: `400 reasoning summaries`
**What happened:** gpt-5.2 auto-enables `thinking=low` mode which requires org verification.

**Fix:** `"thinkingDefault": "off"` in `openclaw.json → agents.defaults`

---

## How to Extend — Adding New Categories

Edit `~/.openclaw/bin/mailwa_run.sh`, add to the prompt:

```bash
(D) INVOICES:
- Subject contains "חשבונית" OR "receipt"
- From: *@invoice.*, *@billing.*
```

And add routing in `route_lines()`:
```bash
inv="$(echo "$OUT" | awk -F'|' '$1 ~ /INVOICES/ {print}' | sed 's/^INVOICES */🧾 INVOICE /')"
[[ -n "$inv" ]] && send_wa "${WA_FALLBACK_JID}" "[${EMAIL}]\n${inv}"
```

---

## How to Test Manually

```bash
# Run instant scan right now (both mailboxes)
~/.openclaw/bin/mailwa_run.sh instant

# Run daily digest right now
~/.openclaw/bin/mailwa_run.sh daily

# Test Gmail reading directly
~/.openclaw/workspace/skills/clawmail/.venv/bin/python \
  ~/.openclaw/workspace/skills/clawmail/skill.py \
  digest golan.moyal@gmail.com 6

# Check LaunchAgent status
launchctl list | grep mailwa

# Pause auto-runs (during rate limit recovery etc.)
launchctl unload ~/Library/LaunchAgents/ai.openclaw.mailwa.instant.plist

# Resume auto-runs
launchctl load ~/Library/LaunchAgents/ai.openclaw.mailwa.instant.plist
```

---

## Rate Limit Awareness

The mail scanner uses the same AI API budget as the rest of ClawBot. **If the scanner loops or fails repeatedly, it will exhaust the API quota for ALL agents** (including WhatsApp replies).

**Safeguards in place:**
- ✅ Timestamped sessions → no overflow loops
- ✅ `mailwa-instant` paused during rate limit recovery
- ✅ Silent exit when no matching emails (no wasted API calls)
- ✅ Fallback chain: gpt-5.2 → gemini-2.5-flash

**If WhatsApp stops responding:** Check `launchctl list | grep mailwa` and look for a runaway session in `openclaw sessions list`.

---

*ClawBot Mail System | Mac M1 32GB | OpenClaw v2026.2.15*
