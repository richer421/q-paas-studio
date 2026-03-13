# GitOps 全流程配置指南

本文档介绍如何配置 Jenkins + Harbor + ArgoCD 实现完整的 GitOps 工作流。

## 架构概览

```
GitHub (代码仓库)
    ↓ webhook
Jenkins (CI)
    ↓ 构建镜像
Harbor (镜像仓库)
    ↓ 更新 GitOps 配置
GitHub (GitOps 配置仓库)
    ↓ 监听变更
ArgoCD (CD)
    ↓ 自动部署
Kubernetes 集群
```

## 快速开始

### 1. 一键部署

```bash
cd q-infra
make infra-gitops
```

这将自动部署：
- 中间件：MySQL + Redis + PostgreSQL
- DevOps 服务：Jenkins + Harbor + ArgoCD

### 2. 获取访问信息

**ArgoCD**
- URL: http://localhost:30080
- 用户名: admin
- 密码: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`

**Jenkins**
- URL: http://localhost:30800
- 用户名: admin
- 密码: `kubectl -n q-infra get secret jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d`

**Harbor**
- URL: http://localhost:30880
- 用户名: admin
- 密码: Harbor12345

## 配置步骤

### 步骤 1: 配置 Harbor

1. 登录 Harbor (http://localhost:30880)
2. 创建项目（如 `q-paas`）
3. 创建 Robot Account 用于 Jenkins 推送镜像

### 步骤 2: 配置 Jenkins

1. 登录 Jenkins (http://localhost:30800)
2. 安装插件：
   - Docker Pipeline
   - Kubernetes
   - Git
3. 配置 Harbor 凭据：
   - Manage Jenkins → Credentials
   - 添加 Username/Password 类型凭据
   - ID: `harbor-robot`
4. 配置 GitHub 凭据：
   - 添加 Username/Password 或 SSH Key
   - ID: `github-token`

### 步骤 3: 创建 Jenkins Pipeline

创建 Jenkinsfile：

```groovy
pipeline {
    agent any

    environment {
        HARBOR_URL = 'localhost:30880'
        HARBOR_PROJECT = 'q-paas'
        IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/myapp"
        IMAGE_TAG = "${BUILD_NUMBER}"
        GITOPS_REPO = 'https://github.com/your-org/gitops-config.git'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/your-org/your-app.git',
                    credentialsId: 'github-token'
            }
        }

        stage('Build Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Push to Harbor') {
            steps {
                script {
                    docker.withRegistry("http://${HARBOR_URL}", 'harbor-robot') {
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push('latest')
                    }
                }
            }
        }

        stage('Update GitOps Config') {
            steps {
                script {
                    // Clone GitOps 配置仓库
                    sh """
                        git clone ${GITOPS_REPO} gitops-config
                        cd gitops-config

                        # 更新镜像版本
                        sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g' k8s/deployment.yaml

                        # 提交并推送
                        git config user.email "jenkins@example.com"
                        git config user.name "Jenkins"
                        git add .
                        git commit -m "Update image to ${IMAGE_TAG}"
                        git push origin main
                    """
                }
            }
        }
    }
}
```

### 步骤 4: 配置 ArgoCD

1. 登录 ArgoCD (http://localhost:30080)

2. 连接 GitHub 仓库：
   ```bash
   argocd repo add https://github.com/your-org/gitops-config.git \
     --username your-username \
     --password your-token
   ```

3. 创建 Application：
   ```bash
   argocd app create myapp \
     --repo https://github.com/your-org/gitops-config.git \
     --path k8s \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace default \
     --sync-policy automated \
     --auto-prune \
     --self-heal
   ```

   或通过 UI 创建：
   - Application Name: myapp
   - Project: default
   - Sync Policy: Automatic
   - Repository URL: https://github.com/your-org/gitops-config.git
   - Path: k8s
   - Cluster: https://kubernetes.default.svc
   - Namespace: default

### 步骤 5: 创建 GitOps 配置仓库

在 GitHub 创建新仓库 `gitops-config`，结构如下：

```
gitops-config/
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── README.md
```

示例 `deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: localhost:30880/q-paas/myapp:latest
        ports:
        - containerPort: 8080
```

## 完整工作流

1. **开发者推送代码** → GitHub
2. **GitHub webhook 触发** → Jenkins Pipeline
3. **Jenkins 构建镜像** → 推送到 Harbor
4. **Jenkins 更新 GitOps 配置** → 推送到 GitHub
5. **ArgoCD 检测到变更** → 自动同步到 K8s
6. **应用自动部署** → Kubernetes 集群

## 验证部署

```bash
# 查看 ArgoCD 应用状态
kubectl get applications -n argocd

# 查看应用 Pod
kubectl get pods -n default

# 查看 ArgoCD 同步历史
argocd app history myapp
```

## 故障排查

### Jenkins 无法推送到 Harbor

1. 检查 Harbor 凭据是否正确
2. 确认 Harbor 项目已创建
3. 检查网络连接：`curl http://localhost:30880`

### ArgoCD 无法同步

1. 检查 GitHub 仓库凭据
2. 查看 ArgoCD 日志：`kubectl logs -n argocd deployment/argocd-server`
3. 检查 Application 状态：`argocd app get myapp`

### 镜像拉取失败

1. 确认 K8s 可以访问 Harbor
2. 创建 imagePullSecret：
   ```bash
   kubectl create secret docker-registry harbor-secret \
     --docker-server=localhost:30880 \
     --docker-username=admin \
     --docker-password=Harbor12345
   ```
3. 在 Deployment 中引用：
   ```yaml
   spec:
     imagePullSecrets:
     - name: harbor-secret
   ```

## 高级配置

### 多环境部署

创建不同的 GitOps 配置目录：

```
gitops-config/
├── dev/
│   └── k8s/
├── staging/
│   └── k8s/
└── prod/
    └── k8s/
```

为每个环境创建独立的 ArgoCD Application。

### 自动回滚

在 ArgoCD Application 中启用自动回滚：

```yaml
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 通知集成

配置 ArgoCD 通知（Slack、Email 等）：

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: Application {{.app.metadata.name}} is now running new version.
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
EOF
```

## 参考资料

- [ArgoCD 官方文档](https://argo-cd.readthedocs.io/)
- [Jenkins Pipeline 文档](https://www.jenkins.io/doc/book/pipeline/)
- [Harbor 文档](https://goharbor.io/docs/)
