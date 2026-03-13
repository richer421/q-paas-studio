# GitOps 快速开始指南

一键部署 Jenkins + Harbor + ArgoCD 的完整 GitOps 工作流。

## 前置要求

- Kubernetes 集群（Docker Desktop / Minikube / Kind）
- kubectl 已配置
- Helm 3.x
- 至少 8GB 可用内存

## 一键部署

```bash
cd q-infra
make infra-gitops
```

等待 5 分钟，所有组件将自动部署完成。

## 访问服务

### ArgoCD
- URL: http://localhost:30080
- 用户名: `admin`
- 密码:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
  ```

### Jenkins
- URL: http://localhost:30090
- 用户名: `admin`
- 密码:
  ```bash
  kubectl exec -n q-infra jenkins-0 -c jenkins -- cat /run/secrets/additional/chart-admin-password
  ```

### Harbor
- URL: http://localhost:30180
- 用户名: `admin`
- 密码: `Harbor12345`

## 验证部署

```bash
# 查看所有 Pod 状态
kubectl get pods -n q-infra
kubectl get pods -n argocd

# 查看服务端口
kubectl get svc -n q-infra
kubectl get svc -n argocd
```

所有 Pod 应该处于 `Running` 状态。

## 配置 GitOps 工作流

### 步骤 1: 配置 Harbor

1. 登录 Harbor (http://localhost:30180)
2. 创建项目（如 `q-paas`）
3. 创建 Robot Account：
   - 项目 → Robot Accounts → New Robot Account
   - 名称: `jenkins-robot`
   - 权限: Push Artifact, Pull Artifact
   - 保存 Token

### 步骤 2: 配置 Jenkins

1. 登录 Jenkins (http://localhost:30090)

2. 安装插件：
   - Manage Jenkins → Plugins → Available plugins
   - 搜索并安装：Docker Pipeline, Kubernetes, Git

3. 配置 Harbor 凭据：
   - Manage Jenkins → Credentials → System → Global credentials
   - Add Credentials
   - Kind: Username with password
   - Username: `robot$jenkins-robot`
   - Password: `<Harbor Robot Token>`
   - ID: `harbor-robot`

4. 配置 GitHub 凭据：
   - Add Credentials
   - Kind: Username with password (或 SSH Key)
   - ID: `github-token`

### 步骤 3: 创建 Jenkins Pipeline

创建新的 Pipeline 任务，使用以下 Jenkinsfile：

```groovy
pipeline {
    agent any

    environment {
        HARBOR_URL = 'localhost:30180'
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
                    sh """
                        git clone ${GITOPS_REPO} gitops-config
                        cd gitops-config
                        sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g' k8s/deployment.yaml
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

2. 添加 Git 仓库：
   - Settings → Repositories → Connect Repo
   - Repository URL: `https://github.com/your-org/gitops-config.git`
   - Username: `your-username`
   - Password: `your-token`

3. 创建 Application：
   - Applications → New App
   - Application Name: `myapp`
   - Project: `default`
   - Sync Policy: `Automatic`
   - Repository URL: `https://github.com/your-org/gitops-config.git`
   - Path: `k8s`
   - Cluster URL: `https://kubernetes.default.svc`
   - Namespace: `default`

### 步骤 5: 创建 GitOps 配置仓库

在 GitHub 创建新仓库 `gitops-config`：

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
        image: localhost:30180/q-paas/myapp:latest
        ports:
        - containerPort: 8080
```

## 测试完整流程

1. **推送代码到 GitHub**
2. **触发 Jenkins Pipeline**（手动或 webhook）
3. **Jenkins 构建镜像并推送到 Harbor**
4. **Jenkins 更新 GitOps 配置仓库**
5. **ArgoCD 自动检测变更并部署到 K8s**

验证：
```bash
# 查看 ArgoCD 应用状态
kubectl get applications -n argocd

# 查看部署的应用
kubectl get pods -n default
```

## 故障排查

### Jenkins 无法推送到 Harbor
```bash
# 检查 Harbor 服务
kubectl get svc -n q-infra | grep harbor

# 检查 Jenkins 凭据
# Manage Jenkins → Credentials → 验证 harbor-robot 凭据
```

### ArgoCD 无法同步
```bash
# 查看 ArgoCD 日志
kubectl logs -n argocd deployment/argocd-server

# 检查 Git 仓库连接
# ArgoCD UI → Settings → Repositories
```

### 镜像拉取失败
```bash
# 创建 imagePullSecret
kubectl create secret docker-registry harbor-secret \
  --docker-server=localhost:30180 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  -n default

# 在 Deployment 中引用
spec:
  imagePullSecrets:
  - name: harbor-secret
```

## 卸载

```bash
# 卸载所有服务
cd q-infra
make infra-destroy-all

# 卸载单个服务
make infra-destroy SERVICE=jenkins
make infra-destroy SERVICE=harbor
make infra-destroy SERVICE=argocd
```

## 更多信息

- 详细配置指南: [README-GITOPS.md](./README-GITOPS.md)
- 测试报告: [TEST-REPORT.md](./TEST-REPORT.md)
- ArgoCD 文档: https://argo-cd.readthedocs.io/
- Jenkins 文档: https://www.jenkins.io/doc/
- Harbor 文档: https://goharbor.io/docs/
