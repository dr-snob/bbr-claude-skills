# Siege — 9 Pillars Reference

Detailed scope and detection strategies for each pillar agent.

## Pillar 1: Security Penetration

**Heritage**: Shannon injection/XSS/auth/authz/SSRF agents
**Patterns**: SEC-001 through SEC-009
**Tool input**: semgrep, trufflehog, gitleaks, npm audit output

### What to Look For

1. **Hardcoded secrets** — API keys, tokens, passwords in source (check client bundles)
2. **Fire-and-forget async** — `.then()` without `.catch()`, especially on signOut, audit logging
3. **Missing CSRF** — POST/PUT/DELETE routes without Origin header validation
4. **Cookie security** — Missing `secure`, `httpOnly`, `sameSite` flags
5. **CORS misconfiguration** — `cors: true` in Firebase, wildcard origins, credential reflection
6. **Error detail leakage** — `error.message` or stack traces in API responses
7. **Fail-open patterns** — Rate limiters, auth checks that default to "allow" on error
8. **Non-atomic idempotency** — Read-then-write without transaction (webhooks, payments)
9. **Dependency CVEs** — Known vulnerabilities in npm/pip/go dependencies
10. **Source-to-sink tracing** — User input to database, HTML, command, or file

### Detection Strategy

```
1. Run grep patterns from SEC-* in patterns.json
2. Cross-reference with semgrep findings
3. Check npm audit for known CVEs
4. Check trufflehog/gitleaks for exposed secrets
5. Trace every user input to its destination
6. Check every API route for: auth, CSRF, validation, error handling
7. Check every cookie for: secure, httpOnly, sameSite
8. Check every catch block: fail-open or fail-closed?
```

### Source-to-Sink Data Flow Tracing (Shannon)

For every user input point, trace the full data flow:
1. IDENTIFY SOURCES: form inputs, URL params, headers, cookies, file uploads
2. TRACE THROUGH: middleware, validation, sanitization, transformation
3. IDENTIFY SINKS: database writes, HTML output, command execution, file system, email templates
4. VERIFY: Is the input sanitized before reaching the sink? What sanitization method?
5. CLASSIFY: safe (sanitized before sink) | partial (some paths sanitized) | unsafe (raw to sink)

---

## Pillar 2: Deep Integration & Flow Analysis

**Heritage**: Novel — Shannon's blind spot. Born from MFA deadlock case study.
**Patterns**: FLOW-001 through FLOW-004
**Tool input**: Architecture detection (auth type, DB type, services)

### What to Look For

1. **Flow decomposition** — Break critical paths into segments: login > MFA > dashboard
2. **Handoff stress testing** — Step N succeeds but Step N+1 hangs
3. **State machine analysis** — Auth states, wizard steps — find dead states
4. **Promise chain analysis** — Unhandled rejections, hanging awaits
5. **Event listener audit** — Cleanup on unmount, mount/unmount races
6. **Browser API dependencies** — navigator.locks, sessionStorage, crypto.subtle
7. **Token validation across boundaries** — Client validates, server ignores (FLOW-001)
8. **Non-atomic capacity reservation** — Check > payment > webhook gap (FLOW-002)
9. **Non-idempotent handlers** — Webhook fires twice, both process (FLOW-003)

### Detection Strategy

```
1. Identify critical user flows (login, checkout, signup, admin)
2. Decompose each into sequential steps
3. For each boundary: what state is passed? What could fail?
4. Grep for navigator.locks, sessionStorage, addEventListener
5. Grep for .then( chains longer than 2 steps
6. Check all listeners for cleanup (return unsubscribe in useEffect)
7. Trace token lifecycle from creation to consumption
8. Check webhook handlers for idempotency (transaction wrapping)
```

---

## Pillar 3: Frontend-Backend Contract Verification

**Heritage**: Shannon recon agent — expanded to contracts
**Patterns**: CONTRACT-001 through CONTRACT-004
**Tool input**: Architecture detection (DB type, rules info)

### What to Look For

1. **RPC parameter mismatches** — Frontend params vs function signature
2. **Type mismatches** — TS interface says string but DB column is integer
3. **RLS/rules coverage gaps** — Tables with USING (true) in production
4. **Orphan code** — Frontend calls endpoint that does not exist
5. **Phantom features** — UI looks functional but DB rules block writes
6. **Missing server mediation** — Client writes privileged fields directly
7. **CSRF that fails open** — Origin check skips when header missing

### Detection Strategy

```
1. List all client-side API calls (fetch, supabase, setDoc, updateDoc)
2. Verify each target endpoint/function exists
3. Verify parameter types match server expectation
4. List all RLS policies / Firestore rules
5. For each table: verify write paths have non-trivial policies
6. Flag any USING (true) or allow write: if false
7. Check for direct client writes to privileged fields
```

---

## Pillar 4: Ghost Code & Dead Weight

**Heritage**: Etna Wave 1-2, Coco Snob Wave 2
**Patterns**: GHOST-001 through GHOST-006
**Tool input**: knip output, ts-prune output

### What to Look For

1. **Dead dependencies** — Listed in package.json but never imported
2. **Shim/re-export indirection** — Files that only re-export from another module
3. **Stub components** — setTimeout fake submit, hardcoded dropdowns, TODOs
4. **Ungated console.log** — Debug logging in production code
5. **Dead routes** — Minimal pages with no auth, no data, no purpose
6. **Phantom client writes** — Writes blocked by database rules

### Detection Strategy

```
1. Parse knip output for unused deps, exports, files
2. Check each dependency — is it imported anywhere in src/?
3. Find files whose only content is import + re-export
4. Grep for console.log in src/ (exclude test files)
5. Find route files with <5 lines and no data fetching
6. Cross-reference client writes with DB rules (from Pillar 3)
```

---

## Pillar 5: Code Quality & Patterns

**Heritage**: Etna Wave 3-4, Coco Snob Wave 4
**Patterns**: QUALITY-001 through QUALITY-005
**Tool input**: tsc --strict output, ESLint output

### What to Look For

1. **Untyped responses** — `as any` on database query results
2. **Unused imports/parameters** — noUnusedLocals disabled in tsconfig
3. **Cached auth tokens** — getIdTokenResult() without true (stale 1hr)
4. **Oversized components** — Files >400 lines mixing fetch + logic + render
5. **Accessibility gaps** — Icon-only buttons without aria-label

### Detection Strategy

```
1. Run tsc --strict if not already strict
2. Grep for `as any` and `: any` near database calls
3. Check tsconfig for noUnusedLocals, noUnusedParameters
4. Count lines per file — flag >400 lines
5. Find all <button> — check for text or aria-label
6. Grep for getIdTokenResult() without true
```

---

## Pillar 6: Test Coverage & Gap Analysis

**Heritage**: Etna test infrastructure build
**Patterns**: TEST-001 through TEST-002
**Tool input**: Test framework detection, existing coverage

### What to Look For

1. **API routes without tests** — POST/PUT/DELETE with zero coverage
2. **Timer hooks without fake timer tests** — setTimeout in hooks
3. **Risk-weighted coverage** — Auth untested = CRITICAL, about page = LOW
4. **Missing test framework** — No framework detected, recommend one
5. **No coverage thresholds** — CI does not enforce minimum

### Detection Strategy

```
1. List all API route files
2. For each: check for corresponding test file
3. List hooks using setTimeout/setInterval/Date.now
4. For each: check for vi.useFakeTimers tests
5. Categorize untested code by risk:
   CRITICAL: auth, payment, admin, data mutation
   HIGH: API endpoints, middleware, security utils
   MEDIUM: Feature components, data fetching
   LOW: Static pages, layout
6. Generate test plan prioritized by risk
```

---

## Pillar 7: Resilience & Edge Case Hunting

**Heritage**: Etna Wave 13-14, Coco Snob Wave 14
**Patterns**: RESIL-001 through RESIL-004
**Tool input**: Architecture detection (framework, DB type)

### What to Look For

1. **Missing error boundaries** — No ErrorBoundary = white screen on render error
2. **Silent data suppression** — Query error unchecked, shows empty state
3. **Decorative UI controls** — Dropdown with no onChange or state binding
4. **Listeners without error callbacks** — onSnapshot with only success callback
5. **Network failure handling** — API down: loading forever or error message?
6. **Empty states** — List with no items: message or blank?
7. **Concurrent operations** — Two users editing same record: conflict resolution?

### Detection Strategy

```
1. Search for ErrorBoundary, componentDidCatch, error.tsx
2. If none: flag CRITICAL
3. Grep for .from( or supabase. — check both data and error handled
4. Find <select>, toggle — check for onChange
5. Grep for onSnapshot — check for error callback
6. Check list components for empty state rendering
7. Look for optimistic updates without rollback
```

---

## Pillar 8: Privacy & Data Protection Compliance (NEW)

**Heritage**: EU GDPR, CCPA, POPIA requirements
**Patterns**: PRIVACY-001 onwards (new, will grow via pattern learning)

### What to Look For

1. **Account deletion** — Can users delete their account and ALL associated data?
2. **Data export/portability** — Can users download their data (GDPR Art 20)?
3. **Cookie consent** — Is there a cookie banner? Does it actually block tracking before consent?
4. **Privacy policy** — Does one exist? Is it linked from signup/checkout?
5. **Data minimization** — Is the app collecting more data than needed?
6. **Consent for marketing** — Are marketing emails opt-in (not opt-out)?
7. **Third-party data sharing** — Are analytics/tracking pixels disclosed?
8. **Data retention** — Is old data automatically purged? Or kept forever?
9. **Right to rectification** — Can users edit their personal data?
10. **Breach notification** — Is there a process for notifying users of data breaches?
11. **Children's data** — Age verification if applicable (COPPA/GDPR Art 8)?
12. **Cross-border transfers** — Data stored outside EU without adequate protections?

### Detection Strategy

```
1. Search for /delete-account, /account/delete, deleteUser, removeAccount
2. Search for /export, /download-data, exportUserData
3. Search for cookie consent/banner components, tracking scripts loading before consent
4. Check for privacy-policy route/page
5. Grep for analytics: gtag, GA4, fbq, hotjar, mixpanel, segment, amplitude
6. Check signup forms for marketing consent checkbox (must be unchecked by default)
7. Check data models — what PII is stored? Is it encrypted at rest?
8. Check for data retention policies or TTL on user records
9. Look for profile edit functionality covering all stored PII
```

---

## Pillar 9: Business Logic & Financial Integrity (NEW)

**Heritage**: E-commerce fraud prevention, payment security
**Patterns**: BIZLOGIC-001 onwards

### What to Look For

1. **Price integrity** — Can prices be manipulated between client and server?
2. **Discount abuse** — Can coupons be stacked, reused, or fabricated?
3. **Points/loyalty fraud** — Can users claim more points than they have?
4. **Inventory manipulation** — Can capacity checks be bypassed?
5. **Order duplication** — Are webhook handlers idempotent?
6. **Race conditions** — Can concurrent requests create inconsistent state?
7. **Referral abuse** — Can users refer themselves or game the system?
8. **Payment flow integrity** — Is the Store-then-Pay chain unbreakable?
9. **Rush fee bypass** — Can rush orders avoid the 50% surcharge?
10. **Tier manipulation** — Can users escalate their loyalty tier?

### Detection Strategy

```
1. Trace every price from product definition -> cart -> checkout -> payment -> order
2. Check coupon validation: server-side? expiry check? used check? user-bound?
3. Check points deduction: atomic transaction? validated before payment?
4. Check webhook idempotency: transaction-wrapped? reference-based dedup?
5. Check capacity: reserved before or after payment? race window?
6. Check referral: self-referral prevention? minimum purchase requirement?
```
