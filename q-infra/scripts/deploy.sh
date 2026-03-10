#!/usr/bin/env bash
# deploy.sh — 通用部署脚本（检测环境、调度安装/卸载）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================
# Helm chart 仓库映射
# ============================================================
declare -A HELM_REPOS=(
    [jenkins]="https://charts.jenkins.io"
    [harbor]="https://helm.goharbor.io"
    [gitlab]="https://charts.gitlab.io"
)

declare -A HELM_CHARTS=(
    [jenkins]="jenkins/jenkins"
    [harbor]="harbor/harbor"
    [gitlab]="gitlab/gitlab"
)

# ============================================================
# 健康检查 URL 映射
# ============================================================
declare -A HEALTH_URLS=(
    [jenkins]="http://localhost:${JENKINS_PORT:-8090}/login"
    [harbor]="http://localhost:${HARBOR_PORT:-8880}/api/v2.0/health"
    [gitlab]="http://localhost:${GITLAB_PORT:-8929}/-/readiness"
)

# ============================================================
# Docker Compose 部署
# ============================================================
compose_deploy() {
    local service="$1"
    require_docker
    require_docker_compose

    local compose_dir="$INFRA_ROOT/compose/$service"
    if [[ ! -f "$compose_dir/docker-compose.yml" ]]; then
        log_error "Compose file not found: $compose_dir/docker-compose.yml"
        return 1
    fi

    log_step "Deploying $service via Docker Compose..."
    $COMPOSE_CMD -f "$compose_dir/docker-compose.yml" --env-file "$INFRA_ROOT/.env" up -d

    log_info "Waiting for $service to become healthy..."
    wait_for_url "${HEALTH_URLS[$service]}" 180 || true
    log_ok "$service deployed successfully"
}

compose_destroy() {
    local service="$1"
    require_docker
    require_docker_compose

    local compose_dir="$INFRA_ROOT/compose/$service"
    if [[ ! -f "$compose_dir/docker-compose.yml" ]]; then
        log_error "Compose file not found: $compose_dir/docker-compose.yml"
        return 1
    fi

    log_step "Destroying $service via Docker Compose..."
    $COMPOSE_CMD -f "$compose_dir/docker-compose.yml" --env-file "$INFRA_ROOT/.env" down -v
    log_ok "$service destroyed"
}

# ============================================================
# Helm 部署
# ============================================================
helm_deploy() {
    local service="$1"
    local namespace="${INFRA_NAMESPACE:-q-infra}"
    require_helm

    local values_file="$INFRA_ROOT/helm/$service/values.yaml"
    if [[ ! -f "$values_file" ]]; then
        log_error "Helm values not found: $values_file"
        return 1
    fi

    local repo_name="${service}"
    local repo_url="${HELM_REPOS[$service]}"
    local chart="${HELM_CHARTS[$service]}"

    log_step "Adding Helm repo: $repo_name -> $repo_url"
    helm repo add "$repo_name" "$repo_url" --force-update
    helm repo update

    log_step "Deploying $service via Helm..."
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    helm upgrade --install "q-infra-$service" "$chart" \
        -f "$values_file" \
        -n "$namespace" \
        --wait \
        --timeout 10m

    log_ok "$service deployed to namespace $namespace"
}

helm_destroy() {
    local service="$1"
    local namespace="${INFRA_NAMESPACE:-q-infra}"
    require_helm

    log_step "Destroying $service via Helm..."
    helm uninstall "q-infra-$service" -n "$namespace" 2>/dev/null || true
    log_ok "$service destroyed from namespace $namespace"
}

# ============================================================
# 入口逻辑
# ============================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") <action> [options]

Actions:
  deploy    Deploy infrastructure service(s)
  destroy   Destroy infrastructure service(s)

Options:
  --service <name>   Target service: jenkins | harbor | gitlab | all (default: all)
  --mode <mode>      Deploy mode: auto | compose | helm (default: auto)

Examples:
  $(basename "$0") deploy --service jenkins
  $(basename "$0") deploy --service all --mode compose
  $(basename "$0") destroy --service harbor
EOF
    exit 1
}

main() {
    local action="${1:-}"
    shift || true

    local service="all"
    local mode="${DEPLOY_MODE:-auto}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --service) service="$2"; shift 2 ;;
            --mode)    mode="$2";    shift 2 ;;
            *)         log_error "Unknown option: $1"; usage ;;
        esac
    done

    [[ -z "$action" ]] && usage

    # 加载环境变量
    load_env "$INFRA_ROOT"

    # 确定部署模式
    if [[ "$mode" == "auto" ]]; then
        mode="$(detect_runtime)"
        if [[ "$mode" == "kubernetes" ]]; then
            mode="helm"
        else
            mode="compose"
        fi
        log_info "Auto-detected mode: $mode"
    fi

    # 确定服务列表
    local services
    if [[ "$service" == "all" ]]; then
        services="$ALL_SERVICES"
    else
        validate_service "$service"
        services="$service"
    fi

    # 执行操作
    for svc in $services; do
        case "$action" in
            deploy)
                case "$mode" in
                    compose) compose_deploy "$svc" ;;
                    helm)    helm_deploy "$svc" ;;
                    *)       log_error "Unknown mode: $mode"; exit 1 ;;
                esac
                ;;
            destroy)
                case "$mode" in
                    compose) compose_destroy "$svc" ;;
                    helm)    helm_destroy "$svc" ;;
                    *)       log_error "Unknown mode: $mode"; exit 1 ;;
                esac
                ;;
            *)
                log_error "Unknown action: $action"
                usage
                ;;
        esac
    done
}

main "$@"
