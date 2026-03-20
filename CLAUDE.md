# Q-PaaS Studio

PaaS 开发工作室

## 重要提示

**在明确要开发哪个模块之前，不要尝试阅读所有子模块的内容。** 这会消耗大量 token。应该先确认开发目标，再针对性地阅读相关模块。

## 项目结构

```
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

## Submodule + Worktree 流程入口

涉及 `submodule + worktree` 的开发、提交、推送、合并、主项目回填，不在本文件维护细节流程。
统一以项目内 skill 为唯一执行依据：

- `.codex/skills/codex-submodule-worktree-best-practices/SKILL.md`

## 后端分层流程入口

涉及后端 `app/domain` 分层设计与编码时，统一先读取：

- `.codex/skills/codex-backend-layered-best-practices/SKILL.md`

## 知识库

开发前请阅读 `knowledge/` 目录下的文档，了解项目核心概念。

## 开发指南

如需开发某个子模块，请先阅读该模块目录下的 `CLAUDE.md`：
- `q-deploy/CLAUDE.md` — 部署服务开发指南
- `q-ci/CLAUDE.md` — 持续集成服务开发指南
- `q-workflow/CLAUDE.md` — 工作流引擎开发指南
- `q-metahub/CLAUDE.md` — 元数据中心开发指南
- `q-devops-platform/CLAUDE.md` — DevOps 平台前端开发指南
- `q-infra/README.md` — 基建设施部署使用说明（纯配置项目，无 CLAUDE.md）

## 提交规范

使用 Conventional Commits：`feat` / `fix` / `docs` / `refactor` / `chore`
