#!/usr/bin/env bash
# status.sh — 统一状态检查脚本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 加载环境变量
load_env "$INFRA_ROOT"

# ============================================================
# 服务端口/健康检查配置
# ============================================================
declare -A SERVICE_PORTS=(
    [jenkins]="${JENKINS_PORT:-8090}"
    [harbor]="${HARBOR_PORT:-8880}"
    [gitlab]="${GITLAB_PORT:-8929}"
)

declare -A HEALTH_PATHS=(
    [jenkins]="/login"
    [harbor]="/api/v2.0/health"
    [gitlab]="/-/readiness"
)

# ============================================================
# 状态检查
# ============================================================
check_compose_status() {
    local service="$1"
    require_docker
    require_docker_compose

    local compose_dir="$INFRA_ROOT/compose/$service"
    if [[ ! -f "$compose_dir/docker-compose.yml" ]]; then
        echo "  Compose: not configured"
        return
    fi

    echo "  Containers:"
    $COMPOSE_CMD -f "$compose_dir/docker-compose.yml" ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | sed 's/^/    /' || echo "    (not running)"
}

check_helm_status() {
    local service="$1"
    local namespace="${INFRA_NAMESPACE:-q-infra}"

    if ! command -v helm &>/dev/null; then
        return
    fi

    local release="q-infra-$service"
    local status
    status=$(helm status "$release" -n "$namespace" --output json 2>/dev/null | grep -o '"status":"[^"]*"' | head -1) || true
    if [[ -n "$status" ]]; then
        echo "  Helm release: $release ($status)"
    fi
}

check_health() {
    local service="$1"
    local port="${SERVICE_PORTS[$service]}"
    local path="${HEALTH_PATHS[$service]}"
    local url="http://localhost:${port}${path}"

    if curl -sf -o /dev/null --connect-timeout 3 "$url" 2>/dev/null; then
        log_ok "$service — healthy (${url})"
    else
        log_warn "$service — unreachable (${url})"
    fi
}

# ============================================================
# 入口逻辑
# ============================================================
main() {
    local service="${1:-all}"

    local services
    if [[ "$service" == "all" ]]; then
        services="$ALL_SERVICES"
    else
        validate_service "$service"
        services="$service"
    fi

    echo ""
    log_info "=== Q-PaaS Infrastructure Status ==="
    echo ""

    for svc in $services; do
        echo "[$svc]"
        check_health "$svc"
        check_compose_status "$svc"
        check_helm_status "$svc"
        echo ""
    done
}

main "$@"
