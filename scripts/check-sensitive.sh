#!/usr/bin/env bash
# Scan tracked and staged files for things that shouldn't be published.
# Personal terms (real domains, names, SSIDs) go in .sensitive-patterns,
# one extended regex per line. That file is gitignored.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2

files=$(git ls-files -co --exclude-standard | grep -v -e '^scripts/check-sensitive.sh$' -e '^\.sensitive-patterns$')
[ -z "$files" ] && { echo "No files to scan."; exit 0; }

hits=0
check() {
  local label=$1 pattern=$2 allow=${3:-}
  local out
  out=$(echo "$files" | xargs grep -nEi -- "$pattern" 2>/dev/null)
  if [ -n "$allow" ] && [ -n "$out" ]; then
    out=$(echo "$out" | grep -Ev -- "$allow")
  fi
  if [ -n "$out" ]; then
    echo "== $label"
    echo "$out"
    echo
    hits=1
  fi
}

check "Real-looking private IPs (docs use 10.10.x.x)" '\b192\.168\.(1|100)\.[0-9]{1,3}\b'
check "Tailscale CGNAT addresses" '\b100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+\b' \
  '100\.100\.100\.100|100\.64\.0\.0/10'
check "Tailnet names" '\.ts\.net\b'
check "MAC addresses" '\b([0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b'
check "Email addresses" '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'
check "UUIDs (tunnel IDs, account IDs)" '\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
check "Secrets" '(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*\S+|BEGIN [A-Z ]*PRIVATE KEY'

if [ -f .sensitive-patterns ]; then
  while IFS= read -r p; do
    [ -z "$p" ] || [ "${p#\#}" != "$p" ] && continue
    check "Personal term: $p" "$p"
  done < .sensitive-patterns
fi

if [ $hits -eq 0 ]; then echo "Clean."; else echo "Review the matches above before pushing."; exit 1; fi
