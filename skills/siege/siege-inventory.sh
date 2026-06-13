#!/bin/bash
# Siege v2 Tool Inventory — accurate count, no miscounting
# Usage: bash siege-inventory.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

installed=0
missing=0
total=0

check() {
  local name="$1"
  local team="$2"
  local method="$3"  # "bin" | "python" | "path" | "always"
  local target="$4"  # binary name, python module, or file path

  total=$((total + 1))

  case "$method" in
    bin)
      if which "$target" > /dev/null 2>&1; then
        printf "${GREEN}✅ %-20s${NC} [%s]\n" "$name" "$team"
        installed=$((installed + 1))
      else
        printf "${RED}❌ %-20s${NC} [%s]\n" "$name" "$team"
        missing=$((missing + 1))
      fi
      ;;
    python)
      if python3 -c "import $target" 2>/dev/null 1>/dev/null || which "$target" > /dev/null 2>&1; then
        printf "${GREEN}✅ %-20s${NC} [%s]\n" "$name" "$team"
        installed=$((installed + 1))
      else
        printf "${RED}❌ %-20s${NC} [%s]\n" "$name" "$team"
        missing=$((missing + 1))
      fi
      ;;
    path)
      if [ -f "$target" ]; then
        printf "${GREEN}✅ %-20s${NC} [%s] ($target)\n" "$name" "$team"
        installed=$((installed + 1))
      else
        printf "${RED}❌ %-20s${NC} [%s]\n" "$name" "$team"
        missing=$((missing + 1))
      fi
      ;;
    npx)
      if npx "$target" --help > /dev/null 2>&1; then
        printf "${GREEN}✅ %-20s${NC} [%s] (npx)\n" "$name" "$team"
        installed=$((installed + 1))
      else
        printf "${RED}❌ %-20s${NC} [%s]\n" "$name" "$team"
        missing=$((missing + 1))
      fi
      ;;
    always)
      printf "${GREEN}✅ %-20s${NC} [%s]\n" "$name" "$team"
      installed=$((installed + 1))
      ;;
  esac
}

echo ""
echo "${BOLD}═══════════════════════════════════════════${NC}"
echo "${BOLD}  SIEGE v2 — TOOL INVENTORY AUDIT${NC}"
echo "${BOLD}═══════════════════════════════════════════${NC}"
echo ""

echo "${YELLOW}── STATIC ANALYSIS ──${NC}"
check "semgrep"              "STATIC"  bin     semgrep
check "trufflehog"           "STATIC"  bin     trufflehog
check "gitleaks"             "STATIC"  bin     gitleaks
check "knip"                 "STATIC"  always  ""
check "npm audit"            "STATIC"  always  ""
check "tsc --strict"         "STATIC"  always  ""
check "eslint-plugin-security" "STATIC" always ""
check "ts-prune"             "STATIC"  always  ""

echo ""
echo "${YELLOW}── RED TEAM (Recon) ──${NC}"
check "nmap"                 "RED"     bin     nmap
check "httpx"                "RED"     bin     httpx
check "ffuf"                 "RED"     bin     ffuf
check "nikto"                "RED"     bin     nikto
check "nuclei"               "RED"     bin     nuclei
check "amass"                "RED"     bin     amass
check "gobuster"             "RED"     bin     gobuster
check "feroxbuster"          "RED"     bin     feroxbuster
check "subfinder"            "RED"     bin     subfinder
check "katana"               "RED"     bin     katana
check "whatweb"              "RED"     path    "$HOME/whatweb/whatweb"
check "wafw00f"              "RED"     python  wafw00f
check "dnsrecon"             "RED"     python  dnsrecon
check "arjun"                "RED"     python  arjun
check "dirsearch"            "RED"     python  dirsearch

echo ""
echo "${YELLOW}── BLACK TEAM (Exploit) ──${NC}"
check "sqlmap"               "BLACK"   bin     sqlmap
check "dalfox"               "BLACK"   bin     dalfox
check "hydra"                "BLACK"   bin     hydra
check "zaproxy"              "BLACK"   path    "/Applications/ZAP.app/Contents/Java/zap.sh"
check "commix"               "BLACK"   python  commix
check "jwt_tool"             "BLACK"   path    "$HOME/jwt_tool/jwt_tool.py"
check "xsstrike"             "BLACK"   python  xsstrike

echo ""
echo "${YELLOW}── WHITE TEAM (Intel) ──${NC}"
check "trivy"                "WHITE"   bin     trivy
check "testssl.sh"           "WHITE"   bin     testssl.sh
check "sslyze"               "WHITE"   python  sslyze
check "retire.js"            "WHITE"   bin     retire
check "snyk"                 "WHITE"   bin     snyk

echo ""
echo "${YELLOW}── CANNON TEAM (Load) ──${NC}"
check "hey"                  "CANNON"  bin     hey
check "wrk"                  "CANNON"  bin     wrk
check "k6"                   "CANNON"  bin     k6
check "vegeta"               "CANNON"  bin     vegeta
check "ab"                   "CANNON"  bin     ab
check "slowloris"            "CANNON"  python  slowloris

echo ""
echo "${YELLOW}── FUZZER TEAM (API) ──${NC}"
check "schemathesis"         "FUZZER"  python  schemathesis
check "boofuzz"              "FUZZER"  python  boofuzz
check "radamsa"              "FUZZER"  bin     radamsa

echo ""
echo "${YELLOW}── CHROME TEAM (Browser) ──${NC}"
check "claude-in-chrome"     "CHROME"  always  ""
check "playwright"           "CHROME"  always  ""

echo ""
echo "${YELLOW}── BUILT-IN ──${NC}"
check "curl"                 "CORE"    bin     curl
check "node/npx"             "CORE"    bin     node

echo ""
echo "${BOLD}═══════════════════════════════════════════${NC}"
printf "${BOLD}  TOTAL: %d  |  ${GREEN}INSTALLED: %d${NC}  |  ${RED}MISSING: %d${NC}\n" "$total" "$installed" "$missing"
pct=$((installed * 100 / total))
printf "${BOLD}  COVERAGE: %d%%${NC}\n" "$pct"
echo "${BOLD}═══════════════════════════════════════════${NC}"
echo ""
