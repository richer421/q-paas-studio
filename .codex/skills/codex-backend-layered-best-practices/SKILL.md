---
name: codex-backend-layered-best-practices
description: Use when doing backend development tasks in Codex-driven projects, including feature work, bugfixes, refactors, and service integration, so app/domain layering and business orchestration boundaries are consistently applied.
---

# Codex Backend Layered Best Practices

## 基本概念

1. app 层：业务能力提供者，对外暴露业务能力，对内负责编排业务流程。
2. domain 层：核心业务能力抽象，向 app 层提供统一、可编排的业务语义。
3. 分层目标：高内聚、低耦合；语义稳定，边界清晰。

## 规则

1. app 层职责：
按业务域集中暴露能力入口（例如 app 聚合文件）；负责流程编排，不承载复杂领域规则。
2. app 层实现范围：
允许做视图对象转换（DTO/VO）与简单 CRUD 封装；复杂业务规则必须下沉到 domain 层。
3. domain 层职责：
抽象核心业务能力，封装可复用业务语义，向 app 层提供稳定接口。
4. 依赖方向：
app 依赖 domain；domain 不反向依赖 app 的流程编排细节。
5. 变更原则：
新增业务能力优先扩展 domain 语义，再由 app 编排接入；避免在 app 层堆叠临时逻辑。

## app 层代码风格

1. 入口集中：
在 `app.go` 统一暴露业务能力方法；方法尽量薄，主要做编排与转发。
推荐使用包级门面对象风格：`type app struct{}; var App = new(app)`。
2. 按业务拆文件：
同一业务域按 `list/create/update/delete/get` 组织在对应文件中，避免 app 巨石文件。
3. 转换与封装：
在 app 层完成 DTO/VO 转换、输入归一化、简单 CRUD 封装。
4. 规则边界：
复杂规则（策略、核心约束、跨对象语义）不留在 app 层，迁移到 domain 层抽象。
5. 错误语义：
对外错误信息保持业务可读；底层错误按需要包装，不泄漏无关实现细节。
6. 结构体约束：
app 门面结构体保持无状态（空结构体）；不要把 `Service/Repo` 作为字段塞进 `type app struct{...}` 再通过构造函数注入。

推荐目录结构（中立模板）：

```text
app/
└── <feature>/                # 单一业务域入口
    ├── app.go                # 对外暴露该域的应用层门面
    ├── <action>.go           # 单个用例的编排逻辑，如 create/list/get/update
    └── vo/
        └── <feature>.go      # 该域对外入参/出参视图模型

domain/
└── <feature>/                # 单一业务域的领域抽象
    ├── <role>.go             # 根包门面：接口、配置、工厂
    ├── model/
    │   └── types.go          # 稳定领域语义和跨实现共享端口
    └── <impl_name>/          # 某个具体实现子包
        └── <role>.go         # 实现根包定义的接口

infra/
├── <dependency_a>/           # 外部系统实现，如 git / queue / ci / config center
└── <dependency_b>/           # 仓储或第三方客户端实现
```

目录解释：

1. `app/<feature>/app.go`
该业务域唯一稳定入口，只负责流程编排和模型转换。
2. `app/<feature>/<action>.go`
按用例拆分薄方法，避免 `app.go` 变成巨石。
3. `domain/<feature>/<role>.go`
放接口、配置、工厂，不直接堆具体实现细节。
4. `domain/<feature>/model/types.go`
放稳定领域语义；当根包和子实现之间有双向依赖风险时，用它隔离共享类型和端口。
5. `domain/<feature>/<impl_name>/`
放某一种具体实现，命名按策略或实现差异命名，而不是按临时动作命名。
6. `infra/<dependency_x>/`
放对外部依赖的技术实现；domain 只依赖接口，不直接依赖这里的细节。

贴近项目的 app 示例：

```go
package deploy

import (
	"context"

	"github.com/example/q-paas/app/deploy/vo"
	"github.com/example/q-paas/domain/engine"
	"github.com/example/q-paas/domain/engine/gitops"
	render "github.com/example/q-paas/domain/render"
)

type app struct{}

var App = new(app)

func (a *app) Deploy(ctx context.Context, req vo.DeployReq) (vo.ReleaseVO, error) {
	deployCtx, err := a.loadDeployContext(ctx, req)
	if err != nil {
		return vo.ReleaseVO{}, err
	}

	renderer, err := render.New(render.Config{Type: render.TypeK8sNative})
	if err != nil {
		return vo.ReleaseVO{}, err
	}

	deployEngine, err := engine.New(engine.Config{
		Type: engine.TypeGitOps,
		GitOps: gitops.EngineConfig{},
	}, renderer, gitClient, releaseRepo)
	if err != nil {
		return vo.ReleaseVO{}, err
	}

	in, err := buildDeployInput(deployCtx)
	if err != nil {
		return vo.ReleaseVO{}, err
	}

	res, err := deployEngine.Deploy(ctx, in)
	if err != nil {
		return vo.ReleaseVO{}, err
	}
	return convertToReleaseVO(res), nil
}
```

## domain 层代码风格

1. 先抽象再实现：
先定义接口、类型、配置与工厂入口（如 `Engine`/`Renderer` + `New`），再放具体实现子包。
2. 语义模型前置：
在 domain `model` 包定义稳定输入输出语义，避免上层直接依赖底层存储结构。
3. 编排函数拆小：
复杂流程按 `validate -> render/build -> write -> persist` 拆为私有函数链，主流程可读。
4. 外部依赖抽象：
Git、仓储、外部系统通过接口注入（如 `GitClient`、`ReleaseRepo`），实现可替换、可测试。
5. 默认实现可回退：
允许在构造函数中提供合理默认实现，但不破坏依赖注入边界。
6. 命名必须体现领域语义：
优先使用 `Builder`、`Engine`、`Renderer`、`Planner`、`Dispatcher` 等能表达职责边界的名称；不要默认落成泛化的 `Service`。
7. 上下游对象命名也要语义化：
domain 输入输出优先使用 `BuildCommand`、`DeployInput`、`RenderResult` 这类稳定业务名，避免 `TriggerCommand`、`CompleteCommand` 这类只描述过程动作、缺少领域上下文的命名。
8. 有现成同类模块时先对齐风格：
如果仓库里已有同类模块（如 `q-deploy` 的 `engine/render` 风格），优先复用其抽象层次、命名模式和小函数拆分习惯，而不是重新发明一套 `service` 风格。
9. 根包与子实现存在双向依赖风险时，引入 `model` 子包：
把稳定输入输出语义和外部依赖端口放到 `domain/<feature>/model`，根包做别名/工厂，子实现只依赖 `model`，避免 import cycle。
10. 门面接口定义优先放在根包门面文件：
例如 `builder.go`、`pipeline.go`、`artifact.go` 这类文件应承载该职责对外公开的接口；`model` 不应承载“这个域对外暴露什么能力”的定义。

推荐目录结构（中立模板）：

```text
domain/
└── <feature>/                    # 单一功能域
    ├── aliases.go                # 可选：根包对外别名，保持引用路径稳定
    ├── <role_a>.go               # 根包门面一：接口/配置/工厂
    ├── <role_b>.go               # 根包门面二：接口/配置/工厂
    ├── model/
    │   └── types.go              # 稳定领域模型、共享输入输出、依赖端口
    ├── <impl_a>/
    │   └── <role_a>.go           # 第一种具体实现
    └── <impl_b>/
        └── <role_b>.go           # 第二种具体实现

infra/
├── <external_system>/
│   └── client.go                 # 外部系统客户端或适配器
└── <repository>/
    └── repo.go                   # 仓储实现
```

目录解释：

1. `aliases.go`
只在“根包需要保持旧引用路径稳定”时使用；不是所有域都必须有。
2. `<role_a>.go` / `<role_b>.go`
表示同一功能域内两个不同层级或不同职责的抽象，例如选择器、编排器、渲染器、执行器。
3. `model/types.go`
是领域稳定层，不是“杂物间”；这里只放真正跨实现共享的语义和端口，不放根包对外门面接口。
4. `<impl_a>/` / `<impl_b>/`
表示具体策略实现目录。目录名应该体现“实现差异”，例如 `local`、`remote`、`gitops`、`native`，而不是 `service_impl` 这类空泛名字。
5. `infra/<external_system>/`
承接第三方系统调用细节。
6. `infra/<repository>/`
承接仓储落库、查询和模型映射细节。

贴近项目的 domain 根包示例：

```go
package build

import (
	"context"
	"fmt"

	"github.com/example/q-ci/domain/build/jenkins_builder"
	"github.com/example/q-ci/domain/build/standard_pipeline"
	buildmodel "github.com/example/q-ci/domain/build/model"
)

type BuildCommand = buildmodel.BuildCommand
type CallbackConfig = buildmodel.CallbackConfig
type Artifact = buildmodel.Artifact
type ArtifactRepository = buildmodel.ArtifactRepository
type Dispatcher = buildmodel.Dispatcher

type Builder interface {
	Build(ctx context.Context, req BuildDispatch) error
}

type Pipeline interface {
	Build(ctx context.Context, cmd BuildCommand, callback CallbackConfig) (*Artifact, bool, error)
	Complete(ctx context.Context, completion BuildCompletion) error
}

type BuilderType string

const (
	BuilderTypeJenkins BuilderType = "jenkins"
)

type BuilderConfig struct {
	Type BuilderType
}

func NewBuilder(cfg BuilderConfig, dispatcher Dispatcher) (Builder, error) {
	switch cfg.Type {
	case "", BuilderTypeJenkins:
		return jenkins_builder.New(dispatcher), nil
	default:
		return nil, fmt.Errorf("build: unsupported builder type %q", cfg.Type)
	}
}

type PipelineType string

const (
	PipelineTypeStandard PipelineType = "standard"
)

type PipelineConfig struct {
	Type PipelineType
}

func NewPipeline(cfg PipelineConfig, artifacts ArtifactRepository, builder Builder) (Pipeline, error) {
	switch cfg.Type {
	case "", PipelineTypeStandard:
		return standard_pipeline.New(artifacts, builder), nil
	default:
		return nil, fmt.Errorf("build: unsupported pipeline type %q", cfg.Type)
	}
}
```

贴近项目的 Builder 子实现示例：

```go
package jenkins_builder

import (
	"context"

	buildmodel "github.com/example/q-ci/domain/build/model"
)

type builder struct {
	dispatcher buildmodel.Dispatcher
}

func New(dispatcher buildmodel.Dispatcher) *builder {
	return &builder{
		dispatcher: dispatcher,
	}
}

func (b *builder) Build(ctx context.Context, req buildmodel.BuildDispatch) error {
	return b.dispatcher.Dispatch(ctx, req)
}
```

贴近项目的 Pipeline 子实现示例：

```go
package standard_pipeline

import (
	"context"
	"fmt"

	buildmodel "github.com/example/q-ci/domain/build/model"
)

type pipeline struct {
	artifacts buildmodel.ArtifactRepository
	builder   buildmodel.Builder
}

func New(artifacts buildmodel.ArtifactRepository, builder buildmodel.Builder) *pipeline {
	return &pipeline{
		artifacts: artifacts,
		builder:   builder,
	}
}

func (p *pipeline) Build(ctx context.Context, cmd buildmodel.BuildCommand, callback buildmodel.CallbackConfig) (*buildmodel.Artifact, bool, error) {
	artifact := buildArtifact(cmd, resolveImageTag(cmd))
	if err := p.artifacts.Create(ctx, artifact); err != nil {
		return nil, false, err
	}
	if err := p.builder.Build(ctx, buildmodel.BuildDispatch{
		ArtifactID: artifact.ID,
		ImageTag:   artifact.ImageTag,
	}); err != nil {
		return nil, true, fmt.Errorf("trigger build: %w", err)
	}
	if err := p.artifacts.MarkRunning(ctx, artifact.ID); err != nil {
		return nil, true, err
	}
	return artifact, true, nil
}
```

## 全局初始化与命名风格

1. 组合根唯一：
依赖组装统一放在启动入口（如 `cmd/*/main.go`、`internal/bootstrap`、`internal/wire`），不要分散到路由层。
2. 命名语义统一：
初始化函数使用可读动词：`NewXxx`（构造对象）、`InitXxx`（初始化资源）、`BuildXxx`（组装聚合对象）、`RegisterXxxRoutes`（注册路由）。
3. 路由层只做装配：
路由层只接收已构造好的 handler 并注册路径，不负责创建 handler 依赖。
4. 禁止项：
禁止在路由注册文件里直接 `new handler` 或隐式 new service/repo。

反例（禁止）：

```go
func RegisterRoutes(r *gin.Engine) {
	h := handler.NewOrderHandler() // 路由层直接 new，禁止
	r.POST("/orders", h.Create)
}
```

正例（推荐）：

```go
func InitHTTPServer() *gin.Engine {
	h := handler.App // 已在启动阶段完成初始化

	r := gin.New()
	RegisterOrderRoutes(r, h)
	return r
}

func RegisterOrderRoutes(r *gin.Engine, h *handler.OrderHandler) {
	r.POST("/orders", h.Create)
}
```

## Open Model 暴露规范

1. 对外模型集中维护：
对下游暴露的稳定契约类型统一放在独立的 open model 包（例如 `pkg/openModel/<domain>`），不要把 `app/.../vo` 直接暴露给外部调用方。
2. 转换函数集中维护：
由 `ToOpenModelXxx(...)` 负责从 app 聚合结果转换到 open model，接口层只调用转换函数，不重复拼装。
3. 多出口复用同一模型：
HTTP API 与 MCP 工具共用同一个 open model 转换结果，保证跨入口返回结构一致。
4. 契约优先稳定：
open model 结构字段采用明确 `json` 标签；新增字段优先走向后兼容（新增不破坏旧字段语义）。
5. 分层边界保持清晰：
`app` 返回业务聚合，open model 包负责外部契约映射，接口层仅负责协议适配与输出。

## 流程

1. 需求识别：
先判断是“流程编排变更”还是“领域能力变更”。
2. 领域优先建模：
涉及业务语义变化时，先在 domain 层定义/扩展能力，再由 app 层编排调用。
3. app 层落地：
集中在 app 文件暴露业务入口，完成 DTO/VO 转换与简单 CRUD 组织。
4. 边界校验：
检查 app 层是否出现复杂领域规则；若出现，回收至 domain 层。
5. 交付校验：
确认 app 层入口清晰、domain 语义可复用、跨模块调用不依赖具体流程细节。

## 反模式

1. 在 app 层直接实现复杂领域规则。
2. domain 层暴露过细的存储细节而非业务语义。
3. 同一业务能力在多个 app 文件重复编排，缺乏集中入口。
4. 把临时需求写成跨层耦合，导致后续演进困难。

仅在需要时再扩展脚本/模板资源；当前版本保持规范最小闭环。
