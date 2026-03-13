#!/usr/bin/env bash
# deploy-gitops.sh — 一键部署 GitOps 全流程（Jenkins + Harbor + ArgoCD）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_step "=========================================="
log_step "GitOps 全流程部署"
log_step "=========================================="
log_info "组件: Jenkins + Harbor + ArgoCD"
log_info "中间件: MySQL + Redis + PostgreSQL"
log_step "=========================================="

# 加载环境变量
load_env "$INFRA_ROOT"

# 检查 Kubernetes 集群
require_helm

log_step "Step 1/3: 部署中间件（MySQL + Redis + PostgreSQL）"
for middleware in mysql redis postgresql; do
    log_info "Deploying $middleware..."
    bash "$SCRIPT_DIR/deploy.sh" deploy --service "$middleware" || {
        log_error "Failed to deploy $middleware"
        exit 1
    }
done

log_step "Step 2/3: 部署 DevOps 服务（Jenkins + Harbor + ArgoCD）"
for devops in jenkins harbor argocd; do
    log_info "Deploying $devops..."
    bash "$SCRIPT_DIR/deploy.sh" deploy --service "$devops" || {
        log_error "Failed to deploy $devops"
        exit 1
    }
done

log_step "Step 3/3: 验证部署状态"
sleep 10
kubectl get pods -n q-infra
kubectl get pods -n argocd

log_ok "=========================================="
log_ok "GitOps 全流程部署完成！"
log_ok "=========================================="

log_info "访问方式："
log_info "  Jenkins:  http://localhost:30800"
log_info "  Harbor:   http://localhost:30880"
log_info "  ArgoCD:   http://localhost:30080"
log_info ""
log_info "获取 ArgoCD 初始密码："
log_info "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
log_info ""
log_info "获取 Jenkins 初始密码："
log_info "  kubectl -n q-infra get secret jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
