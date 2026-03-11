#!/usr/bin/env bash
# status.sh — 快捷状态检查（委托给 deploy.sh status）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/deploy.sh" status "$@"
