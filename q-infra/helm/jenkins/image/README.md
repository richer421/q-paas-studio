# Jenkins K8s Image

用于 K8s/Helm 部署 Jenkins 的基础镜像模板。

## 作用

- 预装 `q-ci` 流水线需要的 Jenkins 插件
- 内置 `docker` CLI 和 `curl`
- 作为 Helm 模式下执行真实构建的 Jenkins controller 或 agent 基线镜像

## 构建示例

```bash
docker build \
  -f q-infra/helm/jenkins/image/Dockerfile \
  -t <your-registry>/q-paas-jenkins:lts-jdk17-ci \
  q-infra/helm/jenkins/image
```

## 推送后配置

将 `q-infra/helm/jenkins/values-overrides.yaml` 中的 `controller.image.repository` 和 `controller.image.tag` 改为你的镜像。
