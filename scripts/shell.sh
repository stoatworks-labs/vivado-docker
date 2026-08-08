#!/usr/bin/env bash
# Drop into an interactive shell in the build container (Vivado on PATH if installed).
set -euo pipefail
cd "$(dirname "$0")/.."
exec docker compose run --rm vivado bash
