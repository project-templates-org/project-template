#!/usr/bin/env bash
# Generic checks that work for any repository. Add the project's own lint/test/build below.
set -euo pipefail

echo "== Validating YAML and JSON files"
python3 - <<'PY'
import json, pathlib, sys
try:
    import yaml
except ImportError:
    yaml = None
bad = 0
for p in pathlib.Path(".").rglob("*"):
    if ".git" in p.parts or not p.is_file():
        continue
    try:
        if p.suffix == ".json":
            json.loads(p.read_text(encoding="utf-8"))
        elif p.suffix in (".yml", ".yaml") and yaml:
            yaml.safe_load(p.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"::error file={p}::{e}")
        bad += 1
sys.exit(1 if bad else 0)
PY

echo "== Checking for merge-conflict markers"
if git grep -nE '^(<<<<<<<|>>>>>>>)( |$)' -- . ':!scripts/ci.sh'; then
  echo "::error::Conflict markers found"; exit 1
fi

# ---- Project-specific checks go here --------------------------------------
# npm ci && npm test
# pytest
# docker build .

echo "CI OK"
