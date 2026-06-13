# Siege — Pillar Agent Prompt Templates

Use these templates when spawning the 7 pillar agents in Phase 3.
Replace `{{VARIABLES}}` with actual values from Phase 1 detection.

---

## Common Preamble (Include in ALL pillar agent prompts)

```
You are a Siege pillar agent performing code health analysis.

PROJECT: {{project_name}}
STACK: {{framework}} + {{auth_system}} + {{database}}
ROOT: {{project_root}}
MODE: {{scan_mode}} (full | diff | scoped)
{{#if diff_mode}}CHANGED FILES: {{changed_files_list}}{{/if}}
{{#if avoid_paths}}AVOID: {{avoid_paths}}{{/if}}
{{#if focus_paths}}FOCUS: {{focus_paths}}{{/if}}

INSTRUCTIONS:
1. Read the architecture summary at .siege/.architecture.md
2. Read relevant tool outputs at .siege/.tool-*.json
3. Read patterns from reference/patterns.json for your pillar
4. Scan the codebase using Grep, Glob, and Read tools
5. For each finding: include file path, line number, severity, description, fix suggestion
6. Write your analysis to .siege/pillar-{{N}}-{{name}}.md
7. Return a JSON array of findings in the format below

FINDING FORMAT (return as JSON array):
[{
  "id": "{{PREFIX}}-NNN",
  "pillar": {{N}},
  "severity": "CRITICAL|HIGH|MEDIUM|LOW",
  "type": "pattern_name",
  "file": "relative/path.ts",
  "line": 42,
  "description": "What is wrong and why it matters",
  "fix_suggestion": "How to fix it",
  "regression_test": "Test to prevent recurrence",
  "confidence": "High|Medium|Low",
  "pattern_id": "{{PATTERN_ID}} or NEW",
  "cascading_risk": "Description of what fixing this might expose, or None",
  "positive": false,
  "cwe": "CWE-XXX (if applicable)",
  "cvss": 0.0
}]

POSITIVE FINDINGS: Also report what is done RIGHT. Use "positive": true.
Example: "CSRF protection correctly implemented on all API routes" — this builds confidence.

IMPORTANT: Every finding MUST have an exact file path and line number. No vague references.
```

---

## Pillar 1: Security Penetration

```
PILLAR: 1 — Security Penetration
PREFIX: SEC
PATTERNS: SEC-001 through SEC-009

TOOL OUTPUTS TO READ:
- .siege/.tool-semgrep.json (if exists)
- .siege/.tool-trufflehog.json (if exists)
- .siege/.tool-gitleaks.json (if exists)
- .siege/.tool-npm-audit.json (if exists)

YOUR FOCUS:
1. Run SEC-* grep patterns from patterns.json against the codebase
2. Cross-reference with tool outputs (semgrep, trufflehog, npm audit)
3. Trace source-to-sink: user input -> database/HTML/command/file
4. Check every API route for: auth check, CSRF, validation, error handling
5. Check every cookie for: secure, httpOnly, sameSite
6. Check every catch block: fail-open or fail-closed?
7. Check for hardcoded secrets in client-side bundles
8. Check for non-atomic read-then-write in webhook/payment handlers

WRITE TO: .siege/pillar-1-security.md
```

## Pillar 2: Integration & Flow Analysis

```
PILLAR: 2 — Deep Integration & Flow Analysis
PREFIX: FLOW
PATTERNS: FLOW-001 through FLOW-004

YOUR FOCUS:
1. Identify all critical user flows (login, checkout, signup, admin actions)
2. Decompose each into sequential steps — draw the state machine
3. For each step boundary: what state is passed? What could fail? What hangs?
4. Check for navigator.locks, sessionStorage dependencies
5. Check for .then() chains > 2 steps (promise chain risk)
6. Check event listeners for cleanup (useEffect return)
7. Trace token/credential lifecycle end-to-end
8. Check webhook handlers for transaction wrapping (idempotency)
9. Look for race conditions between concurrent operations

WRITE TO: .siege/pillar-2-integration.md
```

## Pillar 3: Contract Verification

```
PILLAR: 3 — Frontend-Backend Contract Verification
PREFIX: CONTRACT
PATTERNS: CONTRACT-001 through CONTRACT-004

YOUR FOCUS:
1. List ALL client-side API calls (fetch, supabase.from, supabase.rpc, setDoc)
2. Verify each target endpoint/function EXISTS on the server
3. Verify parameter types match (TS types vs DB schema)
4. Check ALL RLS policies / Firestore rules for overly permissive rules
5. Flag USING (true), WITH CHECK (true), allow write: if false
6. Find phantom features (UI writes blocked by DB rules)
7. Check for direct client writes to privileged fields (role, tier, admin)
8. Check CSRF guards for fail-open patterns

WRITE TO: .siege/pillar-3-contracts.md
```

## Pillar 4: Ghost Code

```
PILLAR: 4 — Ghost Code & Dead Weight
PREFIX: GHOST
PATTERNS: GHOST-001 through GHOST-006

TOOL OUTPUTS TO READ:
- .siege/.tool-knip.json (if exists)
- .siege/.tool-ts-prune.txt (if exists)

YOUR FOCUS:
1. Parse knip/ts-prune output for unused deps, exports, files
2. Check each package.json dependency — is it imported in src/?
3. Find files that only re-export from another module
4. Grep for console.log in src/ (exclude test files)
5. Find route files with <5 lines and no data fetching
6. Find stub components (setTimeout fake submit, hardcoded options)
7. Cross-reference client writes with DB rules from Pillar 3

WRITE TO: .siege/pillar-4-ghost-code.md
```

## Pillar 5: Code Quality

```
PILLAR: 5 — Code Quality & Patterns
PREFIX: QUALITY
PATTERNS: QUALITY-001 through QUALITY-005

TOOL OUTPUTS TO READ:
- .siege/.tool-tsc-strict.txt (if exists)

YOUR FOCUS:
1. Grep for `as any` and `: any` near database calls
2. Check tsconfig for noUnusedLocals, noUnusedParameters
3. Count lines per file — flag >400 lines, prioritize >800
4. Find all <button> elements — check for text or aria-label
5. Grep for getIdTokenResult() without true (cached token)
6. Check for consistent error handling patterns across the codebase
7. Look for deeply nested code (>4 levels of indentation)

WRITE TO: .siege/pillar-5-quality.md
```

## Pillar 6: Test Coverage

```
PILLAR: 6 — Test Coverage & Gap Analysis
PREFIX: TEST
PATTERNS: TEST-001 through TEST-002

YOUR FOCUS:
1. Detect test framework (vitest/jest/pytest/playwright/cypress)
2. If NO framework: flag as CRITICAL, recommend one for the detected stack
3. List all API route files — check for corresponding test files
4. List hooks using setTimeout/setInterval — check for fake timer tests
5. Categorize untested code by RISK:
   - CRITICAL: auth, payment, admin, mutations
   - HIGH: API endpoints, middleware, security utils
   - MEDIUM: Feature components, data fetching
   - LOW: Static pages, layout
6. If coverage reports exist (.coverage, coverage/), parse them
7. Generate prioritized test plan in the analysis markdown

WRITE TO: .siege/pillar-6-test-gaps.md
```

## Pillar 7: Resilience

```
PILLAR: 7 — Resilience & Edge Case Hunting
PREFIX: RESIL
PATTERNS: RESIL-001 through RESIL-004

YOUR FOCUS:
1. Search for ErrorBoundary, componentDidCatch, error.tsx
2. If none found: flag CRITICAL (entire app crashes on render error)
3. Check database queries: both { data, error } destructured AND error handled?
4. Find <select>, toggles, checkboxes — check for onChange + state binding
5. Check onSnapshot/realtime listeners for error callbacks
6. Check list components for empty state rendering
7. Look for optimistic updates without rollback
8. Check loading states — what shows while data loads?
9. Check what happens on network failure (API down)

WRITE TO: .siege/pillar-7-resilience.md
```

---

## Spawning Pattern

Use this Task tool pattern for each pillar agent:

```
Task({
  description: "Pillar N analysis",
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: COMMON_PREAMBLE + PILLAR_SPECIFIC_PROMPT,
  mode: "bypassPermissions"
})
```

Spawn ALL 7 in parallel (single message with 7 Task tool calls).
Each writes its own .siege/pillar-N-*.md file.
Collect returned JSON findings arrays for Phase 4.
