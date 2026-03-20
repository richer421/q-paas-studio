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
2. 按业务拆文件：
同一业务域按 `list/create/update/delete/get` 组织在对应文件中，避免 app 巨石文件。
3. 转换与封装：
在 app 层完成 DTO/VO 转换、输入归一化、简单 CRUD 封装。
4. 规则边界：
复杂规则（策略、核心约束、跨对象语义）不留在 app 层，迁移到 domain 层抽象。
5. 错误语义：
对外错误信息保持业务可读；底层错误按需要包装，不泄漏无关实现细节。

项目中立示例（仅示意结构）：

```go
package app

import (
	"context"
	"example/internal/domain/order"
)

type App struct {
	orderSvc order.Service
}

func (a *App) CreateOrder(ctx context.Context, req CreateOrderReq) (*OrderDTO, error) {
	cmd := toCreateOrderCommand(req)        // DTO -> domain command
	agg, err := a.orderSvc.Create(ctx, cmd) // 编排调用 domain
	if err != nil {
		return nil, wrapBizErr(err)
	}
	out := toOrderDTO(agg) // domain -> DTO
	return &out, nil
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

项目中立示例（仅示意结构）：

```go
package order

import "context"

type Repository interface {
	Save(ctx context.Context, agg *Aggregate) error
}

type Service interface {
	Create(ctx context.Context, cmd CreateCommand) (*Aggregate, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) Create(ctx context.Context, cmd CreateCommand) (*Aggregate, error) {
	if err := validateCreate(cmd); err != nil {
		return nil, err
	}
	agg, err := buildAggregate(cmd)
	if err != nil {
		return nil, err
	}
	if err := s.repo.Save(ctx, agg); err != nil {
		return nil, err
	}
	return agg, nil
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
func BuildHTTPServer(db *sql.DB) *gin.Engine {
	repo := orderrepo.New(db)
	svc := order.NewService(repo)
	h := handler.NewOrderHandler(svc)

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
