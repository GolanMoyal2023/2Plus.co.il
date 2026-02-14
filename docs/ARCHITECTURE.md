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

*(To be expanded: folder hierarchy, naming conventions, note templates.)*

---
