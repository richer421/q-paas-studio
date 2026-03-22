# Q-PaaS Infrastructure (q-infra)

用于在 Kubernetes 中部署 Jenkins、Harbor、GitLab、ArgoCD，以及 MySQL、Redis、PostgreSQL、MinIO、Kafka 等基础设施。

`q-infra` 现在只保留 Helm / K8s 部署路径。

## 快速开始

```bash
cd q-infra
make infra-env
make infra-deploy-all
make infra-status
```

单独部署或销毁：

```bash
make infra-deploy SERVICE=jenkins
make infra-status SERVICE=jenkins
make infra-destroy SERVICE=jenkins
make infra-destroy-all
```

## 目录

```text
q-infra/
├── Makefile
├── scripts/
├── helm/
│   ├── jenkins/
│   ├── harbor/
│   ├── gitlab/
│   ├── argocd/
│   ├── mysql/
│   ├── redis/
│   ├── postgresql/
│   ├── minio/
│   └── kafka/
└── env/
```

## 配置

复制 `env/.env.example` 为 `.env` 后按需调整。

Jenkins 模板仓库约定：

- 模板仓库以 submodule 形式收敛在主仓的 `q-jenkins-templates/`
- Jenkins 通过 JCasC 自动创建 `q-ci-build`
- Job 从 `q-jenkins-templates/pipelines/q-ci/Jenkinsfile` 拉取流水线模板
- 模板分支由 `JENKINS_TEMPLATE_REPO_BRANCH` 控制
- 凭据通过 `env/jenkins.env.example` 或 Helm `additionalSecrets` 注入
- 真实构建建议使用 `helm/jenkins/image/` 里的 Jenkins 基线镜像

## 部署顺序

一键部署脚本顺序：

1. PostgreSQL → Redis → MinIO → MySQL → Kafka
2. GitLab → Jenkins → Harbor

## 常用排查

```bash
kubectl get pods -n q-infra
kubectl get svc -n q-infra
kubectl logs -n q-infra <pod-name>
kubectl describe pod -n q-infra <pod-name>
```

## 前置要求

- kubectl
- Helm 3
- 可用的 Kubernetes 集群
