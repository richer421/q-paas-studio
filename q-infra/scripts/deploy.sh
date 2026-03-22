#!/usr/bin/env bash
# deploy.sh — Helm 部署脚本（仅支持 Kubernetes/Helm 模式）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================
# Helm chart 配置
# ============================================================
# DevOps 服务使用远程仓库
declare -A HELM_REPOS=(
    [jenkins]="https://charts.jenkins.io"
    [harbor]="https://helm.goharbor.io"
    [argocd]="https://argoproj.github.io/argo-helm"
)

# 中间件服务使用本地 chart 目录
MIDDLEWARE_SERVICES="mysql redis postgresql minio kafka"

# ============================================================
# Helm 部署
# ============================================================
helm_deploy() {
    local service="$1"
    local namespace="${INFRA_NAMESPACE:-q-infra}"
    require_helm

    # ArgoCD 使用独立的 namespace
    if [[ "$service" == "argocd" ]]; then
        namespace="argocd"
    fi

    local chart_dir="$INFRA_ROOT/helm/$service"
    local values_file="$chart_dir/values-overrides.yaml"

    # 中间件服务使用本地 chart 目录
    if echo "$MIDDLEWARE_SERVICES" | grep -qw "$service"; then
        if [[ ! -d "$chart_dir" ]]; then
            log_error "Chart directory not found: $chart_dir"
            return 1
        fi
        log_step "Deploying $service from local chart..."
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
        helm dependency update "$chart_dir" 2>/dev/null || true
        helm upgrade --install "$service" "$chart_dir" \
            ${values_file:+-f "$values_file"} \
            -n "$namespace" \
            --timeout 5m
    else
        # DevOps 服务使用本地 chart 目录 + 远程依赖
        if [[ ! -d "$chart_dir" ]]; then
            log_error "Chart directory not found: $chart_dir"
            return 1
        fi

        # 添加必要的 Helm repo
        local repo_name="${service}"
        local repo_url="${HELM_REPOS[$service]}"

        log_step "Adding Helm repo: $repo_name -> $repo_url"
        helm repo add "$repo_name" "$repo_url" --force-update 2>/dev/null || true
        helm repo update

        log_step "Deploying $service from local chart..."
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
        helm dependency update "$chart_dir" 2>/dev/null || true
        helm_prepare "$service" "$namespace"

        helm upgrade --install "$service" "$chart_dir" \
            ${values_file:+-f "$values_file"} \
            -n "$namespace" \
            --timeout 15m
    fi

    log_ok "$service deployed to namespace $namespace"
}

helm_destroy() {
    local service="$1"
    local namespace="${INFRA_NAMESPACE:-q-infra}"
    require_helm

    log_step "Destroying $service via Helm..."
    helm uninstall "$service" -n "$namespace" 2>/dev/null || true
    log_ok "$service destroyed from namespace $namespace"
}

# ============================================================
# 部署前准备（创建 Secrets、数据库初始化等）
# ============================================================
helm_prepare() {
    local service="$1"
    local namespace="${2:-${INFRA_NAMESPACE:-q-infra}}"

    case "$service" in
        argocd)
            log_step "ArgoCD will be deployed to namespace: $namespace"
            ;;
        harbor)
            # Harbor 需要在 PostgreSQL 中创建专用数据库
            log_step "Preparing Harbor databases in PostgreSQL..."

            # 等待 PostgreSQL 就绪
            kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n q-infra --timeout=60s 2>/dev/null || true

            # 创建 Harbor 所需的数据库（如果不存在）
            for db in harbor_core harbor_notary_server harbor_notary_signer; do
                kubectl exec -n q-infra postgresql-0 -- psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1 || \
                kubectl exec -n q-infra postgresql-0 -- psql -U postgres -c "CREATE DATABASE $db;" 2>/dev/null || true
            done

            log_ok "Harbor databases prepared"
            ;;
    esac
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
  status    Show infrastructure service status

Options:
  --service <name>   Target service: gitlab|jenkins|harbor|argocd|mysql|redis|postgresql|minio|kafka|all

Examples:
  $(basename "$0") deploy --service mysql
  $(basename "$0") deploy --service redis
  $(basename "$0") deploy --service kafka
  $(basename "$0") destroy --service harbor
  $(basename "$0") status --service all
  $(basename "$0") deploy --service all
EOF
    exit 1
}

show_status() {
    local service="$1"
    require_helm

    if [[ "$service" == "all" ]]; then
        log_step "Namespace q-infra"
        kubectl get pods -n q-infra
        echo
        kubectl get svc -n q-infra
        echo
        log_step "Namespace argocd"
        kubectl get pods -n argocd 2>/dev/null || true
        echo
        kubectl get svc -n argocd 2>/dev/null || true
        return 0
    fi

    local namespace="${INFRA_NAMESPACE:-q-infra}"
    if [[ "$service" == "argocd" ]]; then
        namespace="argocd"
    fi

    log_step "Helm release status: $service ($namespace)"
    helm status "$service" -n "$namespace" || true
    echo
    kubectl get pods -n "$namespace" | grep -E "^NAME|$service" || true
}

main() {
    local action="${1:-}"
    shift || true

    local service="all"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --service) service="$2"; shift 2 ;;
            *)         log_error "Unknown option: $1"; usage ;;
        esac
    done

    [[ -z "$action" ]] && usage

    # 加载环境变量
    load_env "$INFRA_ROOT"

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
                helm_deploy "$svc"
                ;;
            destroy)
                helm_destroy "$svc"
                ;;
            status)
                show_status "$svc"
                ;;
            *)
                log_error "Unknown action: $action"
                usage
                ;;
        esac
    done
}

main "$@"
