---
name: siege
description: Use when you need comprehensive code health analysis, security auditing, or hardening. Combines 9-pillar static analysis (32+ battle-tested patterns), self-installing tool chain, optional 7-team live attack simulation (RED/BLACK/WHITE/CHROME/CANNON/FUZZER/COMMERCE), test infrastructure setup, and pattern learning. Triggers on security audits, pre-deployment checks, code quality reviews, PR reviews, or hardening any codebase.
---

# Siege

**Version**: 2.0 — Fortified Edition
**Lineage**: Shannon + PentAGI + HexStrike + Anthropic reasoning
**Teams**: 7 (RED, BLACK, WHITE, CHROME, CANNON, FUZZER, COMMERCE)
**Pillars**: 9 static analysis + privacy/compliance
**Philosophy**: No Exploit, No Report. Self-reflection. Attack path chaining.

Comprehensive code health and security analysis tool. 9-pillar static analysis + optional 7-team live attack simulation. Self-installing tool chain, checkpoint/resume, context pressure management, and pattern learning.

**Core principle:** A siege tests every wall, gate, and weakness — from both sides. Static analysis finds what's wrong in the code. Live attack simulation proves what's exploitable in production. No exploit, no report.

## When to Use

- Security audit before deployment or compliance review
- Code quality review on an unfamiliar codebase
- PR review (`--diff` mode — scan only changed files)
- Hardening sprint — find and fix all issues systematically
- Setting up test infrastructure from scratch
- Pre-launch security check with live attack simulation (`--live`)

## When NOT to Use

- Single-file bug fix (overhead not worth it)
- Pure UI/CSS changes with no logic
- Documentation-only changes
- Projects with no source code to analyze

## Arguments

Parse from the user's invocation. Defaults to full 7-pillar static scan.

| Argument | Effect |
|----------|--------|
| (none) | Full 7-pillar static analysis |
| `--scope=security` | Pillar 1 only |
| `--scope=quality` | Pillars 4 + 5 |
| `--scope=integration` | Pillars 2 + 3 |
| `--scope=testing` | Pillar 6 |
| `--scope=resilience` | Pillar 7 |
| `--live <URL>` | Static + 7-team live attack simulation against running instance |
| `--live <URL> --recon` | Static + Team RED recon only (no exploitation) |
| `--live <URL> --attack` | Static + full RED/BLACK/WHITE/CHROME/CANNON/FUZZER/COMMERCE team operation |
| `--live <URL> --osint` | OSINT + infrastructure audit only |
| `--fix` | Auto-fix safe issues (GHOST, QUALITY) after scan |
| `--diff` | Scan only `git diff` changed files (PR review mode) |
| `--resume` | Resume from `.siege/.checkpoint.json` |
| `--install-tools` | Install missing static analysis tools |
| `--install-offensive` | Install offensive security tools (separate for safety) |
| `--test` | Quick validation mode — minimal prompts, Pillar 1 only, fast timeout |

## Config File (Optional)

If `.siege.yml` exists in project root, load it for scan configuration:

```yaml
# .siege.yml
target:
  url: http://localhost:3000           # For --live mode
  auth:
    login_url: /login
    credentials:
      email: test@example.com
      password: testpass123
    success_condition: url_contains /dashboard

scan:
  avoid:                               # Paths to skip
    - node_modules/
    - .next/
    - dist/
    - "*.test.*"
  focus:                               # Paths to prioritize
    - src/app/api/
    - src/lib/auth/
    - src/middleware.ts

thresholds:
  risk_score_fail: 60                  # Fail if risk score below this
  max_critical: 0                      # Fail if any CRITICAL findings
  max_high: 5                          # Fail if more than 5 HIGH findings
```

---

## Execution Pipeline

### Phase 0: CONTEXT CHECK

Run first, every time.

1. **Check for checkpoint**: Read `.siege/.checkpoint.json`. If `--resume` and checkpoint exists, report status and skip to the first incomplete phase.
2. **Check context pressure** (bash: `wc -c` on transcript file):
   - GREEN (< 500KB): Full scan, normal agent usage
   - YELLOW (500KB-1MB): Use Haiku for less critical pillars, checkpoint more often
   - RED (> 1MB): Checkpoint immediately, summarize partial results, warn user
3. **Parse arguments**: Determine scope, mode, and flags.
4. **Report plan to user**: "Siege will run [N pillars] on [project]. Estimated: [X] minutes. Proceed?"
5. **Create output directory**: `.siege/` in project root.

### Phase 1: DETECT (Architecture Mapping)

Stack detection and tool availability check. Write results to `.siege/.architecture.md`.

**Detection sequence** (run in parallel via Bash):

```
1. Framework:   package.json -> Next.js/Express/Vite/etc.
                requirements.txt -> Django/FastAPI/Flask
                go.mod -> Go
2. TypeScript:  tsconfig.json -> TS version, strict mode status
3. Auth:        Grep for supabase|firebase|next-auth|passport|jwt
4. Database:    Grep for prisma|drizzle|supabase|firestore|mongoose
5. Testing:     Grep for vitest|jest|pytest|playwright|cypress
6. Services:    Grep for stripe|paystack|sendgrid|resend|twilio
7. API routes:  Glob for app/api/**/route.ts OR routes/**/*.ts
8. Tool check:  which semgrep && which knip && which trufflehog ...
```

**If `--install-tools`**: Install missing static tools. See [reference/tools.md](reference/tools.md).
**If `--install-offensive`**: Install missing offensive tools (requires user confirmation).

Write `.siege/.architecture.md` with detected stack summary.
**-> CHECKPOINT**

### Phase 2: SCAN (Automated Tools — Parallel via Bash)

Run all available tools in parallel. Each tool writes output to `.siege/.tool-{name}.json`.

| Tool | Command | When Available |
|------|---------|----------------|
| semgrep | `semgrep scan --config auto --json -o .siege/.tool-semgrep.json .` | `which semgrep` |
| knip | `npx knip --reporter json > .siege/.tool-knip.json` | package.json exists |
| npm audit | `npm audit --json > .siege/.tool-npm-audit.json` | package-lock.json exists |
| trufflehog | `trufflehog filesystem --json . > .siege/.tool-trufflehog.json` | `which trufflehog` |
| gitleaks | `gitleaks detect --report-format json --report-path .siege/.tool-gitleaks.json` | `which gitleaks` |
| tsc --strict | `npx tsc --strict --noEmit 2> .siege/.tool-tsc-strict.txt` | tsconfig.json exists |

If a tool is unavailable, skip it — the AI agents in Phase 3 compensate with manual analysis.

Log progress: `[Phase 2] semgrep: 12 findings, npm-audit: 3 vulns, knip: 8 unused exports...`

**-> CHECKPOINT**

### Phase 3: ANALYZE (9 Parallel AI Agents)

The core intelligence layer. Spawn 9 agents via the Task tool, ALL in parallel (use `subagent_type: "general-purpose"`, `model: "sonnet"`).

Each agent receives:
1. **Architecture context** from `.siege/.architecture.md`
2. **Relevant tool output** from Phase 2 (e.g., Pillar 1 gets semgrep + trufflehog output)
3. **Pattern library** — read [reference/patterns.json](reference/patterns.json) for detection patterns
4. **Pillar-specific prompt** — see [prompts/pillar-agents.md](prompts/pillar-agents.md)
5. **Scope filter** — if `--diff`, only analyze changed files from `git diff`
6. **Avoid/focus rules** from `.siege.yml` if present

Each agent returns:
- **Analysis markdown** -> `.siege/pillar-{N}-{name}.md`
- **Findings JSON array** -> parsed and merged in Phase 4

**Pillar mapping** (detail in [reference/pillars.md](reference/pillars.md)):

| # | Pillar | Focus | Patterns |
|---|--------|-------|----------|
| 1 | Security Penetration | OWASP, secrets, CVEs, data flows | SEC-001 to SEC-009 |
| 2 | Integration & Flow | Handoff bugs, state machines, promise chains | FLOW-001 to FLOW-004 |
| 3 | Contract Verification | RPC mismatches, RLS gaps, phantom features | CONTRACT-001 to CONTRACT-004 |
| 4 | Ghost Code | Dead deps, stubs, dead routes, phantom writes | GHOST-001 to GHOST-006 |
| 5 | Code Quality | Type safety, accessibility, monolith components | QUALITY-001 to QUALITY-005 |
| 6 | Test Gaps | Risk-weighted coverage, missing test files | TEST-001 to TEST-002 |
| 7 | Resilience | Error boundaries, silent failures, decorative UI | RESIL-001 to RESIL-004 |
| 8 | Privacy & Compliance | GDPR, account deletion, data export, cookie consent | PRIVACY-001+ (learning) |
| 9 | Business Logic & Financial Integrity | Price integrity, coupon fraud, race conditions, payment flows | BIZLOGIC-001+ (new) |

**Checkpoint after each agent completes** (partial results are safe).

**-> CHECKPOINT (per agent)**

### Phase 3.5: ATTACK SIMULATION (Only with `--live`)

**Prerequisites**: `--live <URL>` flag + target is reachable (health check first).

Run seven coordinated teams. Detail in [reference/offensive.md](reference/offensive.md).
Prompts in [prompts/offensive-teams.md](prompts/offensive-teams.md).

**Phase 3.5a: TEAM RED** — Reconnaissance
- Spawn agents for: port scanning, directory fuzzing, web crawling, tech fingerprinting, template vuln scanning
- Output: `.siege/red-team-recon.md` + `.siege/red-team-targets.json`
- **-> CHECKPOINT**

**Phase 3.5b: TEAM BLACK** — Exploitation (only if RED found targets)
- For each target in `red-team-targets.json`: attempt exploitation
- Tools: OWASP ZAP, sqlmap, dalfox, jwt_tool, Playwright browser automation
- **Ethical constraints**: Max 10 brute-force attempts, no destructive actions, confirm before active scanning
- Output: `.siege/black-team-exploits.md` + `.siege/black-team-evidence.json`
- **-> CHECKPOINT**

**Phase 3.5c: TEAM WHITE** — Intelligence Collection
- Document all successful exploits with reproduction steps
- Document near-misses and defenses that held
- CVSS v3.1 scoring, CWE/OWASP mapping
- OSINT checks, infrastructure audit, anti-forensics assessment
- Output: `.siege/white-team-intel.md`
- **-> CHECKPOINT**

**Phase 3.5d: TEAM CHROME** — Browser Attack Lab (--live only)
- Spawn browser attack agent using claude-in-chrome
- XSS injection on all input fields, CSRF validation, DOM manipulation
- Session handling tests, privilege escalation attempts
- Output: `.siege/chrome-team-browser.md` + `.siege/chrome-team-evidence.json`
- **-> CHECKPOINT**

**Phase 3.5e: TEAM CANNON** — Load & Stress Testing (--live only)
- Install load testing tool (hey/wrk/ab)
- Sequential load tests on each Cloud Function endpoint
- Rate limit validation, payload size testing, cold start measurement
- Output: `.siege/cannon-team-load.md` + `.siege/cannon-team-metrics.json`
- **-> CHECKPOINT**

**Phase 3.5f: TEAM FUZZER** — API Endpoint Fuzzing (--live only)
- Send malformed data to every API endpoint
- Missing fields, wrong types, overflow, injection, encoding, boundaries
- Shannon "No Exploit, No Report" — only report accepted/mishandled inputs
- Output: `.siege/fuzzer-team-results.md` + `.siege/fuzzer-team-findings.json`
- **-> CHECKPOINT**

**Phase 3.5g: TEAM COMMERCE** — Business Logic Adversary (--live only)
- E-commerce specific attacks: price manipulation, coupon fraud, race conditions
- Store-then-Pay attack scenarios, referral abuse, capacity bypass
- Output: `.siege/commerce-team-results.md` + `.siege/commerce-team-evidence.json`
- **-> CHECKPOINT**

### Phase 4: SYNTHESIZE (Report Generation)

1. **Merge findings**: Collect all findings from Phases 2, 3, and 3.5 into `.siege/findings.json`
2. **Deduplicate**: Multiple pillars/teams flagging same issue -> merge, keep highest severity
3. **Risk score**: Start at 100, deduct per finding: CRITICAL -15, HIGH -8, MEDIUM -3, LOW -1
4. **Positive findings**: Report what's done RIGHT (defenses that held, good patterns found)
5. **Cascading reveal detection**: Flag findings where fix A likely exposes bug B
6. **Generate reports**:
   - `.siege/SIEGE_REPORT.md` — Executive summary + all findings + remediation roadmap
   - `.siege/SIEGE_TESTS.md` — Auto-generated test plan from findings
   - `.siege/PENETRATION_REPORT.md` — Compliance-ready pentest report (only with `--live`)
7. **Compare to previous**: If `.siege/findings-previous.json` exists, show delta (new, resolved, score change)
8. **Log cost**: Tokens consumed per phase/agent, total scan time

**-> FINAL CHECKPOINT**

### Phase 5: FIX (Only with `--fix`)

Only runs if `findings.json` has entries.

**Auto-fix (no approval needed)**:
- Remove unused imports (QUALITY-002)
- Add missing aria-label to icon-only buttons (QUALITY-005)
- Remove dead dependencies (GHOST-001)
- Remove console.log in production (GHOST-004)
- Delete dead routes (GHOST-005)

**Propose fix (require user approval)**:
- All SEC-* findings (security changes need review)
- All FLOW-* findings (integration changes are risky)
- All CONTRACT-* findings (contract changes affect multiple layers)
- All RESIL-* findings (resilience changes affect error handling)

**Pattern learning**: Any new finding type not matching existing patterns -> propose adding to `patterns.json` with user approval.

---

## Checkpoint Protocol

Checkpoints save scan state to `.siege/.checkpoint.json` after each phase/agent.

```json
{
  "scan_id": "uuid",
  "started_at": "ISO-8601",
  "target": "project-name",
  "stack": "nextjs-supabase",
  "mode": "full",
  "phases_completed": ["detect", "scan"],
  "pillars_completed": [1, 4, 5],
  "pillars_in_progress": [2],
  "pillars_pending": [3, 6, 7],
  "findings_so_far": 23,
  "context_pressure": "GREEN"
}
```

On `--resume`:
1. Read checkpoint JSON
2. **Clean incomplete deliverables** — delete any pillar-N-*.md without corresponding findings (Shannon pattern)
3. Skip completed phases
4. Resume from first incomplete item

**Retry logic**: If a pillar agent fails, retry up to 3 times before marking as failed. Failed pillars are noted in the report but do not block synthesis.

## Context Pressure Management

Check pressure at the start of each phase. Adjust strategy based on transcript size.

| Level | Transcript | Action |
|-------|-----------|--------|
| GREEN | < 500KB | Normal — all pillars use Sonnet |
| YELLOW | 500KB-1MB | Use Haiku for Pillars 4, 5 (lower criticality). Checkpoint after every agent. |
| RED | > 1MB | Checkpoint NOW. Skip remaining pillars. Synthesize from what is available. |

## Output Structure

```
.siege/
  pillar-1-security.md ... pillar-9-business-logic.md # Per-pillar analysis
  red-team-recon.md, black-team-exploits.md           # Live attack (--live only)
  white-team-intel.md                                  # Intelligence (--live only)
  chrome-team-browser.md, chrome-team-evidence.json   # Browser attacks (--live only)
  cannon-team-load.md, cannon-team-metrics.json       # Load testing (--live only)
  fuzzer-team-results.md, fuzzer-team-findings.json   # API fuzzing (--live only)
  commerce-team-results.md, commerce-team-evidence.json # Business logic (--live only)
  findings.json                                        # All findings (machine-readable)
  red-team-targets.json, black-team-evidence.json     # Attack data (--live only)
  SIEGE_REPORT.md                                      # Executive summary + roadmap
  SIEGE_TESTS.md                                       # Auto-generated test plan
  PENETRATION_REPORT.md                                # Pentest report (--live only)
  .architecture.md, .checkpoint.json                   # Internal state
  .tool-*.json, .scan-log.md                           # Tool outputs + log
```

## Finding Format

```json
{
  "id": "SEC-001", "pillar": 1, "severity": "CRITICAL",
  "type": "hardcoded_secret",
  "file": "src/lib/supabase/client.ts", "line": 12,
  "description": "Supabase anon key exposed in client bundle",
  "fix_suggestion": "Move to server-side env var",
  "regression_test": "Verify key not in client JS bundle",
  "confidence": "High", "pattern_id": "SEC-001",
  "cascading_risk": "None", "positive": false,
  "cwe": "CWE-798", "cvss": 7.5
}
```

## Supporting Reference Files

Read these as needed during execution:

| File | When to Read |
|------|-------------|
| [reference/pillars.md](reference/pillars.md) | Phase 3 — building agent prompts |
| [reference/tools.md](reference/tools.md) | Phase 1 (install), Phase 2 (run) |
| [reference/offensive.md](reference/offensive.md) | Phase 3.5 — live attack mode |
| [reference/patterns.json](reference/patterns.json) | Phase 3 — agent pattern matching |
| [prompts/pillar-agents.md](prompts/pillar-agents.md) | Phase 3 — spawning agents |
| [prompts/offensive-teams.md](prompts/offensive-teams.md) | Phase 3.5 — spawning teams |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running all pillars at RED pressure | Checkpoint and synthesize partial results |
| Skipping Phase 1 detection | Architecture context makes agents 3x more accurate |
| Running `--live` without health check | Always verify target is reachable first |
| Using Opus for all agents | Sonnet is sufficient — save Opus for specialist review |
| Not deduplicating findings | Same issue by Pillar 1 + Pillar 3 = 1 finding, not 2 |
| Auto-fixing security issues | SEC-* findings always need human review |
| Ignoring positive findings | Reporting what is right builds confidence |
| Running offensive tools without confirmation | Always confirm before active scanning |
