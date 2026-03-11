# Q-PaaS Infrastructure (q-infra)

DevOps 基建设施部署模块，用于快速部署 Jenkins、Harbor、GitLab 等 PaaS 平台前置依赖服务，以及 MySQL、Redis、PostgreSQL、MinIO 等中间件服务。

支持 Docker Compose 和 Kubernetes（Helm）两种部署方式，通过 Makefile + Shell 脚本实现一键部署和状态监控。

## 快速开始

```bash
# 1. 初始化环境配置
cd q-infra
make infra-env          # 从模板生成 .env，按需修改

# 2. 部署服务
make infra-deploy SERVICE=mysql              # 部署 MySQL
make infra-deploy SERVICE=redis              # 部署 Redis
make infra-deploy-all                        # 部署全部

# 3. 查看状态
make infra-status                            # 全部状态
make infra-status SERVICE=mysql              # 单个状态

# 4. 销毁服务
make infra-destroy SERVICE=mysql             # 销毁单个
make infra-destroy-all                       # 销毁全部
```

## 服务清单

### DevOps 服务

| 服务 | 默认端口 | 健康检查 | 用途 |
|------|----------|----------|------|
| Jenkins | 8090 | `/login` | CI 构建服务 |
| Harbor | 8880 | `/api/v2.0/health` | 镜像仓库 |
| GitLab | 8929 | `/-/readiness` | 代码托管 |

### 中间件服务

| 服务 | 默认存储 | 用途 |
|------|----------|------|
| MySQL | 1Gi | 关系型数据库 |
| Redis | 256Mi | 缓存/消息队列 |
| PostgreSQL | 1Gi | 关系型数据库 |
| MinIO | 2Gi | 对象存储 |

## 目录结构

```
q-infra/
├── Makefile              # 一键操作入口
├── scripts/
│   ├── deploy.sh         # 部署/销毁调度
│   ├── status.sh         # 状态检查
│   └── utils.sh          # 公共函数
├── helm/                 # Kubernetes Helm Chart
│   ├── jenkins/
│   ├── harbor/
│   ├── gitlab/
│   ├── mysql/            # Bitnami MySQL Chart
│   ├── redis/            # Bitnami Redis Chart
│   ├── postgresql/       # Bitnami PostgreSQL Chart
│   └── minio/            # Bitnami MinIO Chart
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
    └── minio.env.example
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

更多配置项见各服务的 `env/<service>.env.example`。

## Helm Chart 来源

中间件服务使用 Bitnami 官方 Chart：

| 服务 | Chart | 版本 |
|------|-------|------|
| MySQL | bitnami/mysql | 12.3.5 |
| Redis | bitnami/redis | latest |
| PostgreSQL | bitnami/postgresql | latest |
| MinIO | bitnami/minio | latest |

## 前置要求

- **Docker Compose 模式**: Docker Engine 20+ / Docker Desktop
- **Helm 模式**: kubectl + Helm 3 + 可用的 K8s 集群