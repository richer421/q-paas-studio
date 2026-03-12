#!/opt/homebrew/bin/bash
# test-deploy-cycle.sh — 完整的部署-验证-卸载测试循环

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

NAMESPACE="q-infra"
CYCLE_NUM="${1:-1}"

log_info "=========================================="
log_info "测试循环 #${CYCLE_NUM} 开始"
log_info "=========================================="
echo

# ============================================================
# 阶段 1: 清理环境
# ============================================================
log_step "阶段 1: 清理现有部署"

# 卸载应用服务
for service in gitlab jenkins harbor; do
    log_info "卸载 $service..."
    "$SCRIPT_DIR/deploy.sh" destroy --service "$service" --mode helm 2>/dev/null || true
done

# 卸载中间件
for service in mysql minio redis postgresql; do
    log_info "卸载 $service..."
    "$SCRIPT_DIR/deploy.sh" destroy --service "$service" --mode helm 2>/dev/null || true
done

# 等待 Pod 完全删除
log_info "等待 Pod 完全删除..."
sleep 10

# 清理残留资源
kubectl delete pvc --all -n "$NAMESPACE" 2>/dev/null || true
kubectl delete secret -n "$NAMESPACE" -l heritage=Helm 2>/dev/null || true

log_ok "环境清理完成"
echo

# ============================================================
# 阶段 2: 部署中间件
# ============================================================
log_step "阶段 2: 部署中间件服务"

for service in postgresql redis minio mysql; do
    log_info "部署 $service..."
    "$SCRIPT_DIR/deploy.sh" deploy --service "$service" --mode helm
    echo
done

log_info "等待中间件就绪..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n "$NAMESPACE" --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n "$NAMESPACE" --timeout=300s
kubectl wait --for=condition=ready pod -l app=minio -n "$NAMESPACE" --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mysql -n "$NAMESPACE" --timeout=300s

log_ok "中间件部署完成"
echo

# ============================================================
# 阶段 3: 部署应用服务
# ============================================================
log_step "阶段 3: 部署应用服务"

# GitLab
log_info "部署 GitLab..."
"$SCRIPT_DIR/deploy.sh" deploy --service gitlab --mode helm
echo

# 等待 GitLab 核心组件就绪
log_info "等待 GitLab 就绪..."
kubectl wait --for=condition=ready pod -l app=webservice -n "$NAMESPACE" --timeout=600s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=sidekiq -n "$NAMESPACE" --timeout=600s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=gitlab-runner -n "$NAMESPACE" --timeout=600s 2>/dev/null || true

# Jenkins
log_info "部署 Jenkins..."
"$SCRIPT_DIR/deploy.sh" deploy --service jenkins --mode helm
echo

log_info "等待 Jenkins 就绪..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jenkins -n "$NAMESPACE" --timeout=600s 2>/dev/null || true

# Harbor
log_info "部署 Harbor..."
"$SCRIPT_DIR/deploy.sh" deploy --service harbor --mode helm
echo

log_info "等待 Harbor 就绪..."
kubectl wait --for=condition=ready pod -l component=core -n "$NAMESPACE" --timeout=600s 2>/dev/null || true

log_ok "应用服务部署完成"
echo

# ============================================================
# 阶段 4: 验证部署
# ============================================================
log_step "阶段 4: 验证部署状态"

log_info "所有 Pods 状态:"
kubectl get pods -n "$NAMESPACE" -o wide

echo
log_info "检查失败的 Pods:"
FAILED_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l | xargs)

if [ "$FAILED_PODS" -gt 0 ]; then
    log_error "发现 $FAILED_PODS 个失败的 Pods"
    kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running,status.phase!=Succeeded
    exit 1
fi

log_ok "所有 Pods 运行正常"
echo

# 验证 GitLab Runner
log_info "验证 GitLab Runner..."
RUNNER_STATUS=$(kubectl exec -n "$NAMESPACE" gitlab-toolbox-$(kubectl get pods -n "$NAMESPACE" -l app=toolbox -o jsonpath='{.items[0].metadata.name}') -- gitlab-rails runner 'puts Ci::Runner.first&.status' 2>&1 | grep -v "Defaulted" | tail -1)

if [ "$RUNNER_STATUS" = "online" ]; then
    log_ok "GitLab Runner 状态: online"
else
    log_error "GitLab Runner 状态异常: $RUNNER_STATUS"
    exit 1
fi

echo

# ============================================================
# 阶段 5: 卸载验证
# ============================================================
log_step "阶段 5: 卸载所有服务"

# 卸载应用服务
for service in gitlab jenkins harbor; do
    log_info "卸载 $service..."
    "$SCRIPT_DIR/deploy.sh" destroy --service "$service" --mode helm
done

# 卸载中间件
for service in mysql minio redis postgresql; do
    log_info "卸载 $service..."
    "$SCRIPT_DIR/deploy.sh" destroy --service "$service" --mode helm
done

log_info "等待资源清理..."
sleep 10

# 验证清理
REMAINING_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -v Terminating | wc -l | xargs)
if [ "$REMAINING_PODS" -gt 0 ]; then
    log_error "仍有 $REMAINING_PODS 个 Pods 未清理"
    kubectl get pods -n "$NAMESPACE"
    exit 1
fi

log_ok "所有服务已卸载"
echo

# ============================================================
# 测试结果
# ============================================================
log_ok "=========================================="
log_ok "测试循环 #${CYCLE_NUM} 完成 ✓"
log_ok "=========================================="
echo
