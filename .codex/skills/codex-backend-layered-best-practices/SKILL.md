---
name: codex-backend-layered-best-practices
description: Use when doing backend development tasks in this repository, including feature work, bugfixes, refactors, and service integration, so app/domain layering and business orchestration boundaries are always applied.
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
