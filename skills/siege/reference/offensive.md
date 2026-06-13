# Siege — Offensive Security Simulation Reference

Seven coordinated agent teams operating against a LIVE running instance.
This is the `--live` mode — dynamic analysis against a running application.

**Requires**: `--live http://localhost:3000` or `--live https://deployed-url.web.app`

## V2 Principles (Shannon + PentAGI + HexStrike)

1. **No Exploit, No Report** (Shannon): Hypothetical vulnerabilities are discarded.
   Only report findings with working proof-of-concept exploits or server misbehavior.

2. **Self-Reflection** (HexStrike): Each agent reviews its own findings before
   submitting. Ask: "Is this a real vulnerability or am I hallucinating?"
   Confidence score required for each finding.

3. **Attack Path Chaining** (HexStrike): Don't just find individual vulns.
   Map multi-step attack paths with success probability estimates.

4. **Human Approval Gate** (PentAGI): Dangerous operations (active exploitation,
   data access, brute force) require explicit confirmation in the prompt.
   Fail-closed: if unsure, do NOT proceed.

5. **Positive Findings** (Siege original): Report defenses that HELD.
   "Rate limiting activated at request #12" is valuable intelligence.

---

## Team RED — Reconnaissance (The Scouts)

**Mission**: Map the attack surface. Find every door, window, and crack. Feed targets to Team BLACK.
**Model**: Sonnet

### Operations

| Operation | Tool | What It Does |
|-----------|------|-------------|
| Port scan | nmap | Open ports, services, OS fingerprint |
| Subdomain enum | subfinder | Discover staging, admin, api subdomains |
| Tech fingerprint | httpx | Live hosts, tech stack, status codes |
| Web crawl | katana | Spider site, find hidden pages, map endpoints |
| Dir fuzz | ffuf | Brute-force hidden dirs (/admin, /debug, /.env) |
| Server misconfig | nikto | Default files, dangerous HTTP methods |
| Template scan | nuclei | CVEs, misconfigs, exposed panels, default creds |

### Output Format

`red-team-recon.md` — Human-readable attack surface map
`red-team-targets.json`:
```json
{
  "targets": [{
    "id": "RT-001",
    "type": "exposed_endpoint",
    "url": "/api/admin/debug",
    "method": "GET",
    "status": 200,
    "risk": "HIGH",
    "discovered_by": "ffuf",
    "notes": "Debug endpoint accessible without auth"
  }]
}
```

---

## Team BLACK — Exploitation (The Hackers)

**Mission**: Take RED targets and break in. Successful exploits prove real vulnerabilities.
**Model**: Sonnet

### Operations

| Operation | Tool | Attack Type |
|-----------|------|------------|
| Full web scan | OWASP ZAP | XSS, SQLi, CSRF, OWASP Top 10 |
| SQL injection | sqlmap | SQLi in params, headers, cookies |
| XSS scanning | dalfox | Reflected, stored, DOM XSS |
| Command injection | commix | OS command injection |
| JWT attacks | jwt_tool | Algorithm confusion, claim tampering |
| Auth brute-force | hydra | Password spraying (max 10 attempts) |
| Browser exploit | Playwright MCP | Full browser XSS, CSRF, clickjacking |
| API exploit | curl/httpie | Bypass frontend validation |

### Attack Chains

1. **Anonymous to User**: Malicious input > stored XSS > steal admin session
2. **User to Admin**: JWT claim tampering > role escalation > admin endpoints
3. **Read to Write**: SQLi in search > DB modification > data exfiltration
4. **Frontend bypass**: Remove client validation > submit to API directly
5. **Session hijack**: Cookie theft via XSS > replay > impersonate user
6. **Business logic**: Price manipulation, inventory tampering, order duplication
7. **Rate limit bypass**: Rotate headers > circumvent brute-force protection
8. **SSRF chain**: Find SSRF > internal services > cloud metadata

### Ethical Constraints (MANDATORY)

- Max 10 brute-force attempts per account
- No destructive actions (no DELETE, no data modification)
- Confirmation before active scanning
- Read-only exploitation preferred
- Log every action (Team WHITE documents)
- Respect rate limits (back off on 429)

### Output Format

`black-team-exploits.md` + `black-team-evidence.json`:
```json
{
  "exploits": [{
    "id": "BT-001",
    "target_id": "RT-001",
    "technique": "auth_bypass",
    "severity": "CRITICAL",
    "cvss": 9.1,
    "cwe": "CWE-306",
    "proof": "curl -X GET http://localhost:3000/api/admin/debug -> 200 OK",
    "impact": "Full admin access without authentication",
    "chain": ["RT-001 -> BT-001"],
    "reproduction_steps": ["1. curl ...", "2. Observe 200 OK"]
  }]
}
```

---

## Team WHITE — Intelligence Collection (The Analysts)

**Mission**: Document EVERYTHING. Run alongside RED and BLACK.
**Model**: Sonnet

### Core Documentation

| What | Why |
|------|-----|
| Successful exploits | Proof with reproduction steps |
| Near-misses | One change away from exploitable |
| Defense assessment | Security controls that worked |
| Exploitation chains | Multi-step real-world scenarios |
| CVSS v3.1 scoring | Standardized compliance severity |
| CWE/OWASP mapping | Auditor/regulator language |
| Impact assessment | What data could be stolen |
| Remediation priority | Exploitability x impact x effort |

### Additional Checks

**Supply Chain**: npm audit, typosquatting, dependency confusion, lockfile integrity, unmaintained deps
**Infrastructure**: TLS/SSL (testssl), HTTP headers (CSP, X-Frame-Options), cookie flags, CORS, DNS security
**OSINT**: GitHub code search for leaked secrets, breach history, exposed staging envs, Google dorking
**Persistence**: Stored XSS persistence, privilege escalation paths, mass data extraction, session persistence
**Anti-Forensics**: Login logging, rate monitoring, audit log integrity, anomaly alerting, session invalidation

### Output

`white-team-intel.md` — Comprehensive intelligence report
`penetration-test-report.md` — Compliance-ready pentest report

---

## Team CHROME — Browser Attack Lab (The Browser Hackers)

**Mission**: Use real browser automation to prove exploits that require a DOM. XSS, CSRF, clickjacking, DOM manipulation, session attacks.
**Model**: Sonnet

### Operations

| Operation | Tool | What It Does |
|-----------|------|-------------|
| Auth attacks | claude-in-chrome / Playwright | Credential testing, session replay, privilege escalation |
| XSS injection | claude-in-chrome / Playwright | Inject payloads in every input field, check DOM escaping |
| CSRF validation | curl / Playwright | Test token presence, expiry, cross-origin submission |
| Clickjacking | curl / Playwright | Attempt iframe embedding, check X-Frame-Options / CSP |
| DOM manipulation | claude-in-chrome | Modify prices, quantities, hidden fields via devtools |

### Ethical Constraints (MANDATORY)

- Max 10 credential attempts per account
- No destructive actions — prove access, do not damage
- Do not exfiltrate real user data — note its existence only
- Log every browser action for Team WHITE documentation

### Output Format

`chrome-team-browser.md` + `chrome-team-evidence.json`:
```json
{
  "browser_findings": [{
    "id": "CT-001",
    "category": "xss|csrf|clickjacking|dom_manipulation|auth_attack",
    "input_field": "Configurator inscription",
    "payload": "<script>alert('xss')</script>",
    "result": "ESCAPED|REFLECTED|EXECUTED|BLOCKED",
    "severity": "CRITICAL|HIGH|MEDIUM|LOW",
    "cwe": "CWE-XXX",
    "confidence": 0.95,
    "screenshot": "chrome-team-ct001.png",
    "reproduction_steps": ["Step 1...", "Step 2..."]
  }]
}
```

---

## Team CANNON — Load & Stress Testing (The Stress Testers)

**Mission**: Push the infrastructure to its limits. Measure performance under load and verify rate limiting.
**Model**: Sonnet

### Operations

| Operation | Tool | What It Does |
|-----------|------|-------------|
| Endpoint load test | hey / wrk / ab | Sequential load tests per endpoint (warm-up, normal, stress, spike) |
| Rate limit validation | curl (rapid-fire) | Verify rate limiting activates at expected thresholds |
| Payload size testing | curl | Send oversized, deeply nested, and malformed payloads |
| Cold start measurement | curl + timing | Measure first-request latency after idle period |

### Ethical Constraints (MANDATORY)

- Max 30 seconds per load test burst
- Back off immediately on 429 responses
- One endpoint at a time — never simultaneous multi-endpoint load
- Stop immediately if site becomes unresponsive

### Output Format

`cannon-team-load.md` + `cannon-team-metrics.json`:
```json
{
  "load_tests": [{
    "id": "LT-001",
    "endpoint": "/api/initializePayment",
    "method": "POST",
    "test_type": "normal|stress|spike|cold_start",
    "requests_total": 100,
    "concurrency": 10,
    "duration_seconds": 12.5,
    "requests_per_second": 8.0,
    "latency_p50_ms": 120,
    "latency_p95_ms": 450,
    "latency_p99_ms": 890,
    "error_rate_percent": 2.0,
    "status_codes": {"200": 98, "429": 2},
    "rate_limit_triggered_at_request": 15
  }]
}
```

---

## Team FUZZER — API Endpoint Fuzzing (The Mutators)

**Mission**: Send malformed, unexpected, and adversarial input to every API endpoint. Only report findings where the server accepted or mishandled the input.
**Model**: Sonnet

### Operations

| Operation | Tool | What It Does |
|-----------|------|-------------|
| Missing fields | curl / httpie | Remove required fields one at a time |
| Wrong types | curl / httpie | String where number expected, null where object expected |
| Overflow | curl / httpie | 10k char strings, MAX_SAFE_INTEGER, deeply nested JSON |
| Injection | curl / httpie | SQL, NoSQL ($gt, $ne), command injection (;ls;) |
| Encoding | curl / httpie | Unicode, null bytes, UTF-8 BOM, emoji in field names |
| Boundary values | curl / httpie | Zero, negative, minimum, maximum for all numeric fields |
| Path traversal | curl | /../../../etc/passwd on GET endpoints |
| Parameter pollution | curl | Duplicate query params, type juggling |

### Shannon "No Exploit, No Report" Rule

- Expected 400 rejections = POSITIVE findings (defense worked)
- 500 errors = findings (unhandled edge case)
- 200 with malformed data = CRITICAL (validation bypass)
- Only report where the server ACCEPTED or MISHANDLED the input

### Output Format

`fuzzer-team-results.md` + `fuzzer-team-findings.json`:
```json
{
  "fuzz_findings": [{
    "id": "FZ-001",
    "endpoint": "/api/initializePayment",
    "method": "POST",
    "mutation_category": "missing_field|wrong_type|overflow|injection|encoding|negative|boundary",
    "payload_description": "Removed 'amount' field from request body",
    "payload_sample": "{\"email\": \"test@test.com\"}",
    "expected_status": 400,
    "actual_status": 500,
    "response_leaked_info": true,
    "response_sample": "TypeError: Cannot read property 'toFixed' of undefined",
    "severity": "CRITICAL|HIGH|MEDIUM|LOW",
    "cwe": "CWE-XXX",
    "confidence": 0.90,
    "self_reflection": "Confirmed: server returns stack trace on missing amount field"
  }]
}
```

---

## Team COMMERCE — Business Logic Adversary (The Fraud Specialists)

**Mission**: Attack the money-making logic. Test price manipulation, coupon fraud, race conditions, and payment flow integrity.
**Model**: Sonnet

### Operations

| Operation | Tool | What It Does |
|-----------|------|-------------|
| Store-then-Pay attacks | curl / Playwright | Reuse, modify, or fabricate pendingOrderIds |
| Price manipulation | curl + devtools | Intercept and modify payment amounts between client and server |
| Coupon/points fraud | curl | Stack coupons, reuse codes, claim excess points |
| Capacity bypass | curl | Book fully-booked dates, exceed quantity limits |
| Race conditions | parallel curl | Simultaneous payment inits, duplicate webhook callbacks |
| Referral abuse | curl | Self-referral, points without purchase |

### Ethical Constraints (MANDATORY)

- No real payments — use test/sandbox payment endpoints only
- Do not modify real user data — create test data if needed
- Document all attempts including failures (valuable for defense assessment)
- Max 5 concurrent requests for race condition testing

### Output Format

`commerce-team-results.md` + `commerce-team-evidence.json`:
```json
{
  "business_logic_findings": [{
    "id": "BL-001",
    "attack_category": "price_manipulation|coupon_fraud|points_fraud|capacity_bypass|race_condition|referral_abuse|order_duplication",
    "target_flow": "Store-then-Pay",
    "attack_description": "Reused pendingOrderId from completed order",
    "request": "POST /api/initializePayment {pendingOrderId: 'abc123', amount: 100}",
    "response_status": 200,
    "response_body": "{\"authorization_url\": \"...\"}",
    "expected_behavior": "Reject with 400 — pendingOrderId already used",
    "actual_behavior": "Accepted — created duplicate payment for same order",
    "severity": "CRITICAL|HIGH|MEDIUM|LOW",
    "financial_impact": "Potential double-charge or free product",
    "cwe": "CWE-XXX",
    "confidence": 0.95,
    "chain": ["BL-001 -> BL-002"],
    "reproduction_steps": ["Step 1...", "Step 2..."]
  }]
}
```

---

## Team Coordination

```
Team RED scans ---------> red-team-targets.json
                                |
Team BLACK exploits <---- reads targets
                                |
Team CHROME browser <---- reads targets (browser-specific)
                                |
Team CANNON loads ------> cannon-team-metrics.json
                                |
Team FUZZER mutates ----> fuzzer-team-findings.json
                                |
Team COMMERCE business -> commerce-team-evidence.json
                                |
Team WHITE documents <--- observes ALL teams, synthesizes
```

File-based handoff (not agent messaging) keeps it simple and checkpointable.
WHITE starts documenting as soon as RED produces first results.
CHROME, CANNON, FUZZER, and COMMERCE can run in parallel after RED completes.
