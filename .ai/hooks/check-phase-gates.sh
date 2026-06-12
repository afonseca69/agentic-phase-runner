#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${APR_ROOT_DIR:-$(pwd)}"
BLUEPRINT="${APR_BLUEPRINT:-$ROOT_DIR/.ai/project-blueprint.yaml}"
PHASE="${1:-}"

if [[ -z "$PHASE" ]]; then
  echo "usage: check-phase-gates.sh PHASE_ID" >&2
  exit 64
fi

if [[ ! -f "$BLUEPRINT" ]]; then
  echo "check-phase-gates: blueprint not found: $BLUEPRINT" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  python3 - "$BLUEPRINT" "$PHASE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
phase = sys.argv[2]
text = path.read_text()

m = re.search(r"(?ms)^\s*-\s+id:\s*['\"]?" + re.escape(phase) + r"['\"]?.*?(?=^\s*-\s+id:|\Z)", text)
if not m:
    print(f"check-phase-gates: phase {phase} not found")
    sys.exit(1)
block = m.group(0)
if "gates:" not in block:
    print(f"check-phase-gates: {phase} has no gates")
    sys.exit(0)
print(f"check-phase-gates: {phase} declares gates; review before running")
for line in block.splitlines():
    if "gates:" in line or re.match(r"^\s*-\s+[a-zA-Z0-9_-]+\s*$", line):
        print(line)
sys.exit(2)
PY
else
  if grep -A20 -E "^[[:space:]]*-[[:space:]]*id:[[:space:]]*$PHASE" "$BLUEPRINT" | grep -q "gates:"; then
    echo "check-phase-gates: $PHASE declares gates; review before running" >&2
    exit 2
  fi
  echo "check-phase-gates: no gates detected"
fi
