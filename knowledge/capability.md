# 核心业务能力

描述系统解决的业务问题和核心能力边界。

## 设计原则

- 只描述"做什么"，不描述"怎么做"
- 接口细节由 Swagger 文档维护，此处不重复
- 新增模块时，说明业务场景而非 API 列表

## 能力清单

### q-deploy（服务发布平台）

核心发布能力，支持多种发布模式。

- **发布**：完整部署，新产物 + 新工作负载 YAML + 新配套资源 YAML
- **更新**：配套资源变更（ConfigMap/Secret/Service 等），工作负载和产物不变
- **回滚**：回退到历史版本的工作负载 YAML + 配套资源 YAML
- 渲染引擎（Helm/Kustomize/自定义模板）
- 工作引擎（Kubernetes/Docker/SSH）— CDConfig 中尚未建模 WorkEngine 字段，当前仅实现 RenderEngine

### q-ci（持续集成服务）

构建与测试能力。

- **CI 工作流**：Kafka 触发 → Jenkins 构建 → Webhook 回调，完整构建流水线
- **产物管理**：构建产物（镜像）全生命周期管理，状态追踪（pending/running/success/failed）
- **Jenkins 集成**：预定义模板 Job 参数化构建，ArtifactID 作为 correlation key
- 测试执行（规划中）

### q-workflow（工作流引擎）

流程编排能力。

- 工作流定义
- 任务编排
- 状态追踪

### q-metahub（元数据中心）

元数据管理能力，管理 PaaS 平台核心元数据与配置关系。

- **项目管理**：代码仓库映射（Git 平台项目 ID、仓库地址）
- **业务单元管理**：独立交付单元及其项目关联、部署计划组织
- **部署计划管理**：聚合CI/CD/实例配置的完整配置包
- **CI配置管理**：构建参数、镜像标签规则、构建规格
- **CD配置管理**：部署策略、渲染引擎配置
- **实例配置管理**：环境（dev/test/gray/prod）、K8s 原生工作负载 Spec、附加资源
- **依赖与资源管理**：中间件定义、依赖绑定（规划中，未实现）

### q-infra（基建设施部署）

DevOps 基建服务的一键部署与状态监控，是 PaaS 平台的前置依赖。

- **服务部署**：Jenkins（CI 构建）、Harbor（镜像仓库）、GitLab（代码托管）的自动化部署
- **多模式支持**：Docker Compose（本地/单机）和 Kubernetes Helm（集群）两种部署方式，自动检测环境
- **状态监控**：HTTP 健康探针 + 容器/Pod 状态检查
- 纯配置/模板项目，通过 Makefile + Shell 脚本实现，不含独立后端服务
