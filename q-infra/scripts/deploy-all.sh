#!/opt/homebrew/bin/bash
# deploy-all.sh — 一键部署所有 q-infra 组件

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info "=== Q-Infra 一键部署 ==="
echo

# 加载环境变量
load_env "$INFRA_ROOT"

# 检测运行环境
MODE="$(detect_runtime)"
if [[ "$MODE" == "kubernetes" ]]; then
    MODE="helm"
else
    MODE="compose"
fi

log_info "Deployment mode: $MODE"
echo

# 部署顺序：先中间件，后应用
MIDDLEWARE_SERVICES="postgresql redis minio mysql kafka"
APP_SERVICES="gitlab jenkins harbor"

# 1. 部署中间件
log_step "Step 1: Deploying middleware services..."
for service in $MIDDLEWARE_SERVICES; do
    log_info "Deploying $service..."
    "$SCRIPT_DIR/deploy.sh" deploy --service "$service" --mode "$MODE"
    echo
done

log_ok "All middleware services deployed!"
echo

# 2. 等待中间件就绪
if [[ "$MODE" == "helm" ]]; then
    log_step "Step 2: Waiting for middleware to be ready..."

    log_info "Waiting for PostgreSQL..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n q-infra --timeout=300s

    log_info "Waiting for Redis..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n q-infra --timeout=300s

    log_info "Waiting for MinIO..."
    kubectl wait --for=condition=ready pod -l app=minio -n q-infra --timeout=300s

    log_info "Waiting for MySQL..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mysql -n q-infra --timeout=300s

    log_info "Waiting for Kafka..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n q-infra --timeout=300s

    log_ok "All middleware services are ready!"
    echo
fi

# 3. 部署应用服务
log_step "Step 3: Deploying application services..."
for service in $APP_SERVICES; do
    log_info "Deploying $service..."
    "$SCRIPT_DIR/deploy.sh" deploy --service "$service" --mode "$MODE"
    echo
done

log_ok "All application services deployed!"
echo

# 4. 显示部署状态
if [[ "$MODE" == "helm" ]]; then
    log_step "Step 4: Deployment Status"
    echo
    kubectl get pods -n q-infra -o wide
    echo

    log_info "Services:"
    kubectl get svc -n q-infra | grep -E "NAME|NodePort"
    echo
fi

# 5. 显示访问信息
log_step "Access Information"
echo

if [[ "$MODE" == "helm" ]]; then
    GITLAB_PORT=$(kubectl get svc -n q-infra gitlab-webservice-default -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    JENKINS_PORT=$(kubectl get svc -n q-infra jenkins -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    HARBOR_PORT=$(kubectl get svc -n q-infra harbor-core -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    KAFKA_PORT=$(kubectl get svc -n q-infra kafka-controller-0-external -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30092")

    echo "GitLab:  http://localhost:${GITLAB_PORT}"
    echo "  - Username: root"
    echo "  - Password: ${GITLAB_ROOT_PASSWORD:-changeme123}"
    echo
    echo "Jenkins: http://localhost:${JENKINS_PORT}"
    echo "  - Username: admin"
    echo "  - Password: changeme"
    echo
    echo "Harbor:  http://localhost:${HARBOR_PORT}"
    echo "  - Username: admin"
    echo "  - Password: Harbor12345"
    echo
    echo "Kafka:   localhost:${KAFKA_PORT}"
    echo
fi

log_ok "=== Deployment completed successfully! ==="
