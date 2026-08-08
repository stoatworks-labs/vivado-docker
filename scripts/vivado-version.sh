#!/usr/bin/env bash
# Sanity check: is Vivado installed and runnable in the container?
set -euo pipefail
cd "$(dirname "$0")/.."
exec docker compose run --rm vivado vivado -version
