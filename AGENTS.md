# Q-PaaS Studio

PaaS 开发工作室（Codex 指南）

## 重要提示

**在明确要开发哪个模块之前，不要尝试阅读所有子模块的内容。** 这会消耗大量 token。应该先确认开发目标，再针对性地阅读相关模块。
**一次任务默认只处理一个模块。** 如果用户没有明确模块，先问清楚再开始。

## 项目结构

```text
q-paas-studio/                     # 项目根目录，所有路径基于此目录
├── knowledge/     # 知识库（主仓库内容）
├── q-ci/          # 持续集成服务（子模块）
├── q-deploy/      # 部署服务（子模块）
├── q-workflow/    # 工作流引擎服务（子模块）
├── q-metahub/     # 元数据中心服务（子模块）
├── q-devops-platform/ # DevOps 平台前端（子模块）
└── q-infra/       # 基建设施部署（主仓库目录，非子模块）
```

## 子模块远程仓库

| 子模块 | 远程仓库 |
|--------|----------|
| q-deploy | https://github.com/richer421/q-deploy.git |
| q-ci | https://github.com/richer421/q-ci.git |
| q-workflow | https://github.com/richer421/q-workflow.git |
| q-metahub | https://github.com/richer421/q-metahub.git |
| q-devops-platform | https://github.com/richer421/q-devops-platform.git |

说明：子模块清单以 `.gitmodules` 为准。

## AI 任务输入要求（必须明确）

给 Codex 下达任务时，至少包含这 4 点：
1. 目标模块（例如：`q-deploy`）。
2. 目标变更（修复什么/新增什么）。
3. 验收标准（测试、接口、页面效果）。
4. 是否允许跨模块改动（默认不允许）。

## Submodule + Worktree 说明（已收敛）

本文件不再维护 `submodule + worktree` 的细节流程（分支、合并、回填、校验）。
统一以项目内 skill 作为唯一执行规范：

- `.codex/skills/codex-submodule-worktree-best-practices/SKILL.md`

若与其它文档存在冲突，以该 skill 为准。

## 后端分层 Skill 入口

涉及后端 `app/domain` 分层设计、职责边界、业务编排落地时，统一先读取：

- `.codex/skills/codex-backend-layered-best-practices/SKILL.md`

## Skill 使用判定规则（固定）

为避免流程过重或执行跑偏，按以下规则执行：

1. **小修小补：可直接修改，不强制进入重流程 skill**。
2. **较大改动：必须先走 skill，再进入实现**。

判定标准：

- **小改（可直接改）**：单模块、少量文件、样式/文案/小交互微调，不涉及接口契约、数据模型、数据库迁移。
- **大改（必须走 skill）**：跨模块联动、涉及 API/数据库/数据模型、页面结构重做、流程新增、需要 worktree 分支联动。

执行要求：

- 开始动手前，先给出一句“**规模判定 + 原因**”。
- 若判定为大改，先进入对应 skill 流程（如 `brainstorming`、`using-git-worktrees`），完成后再编码。
- 若判定为小改，可不进入 `brainstorming`、`using-git-worktrees` 这类重流程 skill；但**平台基础要求、用户显式指定的 skill、以及任务明显匹配的专项 skill 仍需遵守**。

## 知识库

开发前请优先阅读 `knowledge/` 中**与当前目标模块、当前需求直接相关**的文档，了解项目核心概念。

- 若 `knowledge/` 中存在总览、索引、导航文档，优先先读这些文档。
- 不要求为了一次单模块任务通读整个 `knowledge/` 目录。

## 开发指南

如需开发某个子模块，请先阅读该模块目录下的 `CLAUDE.md`：
- `q-deploy/CLAUDE.md` - 部署服务开发指南
- `q-ci/CLAUDE.md` - 持续集成服务开发指南
- `q-workflow/CLAUDE.md` - 工作流引擎开发指南
- `q-metahub/CLAUDE.md` - 元数据中心开发指南
- `q-devops-platform/README.md` - DevOps 平台前端开发说明
- `q-infra/README.md` - 基建设施部署使用说明（纯配置项目，无 `CLAUDE.md`）

## 前端验收与测试策略

针对 `q-devops-platform`，默认按下面的优先级执行：

1. **业务流程或交互链路改动**：优先通过浏览器自动化 skill（Midscene）做真实页面验收，而不是先补低价值的 UI 测试。
2. **小型 UI 微调**：如果只是间距、文案、颜色、布局等轻量视觉改动，默认由用户在页面上直接确认，不强制补测试代码。
3. **保留自动化测试的场景**：仅在逻辑复杂、容易回归、且可以稳定低成本维护时再补前端测试。

明确禁止：

- 不要为了“看起来有测试”去补只会重复 DOM 结构或样式细节的无意义测试。
- 不要把浏览器真实验收本可以覆盖的前端联调链路，硬塞成脆弱的组件测试。

执行要求：

- 若通过 Midscene 做验收，完成后要把关键步骤、结果、截图/报告路径一并反馈给用户。
- 若判定为“小型 UI 微调”，直接说明“请用户页面确认”，不要额外制造测试负担。

## 提交规范

使用 Conventional Commits：`feat` / `fix` / `docs` / `refactor` / `chore`
