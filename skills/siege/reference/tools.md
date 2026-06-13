# Siege — Tool Chain Reference

## Static Analysis Tools (`--install-tools`)

### Semgrep — SAST
```bash
# Install
pip install semgrep        # pip
brew install semgrep       # macOS
# Run
semgrep scan --config auto --json -o .siege/.tool-semgrep.json .
# Catches: SQLi, XSS, command injection, path traversal, insecure deserialization
```

### knip — Dead Code
```bash
# Zero-install
npx knip --reporter json > .siege/.tool-knip.json
# Catches: Unused deps, exports, files, types
```

### npm audit — Dependency Vulns
```bash
npm audit --json > .siege/.tool-npm-audit.json
# Catches: Known CVEs in dependency tree
```

### eslint-plugin-security — Security Lint
```bash
npm i -D eslint-plugin-security
# Catches: eval(), child_process.exec, non-literal regex, timing attacks
```

### ts-prune — Unused TS Exports
```bash
npx ts-prune > .siege/.tool-ts-prune.txt
# Catches: Exported but never imported functions/types
```

### TruffleHog — Secret Scanning
```bash
brew install trufflehog    # macOS
trufflehog filesystem --json . > .siege/.tool-trufflehog.json
# Catches: API keys, tokens, passwords (800+ service detectors)
```

### gitleaks — Git History Secrets
```bash
brew install gitleaks
gitleaks detect --report-format json --report-path .siege/.tool-gitleaks.json
# Catches: Secrets in git history (even deleted ones)
```

### tsc --strict — TypeScript Strict
```bash
npx tsc --strict --noEmit 2> .siege/.tool-tsc-strict.txt
# Catches: Implicit any, null safety, unused locals
```

---

## Offensive Tools (`--install-offensive`)

### Team RED — Reconnaissance

| Tool | Install | Run |
|------|---------|-----|
| nmap | `brew install nmap` | `nmap -sV -sC -O <target> -oX .siege/.tool-nmap.xml` |
| subfinder | `brew install subfinder` | `subfinder -d <domain> -o .siege/.tool-subfinder.txt` |
| httpx | `brew install httpx` | `httpx -u <target> -json -o .siege/.tool-httpx.json -tech-detect` |
| katana | `brew install katana` | `katana -u <target> -json -o .siege/.tool-katana.json` |
| ffuf | `brew install ffuf` | `ffuf -u <target>/FUZZ -w wordlist.txt -o .siege/.tool-ffuf.json -of json` |
| nikto | `brew install nikto` | `nikto -h <target> -output .siege/.tool-nikto.json -Format json` |
| nuclei | `brew install nuclei` | `nuclei -u <target> -json -o .siege/.tool-nuclei.json` |

### Team BLACK — Exploitation

| Tool | Install | Purpose |
|------|---------|---------|
| OWASP ZAP | `brew install zaproxy` | Full web app scanner (XSS, SQLi, CSRF, OWASP Top 10) |
| sqlmap | `brew install sqlmap` | SQL injection in params, headers, cookies |
| dalfox | `brew install dalfox` | Reflected/stored/DOM XSS with proof payloads |
| commix | `pip install commix` | OS command injection |
| jwt_tool | `pip install jwt-tool` | JWT confusion, brute-force, claim tampering |
| hydra | `brew install hydra` | Auth brute-force (max 10 attempts — ethical) |
| Playwright | Already installed | Browser-based exploitation |

### Team WHITE — Intelligence

| Tool | Install | Purpose |
|------|---------|---------|
| trivy | `brew install trivy` | Container/filesystem vuln scan |
| testssl.sh | `brew install testssl` | TLS/SSL audit (ciphers, certs, HSTS) |

---

## Tool Availability Check (Phase 1)

```bash
# Static tools
for tool in semgrep trufflehog gitleaks; do
  which $tool > /dev/null 2>&1 && echo "$tool: available" || echo "$tool: MISSING"
done
npx knip --help > /dev/null 2>&1 && echo "knip: available" || echo "knip: MISSING"

# Offensive tools (only if --live)
for tool in nmap nuclei sqlmap zaproxy hydra ffuf katana httpx; do
  which $tool > /dev/null 2>&1 && echo "$tool: available" || echo "$tool: MISSING"
done
```

## Fallback Strategy

If a tool is unavailable and cannot be installed:
- **semgrep missing**: AI agents do manual SAST via Grep pattern matching
- **knip missing**: AI agents check imports vs package.json manually
- **trufflehog/gitleaks missing**: AI agents grep for secret patterns
- **Offensive tools missing**: AI agents use curl/httpie + Playwright MCP for browser testing

### Additional Recon Tools (Shannon Heritage)

| Tool | Install | Purpose |
|------|---------|---------|
| whatweb | `brew install whatweb` | Web technology fingerprint (CMS, frameworks, plugins) |
| schemathesis | `pip install schemathesis` | OpenAPI/Swagger schema-driven API fuzz testing |

### Extended Recon & Exploitation Tools

| Tool | Install | Team | Purpose |
|------|---------|------|---------|
| amass | `brew install amass` | RED | Advanced subdomain enumeration + DNS intel |
| gobuster | `brew install gobuster` | RED | Directory/DNS/vhost brute-force |
| arjun | `pip install arjun` | RED | Hidden HTTP parameter discovery |
| dirsearch | `pip install dirsearch` | RED | Web path discovery scanner |
| feroxbuster | `brew install feroxbuster` | RED | Fast recursive content discovery (Rust) |
| sslyze | `pip install sslyze` | WHITE | Deep TLS/SSL analysis |
| retire.js | `npm i -g retire` | WHITE | Known JS library vulnerabilities |
| snyk | `npm i -g snyk` | WHITE | Dependency + container vulns |
| dnsrecon | `pip install dnsrecon` | RED | DNS enumeration + zone transfer |
| wafw00f | `pip install wafw00f` | RED | WAF detection + fingerprint |
| xsstrike | `pip install xsstrike` | BLACK | Advanced XSS detection + fuzzing |

<!-- Removed tools:
  - wfuzz: broken pip metadata on modern Python, ffuf covers same functionality
  - paramspider: not on pip, arjun covers same functionality
  - crlfuzz: not in homebrew, dalfox checks for CRLF
  - nosqlmap: targets MongoDB/CouchDB, we use Firestore
  - restler-fuzzer: requires .NET runtime, schemathesis covers same functionality
-->

---

## V2 Teams — Additional Tools

### Team CANNON — Load & Stress Testing

| Tool | Install | Purpose |
|------|---------|---------|
| hey | `brew install hey` | HTTP load generator (preferred — Go, simple) |
| wrk | `brew install wrk` | Multi-threaded HTTP benchmark |
| k6 | `brew install k6` | Scriptable load testing (Grafana) |
| vegeta | `brew install vegeta` | Constant-rate HTTP attack |
| ab | Pre-installed (Apache Bench) | Basic concurrent request testing |
| slowloris | `pip install slowloris` | Slow HTTP DoS resistance testing |

### Team FUZZER — API Endpoint Fuzzing

| Tool | Install | Purpose |
|------|---------|---------|
| schemathesis | `pip install schemathesis` | OpenAPI schema-driven fuzz (also in recon) |
| restler | `pip install restler-fuzzer` | Stateful REST API fuzzer (Microsoft) |
| boofuzz | `pip install boofuzz` | Protocol-level network fuzzer |
| radamsa | `brew install radamsa` | General-purpose mutation fuzzer |
| jwt_tool | `pip install jwt-tool` | JWT claim tampering + algo confusion (also in BLACK) |

### Team CHROME — Browser Attack Lab

| Tool | Install | Purpose |
|------|---------|---------|
| claude-in-chrome | MCP (pre-installed) | Real browser automation — DOM manipulation, XSS injection |
| playwright | MCP (pre-installed) | Headless browser testing — parallel, faster |
| xsstrike | `pip install xsstrike` | Advanced XSS payload generation (feed to browser) |

### Team COMMERCE — Business Logic (No tools — pure reasoning)

Commerce team uses curl + Claude reasoning. No specialized tools needed — business logic
attacks are about understanding the application's rules and finding ways to break them.

---

## HexStrike AI Integration (`--install-hexstrike`)

HexStrike provides 150+ security tools as MCP functions. When installed, Siege agents
can call tools directly instead of shelling out to CLI.

```bash
# Install HexStrike
git clone https://github.com/0x4m4/hexstrike-ai.git ~/hexstrike-ai
cd ~/hexstrike-ai
python3 -m venv hexstrike-env
source hexstrike-env/bin/activate
pip3 install -r requirements.txt

# Add to Claude Code
claude mcp add hexstrike-ai -- ~/hexstrike-ai/hexstrike-env/bin/python3 ~/hexstrike-ai/hexstrike_mcp.py
```

When HexStrike is available, Siege agents use `mcp__hexstrike-ai__*` tool calls
instead of Bash commands. This is faster, more reliable, and provides structured
JSON output automatically.

### HexStrike Tool Categories Available
- **Scanning**: nmap, masscan, naabu, nuclei, nikto
- **Web Testing**: sqlmap, xsstrike, dalfox, commix, ssrf-scanner
- **Recon**: subfinder, httpx, katana, amass, gobuster, ffuf
- **Exploitation**: metasploit, searchsploit, jwt_tool
- **Intelligence**: testssl, sslyze, wafw00f, whatweb
- **OSINT**: theHarvester, sherlock, dnsrecon
- **Fuzzing**: wfuzz, feroxbuster, arjun, paramspider

### Fallback: No HexStrike

If HexStrike is not installed, Siege falls back to:
1. Direct CLI tools (if installed via `--install-offensive`)
2. curl-based manual probing
3. AI reasoning with Grep/Read tools (static analysis only)
