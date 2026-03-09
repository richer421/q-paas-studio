# Q-PaaS Studio

PaaS 开发工作室

## 重要提示

**在明确要开发哪个模块之前，不要尝试阅读所有子模块的内容。** 这会消耗大量 token。应该先确认开发目标，再针对性地阅读相关模块。

## 项目结构

```
q-paas-studio/
├── knowledge/     # 知识库（主仓库内容）
├── q-deploy/      # 部署服务（子模块）
├── q-ci/          # 持续集成服务（子模块）
├── q-workflow/    # 工作流引擎服务（子模块）
└── q-metahub/     # 元数据中心服务（子模块）
```

## 子模块远程仓库

| 子模块 | 远程仓库 |
|--------|----------|
| q-deploy | https://github.com/richer421/q-deploy.git |
| q-ci | https://github.com/richer421/q-ci.git |
| q-workflow | https://github.com/richer421/q-workflow.git |
| q-metahub | https://github.com/richer421/q-metahub.git |

## 子模块开发流程

1. **开发前先更新**：开发某个子模块前，必须先执行 `git submodule update --init --remote <submodule>` 同步最新内容
2. **直接在子模块目录内开发**：提交、推送，然后更新主仓库引用

```bash
# 1. 开发前先更新子模块
git submodule update --init --remote <submodule>

# 2. 进入子模块目录开发
cd <submodule>

# 3. 在子模块内提交并推送
git add . && git commit -m "feat: xxx"
git push origin main

# 4. 回到主仓库，更新子模块引用
cd ..
git add <submodule>
git commit -m "chore: update <submodule> reference"
git push origin main
```

## 知识库

开发前请阅读 `knowledge/` 目录下的文档，了解项目核心概念。

## 开发指南

如需开发某个子模块，请先阅读该模块目录下的 `CLAUDE.md`：
- `q-deploy/CLAUDE.md` — 部署服务开发指南
- `q-ci/CLAUDE.md` — 持续集成服务开发指南
- `q-workflow/CLAUDE.md` — 工作流引擎开发指南
- `q-metahub/CLAUDE.md` — 元数据中心开发指南

## 提交规范

使用 Conventional Commits：`feat` / `fix` / `docs` / `refactor` / `chore`
