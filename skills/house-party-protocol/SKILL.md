---
name: house-party-protocol
description: Use when a task is complex enough for multiple agents to work in parallel with sacred file ownership, shared contracts for cross-cutting concerns, prep & review protocol for idle agents, and pre-completion checklists. Field-tested across 2 sessions (6 agents, 15 tasks, 23 files). Triggers on large features (4+ files), multi-file refactors, competing hypotheses, debugging, or any task where orchestration beats intelligence.
---

# House Party Protocol

Multi-agent team orchestration where agents work in parallel with sacred file ownership, shared contracts for cross-cutting concerns, and lead-directed idle utilization.

**Core principle:** Better orchestration beats smarter models. Break work into focused subtasks with clear file ownership, let agents solve them in parallel, and when someone finishes — the lead assigns them prep, review, or pre-assigns their next task.

## When to Use

- Complex feature spanning 4+ files
- Problem with multiple valid approaches (need consensus)
- Research from multiple angles simultaneously
- Debugging with competing hypotheses
- Large refactors where agents can own separate modules

## When NOT to Use

- Single-file edits or quick fixes
- Sequential tasks with hard dependencies between every step
- Tasks where coordination overhead exceeds the work itself

## Prerequisites

Enable agent teams (experimental):

```json
// ~/.claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Display modes:**
- **In-process** (default): Shift+Up/Down to navigate teammates
- **Split panes** (tmux/iTerm2): Each agent gets its own pane

---

## The 8 Party Rules

### Rule 1: The Host Sets the Table (Lead in Delegate Mode)

The lead NEVER codes. It decomposes work, spawns teammates, manages tasks, and synthesizes results. Always use **delegate mode** (Shift+Tab after team creation).

```
Create an agent team for [task]. Use delegate mode.
Spawn teammates with single responsibilities:
- [Name]: [focused responsibility] — owns [specific files]
- [Name]: [focused responsibility] — owns [specific files]
```

**Why delegate mode matters:** Without it, the lead starts implementing instead of coordinating. A host who cooks, serves, and DJs does everything poorly.

### Rule 2: Guests Arrive Briefed (Context-Rich Spawning)

Teammates don't inherit conversation history. Give them everything upfront:

```
Spawn teammate "auth-specialist" with prompt:
"You own src/auth/ and tests/auth/.
Task: Implement JWT refresh token rotation using httpOnly cookies.
When done: Message 'api-worker' with the new token interface.
If stuck: Message the lead for help or ask a free teammate."
```

**Must include in every spawn:**
- File ownership (which files they own exclusively)
- Task scope (what to build)
- Communication targets (who to message when done or stuck)
- Permission to ask for help
- Pre-completion checklist (see Rule 8)
- Swarming instructions (see Rule 4)

**File ownership is sacred — even during swarming.** One agent per file, no exceptions. When work crosses file boundaries (Agent A's work requires a change in Agent B's file), resolve via **shared contracts**:
- Agent A messages Agent B: "Your file needs to handle X"
- They agree on a contract (query param, interface, function signature)
- Each implements their side in their own file
- Neither touches the other's file

Example: A reset-password page needs a success banner on the login page. The reset-password agent redirects to `/login?reason=password_reset` (contract). The login page owner adds the banner. No file conflict.

### Rule 3: Guests Talk Directly (Peer Communication)

Teammates message each other — the lead doesn't relay everything. This is what separates teams from subagents.

**Communication patterns:**
- **Handoff:** "Auth module done. Here's the interface: [contract]"
- **Help request:** "Stuck on rate limiting. Anyone free to assist?"
- **Challenge:** "Your session handler has a race condition. Consider a mutex."
- **Status update:** "Security scan 60% done. Covering auth, API, and input validation. Still need: CSRF, file upload, and secrets scanning."

### Rule 4: Prep & Review Protocol (Idle Agent Utilization)

When agents finish their task, the lead immediately assigns them useful work. **This is lead-enforced, not voluntary** — idle agents don't choose what to do next; the lead directs them.

**Why not "Study Group" (co-implementation)?** Field-tested across 2 sessions (6 agents, 15 tasks, 23 files): true co-implementation on the same task never fires. The file ownership rule (Rule 2) prevents it — if Agent A owns `login/page.tsx`, Agent B can't touch it. The only things B can do are prep, review, or work on *different* files (which is really a separate task, not swarming). This tension between "force helpers onto busy agents" and "one agent per file" means idle agents are most valuable doing **prep and review**, not co-implementing.

**What actually works — Lead assigns one of three roles:**

1. **Pre-assign the next blocked task** — If a task will unblock soon, assign it to the idle agent now. Have them prep: read patterns, gather context, understand the files they'll own. When the blocker clears, they start immediately instead of ramping up.

2. **Review completed output** — Have the idle agent verify another agent's finished work against requirements. This catches integration gaps the implementer missed (e.g., audit calls not added, shared contracts not honored).

3. **Different-file delegation** — Only when a busy agent's remaining work spans 5+ files AND the helper can take entire files they haven't started. The lead messages the busy agent: "[idle-agent] is available. Delegate files you haven't started." The busy agent provides context for those specific files.

**Lead protocol when agent goes idle:**

1. Agent A finishes its task and reports to lead
2. Lead checks TaskList:
   - **Unblocked tasks available?** → Assign directly to Agent A
   - **Tasks about to unblock?** → Pre-assign with prep instructions ("read X, Y, Z files while you wait")
   - **No available tasks?** → Assign Agent A to review another agent's completed work
3. **Never let an agent sit idle without direction**

**Spawn prompt addition for all teammates:**
```
When you finish your task:
1. Mark it completed via TaskUpdate
2. Check TaskList for unclaimed, unblocked work — claim if available
3. If none: message the lead immediately with your status
4. The lead will assign you prep, review, or a pre-assigned task
5. If pre-assigned a blocked task: read related files and prep while waiting
```

### Rule 5: Bring the Best to the Table (Model Selection)

Not all agents need the same brain. Match model to role:

| Role Type | Model | Why |
|-----------|-------|-----|
| **Specialists** (security, architecture, performance) | **Opus** | Deep reasoning, catches subtle issues |
| **Workers** (implementation, tests, refactoring) | **Sonnet** | Fast, capable, cost-effective |
| **Scouts** (research, file discovery, quick checks) | **Haiku** | Cheap, fast, good enough for exploration |
| **Lead** | **Inherits** | Uses whatever the session runs |

```
Spawn teammate "security-specialist" with model opus and prompt:
"You are a senior security engineer with deep expertise..."

Spawn teammate "frontend-worker" with model sonnet and prompt:
"Implement the dashboard components in src/components/..."

Spawn teammate "codebase-scout" with model haiku and prompt:
"Find all files that handle user authentication..."
```

**Specialists always get Opus.** When you need expertise, send the best. A security review by Haiku is worse than no review — it creates false confidence.

### Rule 6: The Vote (Consensus Mechanisms)

For decisions with multiple valid approaches, don't let one agent decide. Use consensus.

**Pattern A — Adversarial Debate (strongest):**
```
Spawn 3 teammates to each independently design the caching layer.
Each must critique the other two designs.
The design that survives the most challenges wins.
```

**Pattern B — Parallel Implementation + Judge:**
```
Spawn 2 teammates to each implement the same feature independently.
Spawn a third "judge" agent (Opus) to compare both implementations
on: correctness, readability, performance, edge cases.
Lead picks the winner based on judge report.
```

**Pattern C — Majority Agreement:**
```
Spawn 3 agents to each review the same code independently.
Issues flagged by 2+ agents are real. Issues flagged by only 1 need discussion.
```

### Rule 7: Quality Gates (Hook Enforcement)

Use hooks to prevent premature completion and enforce standards:

**TeammateIdle hook** — catch agents trying to stop too early:
```json
{
  "hooks": {
    "TeammateIdle": [{
      "hooks": [{
        "type": "command",
        "command": "./scripts/check-teammate-done.sh"
      }]
    }]
  }
}
```

**TaskCompleted hook** — validate work before marking done:
```json
{
  "hooks": {
    "TaskCompleted": [{
      "hooks": [{
        "type": "command",
        "command": "./scripts/validate-task.sh"
      }]
    }]
  }
}
```

Exit code 2 from the hook script blocks completion and sends feedback to the agent.

### Rule 8: The Checklist Before Last Call (Pre-Completion Protocol)

Agents must complete a 5-step checklist before reporting any task as done. This prevents missed requirements — especially from messages received mid-task.

**Add to ALL agent spawn prompts:**
```
Before reporting task complete:
1. Re-read all messages received during this task
2. Verify every requirement mentioned in those messages is implemented
3. List any items you received mid-task and confirm coverage
4. Code integrity check:
   - All imports resolve to real files/exports (no phantom imports)
   - Functions you created are actually called from somewhere
   - No dead code, placeholder TODOs, or cosmetic-only additions
   - Cross-file connections work end-to-end (e.g., redirect target
     page exists, shared contracts match on both sides)
5. If you skipped anything, explain why to the lead
6. CRITICAL: "Explain why" is a FLAG, not a resolution. The work must
   still be completed after resolution with the lead. The loop does not
   close until the work is done OR the lead explicitly waives it.
```

**Why this matters:** In practice, agents receive mid-task messages from the lead or peers (e.g., "also add a password_reset case to the login page"). These messages arrive while the agent is deep in implementation and get acknowledged but not integrated. The code integrity step catches ghost code — functions that exist but nothing calls, imports that point to files that don't exist yet, or cosmetic additions that look right but aren't wired up. The checklist forces a deliberate review pass before completion.

**The lead's role:** When an agent reports "I skipped X because Y":
- Lead evaluates the reason
- If valid: lead waives it explicitly ("Acknowledged, skip approved")
- If not valid: lead sends the agent back ("Implement X before marking complete")
- Task stays in_progress until resolved either way

---

## Party Compositions

### The Research Party
| Role | Model | Responsibility |
|------|-------|---------------|
| Lead | inherit | Decomposes question, synthesizes findings |
| Researcher A | haiku | Codebase analysis |
| Researcher B | haiku | Documentation and external sources |
| Researcher C | haiku | Similar implementations / prior art |
| Devil's Advocate | opus | Challenges all findings, finds holes |

### The Build Party
| Role | Model | Responsibility |
|------|-------|---------------|
| Lead (delegate) | inherit | Task management only |
| Frontend Worker | sonnet | UI components and pages |
| Backend Worker | sonnet | API endpoints and data layer |
| Test Writer | sonnet | Tests for both, runs suite |
| Architect | opus | Reviews integration points, catches design issues |

### The Debug Party
| Role | Model | Responsibility |
|------|-------|---------------|
| Lead | inherit | Coordinates hypotheses, picks winner |
| Hypothesis A | sonnet | Investigates theory 1 |
| Hypothesis B | sonnet | Investigates theory 2 |
| Hypothesis C | sonnet | Investigates theory 3 |
| Reproducer | haiku | Creates minimal reproduction case |

### The Review Party
| Role | Model | Responsibility |
|------|-------|---------------|
| Security Reviewer | opus | Vulnerabilities, auth, injection, secrets |
| Performance Reviewer | opus | Bottlenecks, memory, query optimization |
| Quality Reviewer | sonnet | Tests, readability, maintainability |

---

## Task Sizing Guide

| Size | Example | Agents |
|------|---------|--------|
| Too small | Fix a typo | 1 (don't use teams) |
| Just right | Implement auth module | 3-4 |
| Just right | Full-stack feature | 4-5 |
| Too large | Rewrite entire app | Split into phases first |

**Sweet spot:** 5-6 tasks per teammate.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Lead starts coding | Use delegate mode (Shift+Tab) |
| Same file owned by 2 agents | Assign exclusive file ownership — sacred even during swarming (Rule 2) |
| No context in spawn prompt | Include files, scope, communication targets, checklist, swarming instructions |
| All agents use same model | Match model to role (Rule 5) |
| Agent finishes and goes idle forever | Lead immediately assigns prep, review, or pre-assigns next task (Rule 4) |
| Busy agent self-claims all unblocked tasks | Lead pre-assigns blocked tasks to idle agents so they're ready when unblocked |
| Helper touches same file as busy agent | Helpers do prep/review or take entirely different files only (Rule 4) |
| Task design puts same file in 2 agents' scope | Create explicit file ownership table; same-file tasks must be sequential (blockedBy) |
| Agent adds imports but not the actual code | Lead must Grep-verify output; import ≠ implementation (Rule 8) |
| Cross-cutting concern causes file conflict | Use shared contracts — query params, interfaces, function signatures (Rule 2) |
| Agent misses mid-task message requirements | Pre-completion checklist catches it — re-read all messages before reporting done (Rule 8) |
| Agent reports "skipped X" and moves on | "Explain why" is a flag, not resolution — loop stays open until done or waived (Rule 8) |
| Single agent makes critical decision | Use consensus voting (Rule 6) |
| No quality checks | Add TeammateIdle/TaskCompleted hooks (Rule 7) |

## What This Adds Beyond Vanilla Agent Teams

| Vanilla Agent Teams | House Party Protocol |
|---|---|
| Spawn teammates with tasks | **Lead-directed idle utilization** — lead immediately assigns prep, review, or pre-assigns blocked tasks to idle agents |
| Self-claim next task | **Prep & Review Protocol** — idle agents prep for blocked tasks, review completed output, or take entirely separate files. Never same file as busy agent |
| All agents same model | **Model-per-role strategy** — Opus specialists, Sonnet workers, Haiku scouts |
| No built-in consensus | **3 consensus patterns** — adversarial debate, parallel+judge, majority |
| Manual quality checks | **Hook-based gates** — TeammateIdle and TaskCompleted enforcement |
| Generic team structure | **Pre-built party compositions** with model assignments per role |
| Agents report "done" whenever | **5-step pre-completion checklist** — re-read messages, verify coverage, no escape without resolution |
| Cross-cutting concerns cause conflicts | **Shared contracts** — agents agree on interfaces/params, each implements in their own files |
