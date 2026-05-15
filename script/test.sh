#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"
swift build
"$(swift build --show-bin-path)/Punaise" --self-test

cd "$ROOT_DIR/landing"
npm run lint
npm run build
