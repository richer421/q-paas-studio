# GitOps 全流程配置指南

本文档描述 Kubernetes 中的 Jenkins + Harbor + ArgoCD 主链路。

## 架构

```text
GitHub(业务代码)
  -> Jenkins(q-ci-build)
  -> Harbor
  -> GitHub(GitOps 配置仓库)
  -> ArgoCD
  -> Kubernetes
```

## 一键部署

```bash
cd q-infra
make infra-gitops
```

## 访问方式

- ArgoCD: `http://localhost:30080`
- Jenkins: `http://localhost:30090`
- Harbor: `http://localhost:30180`

## Jenkins 约定

- Jenkins 通过 Helm 安装
- Jenkins 通过 JCasC 自动创建 `q-ci-build`
- `q-ci-build` 从主仓 submodule `q-jenkins-templates/` 对应的 GitHub 仓库加载模板
- 模板入口为 `q-jenkins-templates/pipelines/q-ci/Jenkinsfile`
- 需要通过 `env/jenkins.env.example` 或 `helm/jenkins/values-overrides.yaml` 注入：
  - GitHub 模板仓库凭据
  - 业务代码仓库凭据
  - Harbor 凭据

## Jenkins 真实构建镜像

若 Jenkins 需要执行真实 `docker build`，请先基于下面目录构建并推送自定义镜像，再写回 Helm values：

- `helm/jenkins/image/Dockerfile`
- `helm/jenkins/image/plugins.txt`

## Harbor 约定

- 在 Harbor 中创建项目，例如 `q-paas`
- 创建可推送镜像的 Robot Account
- 将账号密码配置为 Jenkins 凭据 `q-paas-harbor`

## ArgoCD 约定

- 监听 GitOps 配置仓库
- 应用变更由 Jenkins 更新 GitOps 仓库后自动同步

## 验证

```bash
kubectl get pods -n q-infra
kubectl get pods -n argocd
kubectl get svc -n q-infra
kubectl get svc -n argocd
```
