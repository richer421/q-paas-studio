#!/opt/homebrew/bin/bash
# utils.sh — 公共函数：日志输出、颜色、环境检测、等待就绪

set -euo pipefail

# ============================================================
# 颜色定义
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================
# 日志函数
# ============================================================
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step()  { echo -e "${CYAN}[STEP]${NC}  $*"; }

# ============================================================
# 已知服务列表
# ============================================================
# DevOps 服务
DEVOPS_SERVICES="jenkins harbor argocd"
# 中间件服务
MIDDLEWARE_SERVICES="mysql redis postgresql minio"
# 全部服务
ALL_SERVICES="$DEVOPS_SERVICES $MIDDLEWARE_SERVICES"

# 中间件服务标志
is_middleware() {
    local service="$1"
    echo "$MIDDLEWARE_SERVICES" | grep -qw "$service"
}

validate_service() {
    local service="$1"
    for s in $ALL_SERVICES; do
        [[ "$s" == "$service" ]] && return 0
    done
    log_error "Unknown service: $service (available: $ALL_SERVICES)"
    return 1
}

# ============================================================
# 环境检测
# ============================================================
detect_runtime() {
    # 返回 "kubernetes" 或 "docker"
    if command -v kubectl &>/dev/null && kubectl cluster-info &>/dev/null 2>&1; then
        echo "kubernetes"
    elif command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        echo "docker"
    else
        log_error "Neither Kubernetes nor Docker detected"
        return 1
    fi
}

require_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "docker is not installed"
        return 1
    fi
    if ! docker info &>/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        return 1
    fi
}

require_docker_compose() {
    if docker compose version &>/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        log_error "docker compose is not available"
        return 1
    fi
    export COMPOSE_CMD
}

require_helm() {
    if ! command -v helm &>/dev/null; then
        log_error "helm is not installed"
        return 1
    fi
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl is not installed"
        return 1
    fi
}

# ============================================================
# 等待 HTTP 端点就绪
# ============================================================
wait_for_url() {
    local url="$1"
    local timeout="${2:-120}"
    local interval="${3:-5}"
    local elapsed=0

    log_info "Waiting for $url (timeout: ${timeout}s)..."
    while (( elapsed < timeout )); do
        if curl -sf -o /dev/null "$url" 2>/dev/null; then
            log_ok "$url is ready"
            return 0
        fi
        sleep "$interval"
        elapsed=$(( elapsed + interval ))
    done
    log_warn "$url not ready after ${timeout}s"
    return 1
}

# ============================================================
# 路径工具
# ============================================================
# 获取 q-infra 根目录（脚本所在目录的上一级）
get_infra_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    echo "$(cd "$script_dir/.." && pwd)"
}

# 加载 .env 文件
load_env() {
    local infra_root="$1"
    local env_file="${infra_root}/.env"
    if [[ -f "$env_file" ]]; then
        log_info "Loading environment from $env_file"
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
    else
        log_warn "No .env file found at $env_file — using defaults"
    fi
}
