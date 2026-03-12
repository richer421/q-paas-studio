#!/opt/homebrew/bin/bash
# prepare-gitlab.sh — GitLab 部署前准备脚本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

NAMESPACE="${INFRA_NAMESPACE:-q-infra}"

log_step "Preparing GitLab deployment..."

# 1. 确保 PostgreSQL 就绪
log_info "Checking PostgreSQL..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres -n "$NAMESPACE" --timeout=300s

# 2. 确保 Redis 就绪
log_info "Checking Redis..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n "$NAMESPACE" --timeout=300s

# 3. 确保 MinIO 就绪
log_info "Checking MinIO..."
kubectl wait --for=condition=ready pod -l app=minio -n "$NAMESPACE" --timeout=300s

# 4. 创建 GitLab 数据库
log_info "Creating GitLab database..."
kubectl exec -n "$NAMESPACE" postgresql-0 -- psql -U postgres -c "CREATE DATABASE IF NOT EXISTS gitlabhq_production;" 2>/dev/null || \
kubectl exec -n "$NAMESPACE" postgresql-0 -- psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='gitlabhq_production';" | grep -q 1 || \
kubectl exec -n "$NAMESPACE" postgresql-0 -- psql -U postgres -c "CREATE DATABASE gitlabhq_production;"

log_ok "GitLab database ready"

# 5. 创建 gitlab 命名空间（用于 Redis 别名）
log_info "Creating gitlab namespace for service aliases..."
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# 6. 创建 Redis Service 别名
log_info "Creating Redis service alias..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: gitlab-redis
  namespace: gitlab
spec:
  type: ExternalName
  externalName: redis.${NAMESPACE}.svc.cluster.local
  ports:
  - port: 6379
    targetPort: 6379
EOF

log_ok "Redis service alias created"

# 7. 创建 GitLab Secrets
log_info "Creating GitLab secrets..."

kubectl create secret generic gitlab-postgresql-password \
    --from-literal=password="${POSTGRES_PASSWORD:-postgres123}" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitlab-redis-password \
    --from-literal=password="" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitlab-root-password \
    --from-literal=password="${GITLAB_ROOT_PASSWORD:-changeme123}" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-objectstore-connection
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  connection: |
    provider: AWS
    region: us-east-1
    aws_access_key_id: ${MINIO_ROOT_USER:-admin}
    aws_secret_access_key: ${MINIO_ROOT_PASSWORD:-admin12345}
    endpoint: http://minio.${NAMESPACE}.svc.cluster.local:9000
EOF

log_ok "GitLab secrets created"

log_ok "GitLab preparation completed successfully!"
