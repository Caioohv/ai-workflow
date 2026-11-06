#!/usr/bin/env bash
# Runs the project's checks and prints a compact result for agents:
# one line per check, plus only the tail of the output of checks that failed.
#
# Usage: workflow/verify.sh [check ...]   (default: lint typecheck test build)
# Env:   VERIFY_TAIL=<n> lines shown per failed check (default 40)
# Exit:  0 when every check that exists passes (or none exist), 1 otherwise.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
tail_lines="${VERIFY_TAIL:-40}"

if [[ ! -f package.json ]]; then
  echo "verify: no package.json; no Node checks to run (use the stack's own checks, output trimmed)"
  exit 0
fi
if ! command -v node >/dev/null 2>&1; then
  echo "verify: node not found; cannot read package.json scripts"
  exit 1
fi

if [[ -f pnpm-lock.yaml ]]; then pm=pnpm
elif [[ -f yarn.lock ]]; then pm=yarn
elif [[ -f bun.lockb || -f bun.lock ]]; then pm=bun
else pm=npm
fi

checks=("$@")
[[ ${#checks[@]} -gt 0 ]] || checks=(lint typecheck test build)

# Resolve each check to a script that exists; skip npm's placeholder test script.
scripts="$(node -e '
  const fs = require("fs");
  const s = JSON.parse(fs.readFileSync("package.json", "utf8")).scripts || {};
  const aliases = { typecheck: ["typecheck", "type-check", "check-types"] };
  for (const check of process.argv.slice(1)) {
    const name = (aliases[check] || [check]).find((n) => s[n]);
    if (!name || (check === "test" && /no test specified/.test(s[name]))) continue;
    console.log(name);
  }
' "${checks[@]}")" || { echo "verify: could not parse package.json"; exit 1; }

if [[ -z "$scripts" ]]; then
  echo "verify: no ${checks[*]} scripts in package.json (no checks yet)"
  exit 0
fi

log="$(mktemp)"
trap 'rm -f "$log"' EXIT
failed=0
while IFS= read -r name; do
  start=$SECONDS
  if CI=1 FORCE_COLOR=0 NO_COLOR=1 "$pm" run "$name" >"$log" 2>&1 </dev/null; then
    echo "ok   $name ($((SECONDS - start))s)"
  else
    failed=1
    echo "FAIL $name ($((SECONDS - start))s), last $tail_lines lines:"
    tail -n "$tail_lines" "$log"
  fi
done <<< "$scripts"
exit "$failed"
