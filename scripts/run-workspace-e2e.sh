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

run_suite "schoolable (Flutter integration)" "$ROOT_DIR" flutter test integration_test
run_suite "schoolable_dashboard (Playwright)" "$WORKSPACE_ROOT/schoolable_dashboard" env E2E_START=${E2E_START:-0} npm run test:e2e
run_suite "schoolable_team_lead (Playwright)" "$WORKSPACE_ROOT/schoolable_team_lead" env E2E_START=${E2E_START:-0} npm run test:e2e
run_suite "schoolable_backend (Spring Boot E2E)" "$WORKSPACE_ROOT/schoolable_backend" ./gradlew test --tests com.schoolable.backend.e2e.*

if [ $fail -ne 0 ]; then
  echo "One or more E2E suites failed."
  exit 1
fi

echo "All E2E suites passed."
