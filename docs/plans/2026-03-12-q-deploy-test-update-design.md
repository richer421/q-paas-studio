# q-deploy 测试用例更新设计

## 概述

为 `app/deploy/app.go` 的 `ExecuteDeployPlan` 方法新增基础正常流程测试。

## 背景

- 当前 q-deploy 项目只有 2 个测试文件：
  - `http/common/response_test.go` - HTTP 响应测试
  - `domain/engine/gitops/engine_test.go` - GitOps 引擎测试
- `app/deploy/app.go` 是 app 层的核心服务，但没有对应的测试文件
- 根据 CLAUDE.md 的测试范式："对 app 层关键函数编写测试"

## 测试目标

为 `app/deploy/app.go` 创建测试文件 `app/deploy/app_test.go`，测试 `ExecuteDeployPlan` 方法的正常执行流程。

## 测试方法

使用 fake 对象 mock 依赖，与现有测试风格保持一致（参考 `domain/engine/gitops/engine_test.go`）。

## 代码修改

### 1. 修改 `app/deploy/app.go`

为了支持测试，需要将 engine 和 renderer 的创建逻辑注入到 `AppService` 中：

```go
type AppService struct {
    engineFactory  func(cfg engine.Config, renderer render.Renderer, gitClient gitops.GitClient, releaseRepo gitops.ReleaseRepo) (engine.Engine, error)
    rendererFactory func(cfg render.Config) render.Renderer
}

func NewAppService() *AppService {
    return &AppService{
        engineFactory:  engine.New,
        rendererFactory: render.New,
    }
}
```

修改 `ExecuteDeployPlan` 方法，使用注入的工厂函数：

```go
func (s *AppService) ExecuteDeployPlan(ctx context.Context, cmd *vo.ExecuteDeployPlanCmd) (*vo.ReleaseDTO, error) {
    // ... 构造 AppSpec ...

    renderer := s.rendererFactory(render.Config{Type: rendererType})

    eng, err := s.engineFactory(cfg, renderer, gitclient.New(), nil)
    if err != nil {
        return nil, err
    }

    // ... 其余逻辑不变 ...
}
```

### 2. 创建 `app/deploy/app_test.go`

创建测试文件，包含以下内容：

#### 2.1 fakeEngine

实现 `engine.Engine` 接口，mock `Publish()` 方法：

```go
type fakeEngine struct {
    publishResult *gitops.PublishResult
    publishError  error
}

func (f *fakeEngine) Publish(ctx context.Context, in gitops.PublishInput) (*gitops.PublishResult, error) {
    if f.publishError != nil {
        return nil, f.publishError
    }
    return f.publishResult, nil
}
```

#### 2.2 fakeRenderer

实现 `render.Renderer` 接口（如果需要）。

#### 2.3 测试用例

```go
func TestExecuteDeployPlan_HappyPath(t *testing.T) {
    // 准备测试数据
    cmd := &vo.ExecuteDeployPlanCmd{
        Plan: vo.DeployPlanSpec{
            BusinessUnitID: 1,
            PlanID:         2,
            CIConfig:       vo.CIConfigSpec{ConfigID: 3},
            CDConfig:       vo.CDConfigSpec{ConfigID: 4, Strategy: ...},
            InstanceConfig: vo.InstanceConfigSpec{ConfigID: 5, Spec: ...},
        },
        Artifact: vo.ArtifactSpec{
            ID:       6,
            ImageRef: "registry.example.com/project/service:v1",
        },
    }

    // 创建 fake engine
    fakeEng := &fakeEngine{
        publishResult: &gitops.PublishResult{
            ReleaseID: 42,
            GitOpsSnapshot: gitops.GitOpsSnapshot{
                RepoURL:      "https://github.com/example/gitops.git",
                Branch:       "main",
                ManifestPath: "/manifests",
                AppPath:      "/apps/example",
                AppName:      "example-app",
            },
        },
    }

    // 创建 AppService，注入 fake 工厂函数
    svc := &AppService{
        engineFactory: func(cfg engine.Config, renderer render.Renderer, gitClient gitops.GitClient, releaseRepo gitops.ReleaseRepo) (engine.Engine, error) {
            return fakeEng, nil
        },
        rendererFactory: func(cfg render.Config) render.Renderer {
            return nil // 可以返回 nil，因为 fake engine 不会使用
        },
    }

    // 执行测试
    result, err := svc.ExecuteDeployPlan(context.Background(), cmd)

    // 验证结果
    if err != nil {
        t.Fatalf("ExecuteDeployPlan returned error: %v", err)
    }
    if result == nil {
        t.Fatalf("ExecuteDeployPlan returned nil result")
    }
    if result.ReleaseID != 42 {
        t.Errorf("unexpected ReleaseID: got %d, want 42", result.ReleaseID)
    }
    if result.GitOps.RepoURL != "https://github.com/example/gitops.git" {
        t.Errorf("unexpected RepoURL: got %s", result.GitOps.RepoURL)
    }
    // ... 其他验证 ...
}
```

## 测试覆盖范围

- 测试 `ExecuteDeployPlan` 的正常执行流程
- 验证 AppSpec 的构造是否正确（通过 fake engine 接收到的参数）
- 验证 ReleaseDTO 的转换是否正确

## 不包含的内容

- 错误处理测试（engine 创建失败、Publish 失败等）
- 边界情况测试
- 不同 engine 类型和 renderer 类型的测试

这些可以在后续迭代中添加。

## 实现步骤

1. 修改 `app/deploy/app.go`，添加工厂函数字段
2. 创建 `app/deploy/app_test.go`，实现 fake 对象
3. 编写测试用例 `TestExecuteDeployPlan_HappyPath`
4. 运行测试，验证通过

## 验证标准

- 测试能够成功运行
- 测试覆盖 `ExecuteDeployPlan` 的正常流程
- 测试代码清晰，易于理解
- 与现有测试风格保持一致
