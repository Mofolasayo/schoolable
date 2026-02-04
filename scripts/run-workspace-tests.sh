#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="${SCHOOLABLE_WORKSPACE_ROOT:-$(cd "$ROOT_DIR/.." && pwd)}"

fail=0

run_suite() {
  local name="$1"
  local dir="$2"
  shift 2

  if [ ! -d "$dir" ]; then
    echo "SKIP $name (missing: $dir)"
    return 0
  fi

  echo "==> $name"
  (cd "$dir" && "$@")
  local status=$?
  if [ $status -ne 0 ]; then
    echo "FAILED $name (exit $status)"
    fail=1
  else
    echo "OK $name"
  fi
}

run_suite "schoolable (Flutter)" "$ROOT_DIR" flutter test
run_suite "schoolable_dashboard" "$WORKSPACE_ROOT/schoolable_dashboard" env CI=1 npm test -- --run
run_suite "schoolable_team_lead" "$WORKSPACE_ROOT/schoolable_team_lead" env CI=1 npm test -- --run
run_suite "schoolable_backend" "$WORKSPACE_ROOT/schoolable_backend" ./gradlew test

if [ $fail -ne 0 ]; then
  echo "One or more test suites failed."
  exit 1
fi

echo "All test suites passed."
