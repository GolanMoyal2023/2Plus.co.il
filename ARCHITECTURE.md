# ClawBot Personal Automation Architecture
**WhatsApp-first Control Plane with Apple Notes System Memory**

---

## 1. Core Principle

ClawBot is designed as a **chat-first personal automation system** where:

- **WhatsApp is the primary interaction gateway**
- **Apple Notes is the long-term system memory**
- **Email, web, and services are data sources**
- **Minimal always-on connections**
- **User stays in control**

This architecture optimizes for **daily real usage**, not theoretical automation.

---

## 2. High-Level Architecture

*(To be expanded: components, data flow, WhatsApp ↔ Notes ↔ services.)*

---

## 3. WhatsApp – Control Plane

### Role
WhatsApp is the **main communication pipeline** between the user and ClawBot.

It is:
- Fast
- Always open
- Personal + business friendly
- Used many times per day

### What WhatsApp Is Used For
- Asking questions
- Triggering searches
- Requesting actions
- Receiving alerts
- Getting summaries
- Giving follow-up instructions

### What WhatsApp Is NOT
- Not a database
- Not a task manager
- Not long-term memory

> **Rule:**  
> WhatsApp is **ephemeral by default**.

---

## 4. Apple Notes – System Memory Layer

### Role
Apple Notes is the **authoritative memory** of ClawBot.

It stores:
- Tasks
- Alerts
- Results
- Status updates
- Classified information
- Project states

### Why Apple Notes
- Native on iPhone / iPad / Mac
- No device-link limits
- Offline access
- Searchable
- Automation-friendly
- Zero extra authentication complexity

Apple Notes replaces the need for:
- Multiple WhatsApp bots
- Extra dashboards
- Long-running sync processes

---

## 5. Apple Notes Folder Structure

### Folder Semantics

#### 🚨 Security
- Google / Microsoft / Apple alerts
- Login anomalies
- Access changes
- Critical system warnings

#### 💳 Payments
- Apple / Microsoft / Google / PayPal
- Invoices
- Subscriptions
- Renewals
- Payment failures

#### 💼 Jobs
- Job offers
- Recruiter emails
- CV-based ranking
- Comparison notes

#### 📌 Tasks
- Explicit reminders
- Follow-ups
- User-approved actions

#### 📂 Projects
- Long-running initiatives
- Status snapshots
- Milestones
- Decisions

#### 🗂️ Personal Mail
- Family
- Personal administration
- Non-work important messages

#### 🗞️ Digests
- Daily summaries
- Weekly overviews
- Consolidated reports

---

## 6. Persistence Rules (Critical)

### Data is saved to Apple Notes ONLY IF:

- It is **incoming system information**
- It has **future value**
- It is a **final result**
- The user explicitly asks:
  - "save this"
  - "create a task"
  - "keep this"
  - "track this"

### Data is NOT saved if:

- It is exploratory
- It is conversational
- It is a one-time lookup
- It is temporary

---

## 7. Example Scenarios

### 🔍 Hotel Search
- User asks in WhatsApp
- Results returned in WhatsApp
- ❌ No Apple Note created

### 📧 Mailbox Search
- Results shown in WhatsApp
- ❌ No persistence

### 🚨 Security Alert
- Instant WhatsApp notification
- ✅ Saved under `🚨 Security`

### 💳 Payment / Invoice
- ✅ Saved under `💳 Payments`
- WhatsApp notification based on priority

### 💼 Job Offer
- ✅ Saved under `💼 Jobs`
- Ranked against CV
- Summary sent via WhatsApp

---

## 8. Priority & Notification Strategy

### Instant WhatsApp Alerts
- 🚨 Security events
- 💳 Failed payments
- Account access issues

### Scheduled Digests
- 💼 Job offers
- 🗞️ Newsletters
- Non-urgent payments

### Silent Storage
- Background information
- Low-priority items

---

## 9. Device Strategy (Intentional)

- Keep **WhatsApp linked devices minimal**
- Avoid hitting the 4-device limit
- Apple Notes handles persistence instead

This reduces:
- Sync instability
- WebSocket failures
- Always-on process complexity

---

## 10. Design Philosophy

- WhatsApp = keyboard
- Apple Notes = brain
- Automation = invisible
- Persistence = intentional
- Performance > complexity
- Human-first design

---

## 11. Final Statement

ClawBot is **not a chatbot**.

It is a **personal operating system** where:
- WhatsApp is how you talk
- Apple Notes is what remembers
- Automation works quietly
- Control always stays with you

This architecture is stable, scalable, and built for real life.
