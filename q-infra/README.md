# Q-PaaS Infrastructure (q-infra)

DevOps 基建设施部署模块，用于快速部署 Jenkins、Harbor、GitLab 等 PaaS 平台前置依赖服务，以及 MySQL、Redis、PostgreSQL、MinIO、Kafka 等中间件服务。

支持 Docker Compose 和 Kubernetes（Helm）两种部署方式，通过 Makefile + Shell 脚本实现一键部署和状态监控。

## 快速开始

### 一键部署（推荐）

```bash
# 1. 初始化环境配置
cd q-infra
make infra-env          # 从模板生成 .env，按需修改

# 2. 一键部署所有服务
./scripts/deploy-all.sh

# 3. 查看状态
make infra-status
```

### 单独部署

```bash
# 部署单个服务
make infra-deploy SERVICE=mysql              # 部署 MySQL
make infra-deploy SERVICE=redis              # 部署 Redis
make infra-deploy SERVICE=kafka              # 部署 Kafka
make infra-deploy SERVICE=gitlab             # 部署 GitLab

# 查看状态
make infra-status                            # 全部状态
make infra-status SERVICE=mysql              # 单个状态

# 销毁服务
make infra-destroy SERVICE=mysql             # 销毁单个
make infra-destroy-all                       # 销毁全部
```

## 服务清单

### DevOps 服务

| 服务 | 默认端口 | 健康检查 | 用途 | 资源配置 |
|------|----------|----------|------|----------|
| Jenkins | 8090 | `/login` | CI 构建服务 | 1Gi-2Gi / 500m-2CPU |
| Harbor | 8880 | `/api/v2.0/health` | 镜像仓库 | 256Mi-512Mi / 200m-1CPU |
| GitLab | 8929 | `/-/readiness` | 代码托管 | 1Gi-2Gi / 500m-2CPU |

### 中间件服务

| 服务 | 默认存储 | 用途 | 资源配置 |
|------|----------|------|----------|
| MySQL | 5Gi | 关系型数据库 | 512Mi-1Gi / 250m-1CPU |
| Redis | 1Gi | 缓存/消息队列 | 256Mi-512Mi / 200m-1CPU |
| PostgreSQL | 5Gi | 关系型数据库 | 512Mi-1Gi / 250m-1CPU |
| MinIO | 10Gi | 对象存储 | 512Mi-1Gi / 250m-1CPU |
| Kafka | 5Gi | 事件流/消息总线 | 512Mi-1Gi / 250m-1CPU |

## 目录结构

```
q-infra/
├── Makefile              # 一键操作入口
├── scripts/
│   ├── deploy.sh         # 部署/销毁调度
│   ├── deploy-all.sh     # 一键部署所有服务
│   ├── prepare-gitlab.sh # GitLab 部署前准备
│   ├── status.sh         # 状态检查
│   └── utils.sh          # 公共函数
├── helm/                 # Kubernetes Helm Chart
│   ├── jenkins/
│   ├── harbor/
│   ├── gitlab/
│   ├── mysql/            # groundhog2k MySQL Chart
│   ├── redis/            # groundhog2k Redis Chart
│   ├── postgresql/       # groundhog2k PostgreSQL Chart
│   ├── minio/            # Official MinIO Chart
│   └── kafka/            # Bitnami Kafka Chart
├── compose/              # Docker Compose 配置
│   ├── jenkins/
│   ├── harbor/
│   └── gitlab/
└── env/                  # 环境变量模板
    ├── .env.example
    ├── jenkins.env.example
    ├── harbor.env.example
    ├── gitlab.env.example
    ├── mysql.env.example
    ├── redis.env.example
    ├── postgresql.env.example
    ├── minio.env.example
    └── kafka.env.example
```

## 部署模式

- **auto**（默认）：自动检测环境，优先 Kubernetes，降级到 Docker Compose
- **compose**：强制使用 Docker Compose
- **helm**：强制使用 Helm（需要 K8s 集群）

```bash
make infra-deploy SERVICE=mysql MODE=helm      # 强制 Helm
make infra-deploy SERVICE=jenkins MODE=compose # 强制 Compose
```

## 配置说明

复制 `env/.env.example` 为 `.env` 后修改：

### DevOps 服务

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `JENKINS_PORT` | 8090 | Jenkins Web 端口 |
| `JENKINS_ADMIN_PASSWORD` | changeme | Jenkins 管理员密码 |
| `HARBOR_PORT` | 8880 | Harbor Web 端口 |
| `HARBOR_ADMIN_PASSWORD` | Harbor12345 | Harbor 管理员密码 |
| `GITLAB_PORT` | 8929 | GitLab Web 端口 |
| `GITLAB_ROOT_PASSWORD` | changeme123 | GitLab root 密码 |

### 中间件服务

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MYSQL_ROOT_PASSWORD` | root123 | MySQL root 密码 |
| `MYSQL_DATABASE` | appdb | MySQL 默认数据库 |
| `REDIS_AUTH_ENABLED` | false | Redis 是否启用认证 |
| `POSTGRES_PASSWORD` | postgres123 | PostgreSQL 密码 |
| `POSTGRES_DATABASE` | appdb | PostgreSQL 默认数据库 |
| `MINIO_ROOT_USER` | admin | MinIO 管理员用户名 |
| `MINIO_ROOT_PASSWORD` | admin123 | MinIO 管理员密码 |
| `KAFKA_NODEPORT` | 30092 | Kafka NodePort（本机访问） |
| `KAFKA_CLUSTER_HOST` | kafka.q-infra.svc.cluster.local | Kafka 集群内访问域名 |
| `KAFKA_CLUSTER_PORT` | 9092 | Kafka 集群内访问端口 |

更多配置项见各服务的 `env/<service>.env.example`。

## 部署优化

### 自动化准备

- **GitLab**: 自动创建数据库、Redis 别名、必要的 Secrets
- **资源配置**: 已优化所有组件的内存和 CPU 配置，确保稳定运行
- **健康检查**: 放宽启动探针和存活探针参数，避免冷启动时被误杀
- **测试钩子**: 已禁用 Helm 测试钩子，避免部署时的测试失败

### 部署顺序

一键部署脚本会按照以下顺序部署：

1. **中间件服务**: PostgreSQL → Redis → MinIO → MySQL → Kafka
2. **等待就绪**: 确保所有中间件服务完全启动
3. **应用服务**: GitLab → Jenkins → Harbor

### 故障排查

如果部署失败，检查以下内容：

```bash
# 查看 Pod 状态
kubectl get pods -n q-infra

# 查看特定 Pod 日志
kubectl logs -n q-infra <pod-name>

# 查看 Pod 详细信息
kubectl describe pod -n q-infra <pod-name>

# 重新部署单个服务
make infra-destroy SERVICE=gitlab
make infra-deploy SERVICE=gitlab
```

## Helm Chart 来源

中间件服务使用轻量级 Chart：

| 服务 | Chart | 仓库 |
|------|-------|------|
| MySQL | groundhog2k/mysql | https://groundhog2k.github.io/helm-charts |
| Redis | groundhog2k/redis | https://groundhog2k.github.io/helm-charts |
| PostgreSQL | groundhog2k/postgres | https://groundhog2k.github.io/helm-charts |
| MinIO | minio/minio | https://charts.min.io |
| Kafka | bitnami/kafka | https://charts.bitnami.com/bitnami |

DevOps 服务使用官方 Chart：

| 服务 | Chart | 仓库 |
|------|-------|------|
| Jenkins | jenkins/jenkins | https://charts.jenkins.io |
| Harbor | harbor/harbor | https://helm.goharbor.io |
| GitLab | gitlab/gitlab | https://charts.gitlab.io |

## 前置要求

- **Docker Compose 模式**: Docker Engine 20+ / Docker Desktop
- **Helm 模式**: kubectl + Helm 3 + 可用的 K8s 集群
