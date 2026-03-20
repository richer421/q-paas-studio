---
name: codex-submodule-worktree-best-practices
description: Use when development is driven by Codex, the repository is organized with git submodules, and branch development is executed through git worktree.
---

# Codex Submodule Worktree Best Practices

## 基本概念

1. 主项目：真实开发项目（非 worktree 常驻目录）。
2. worktree 项目：从主项目切出的工作副本，用于某个需求的隔离开发。
3. 子模块：主项目中的业务模块仓库（`q-ci`、`q-deploy`、`q-workflow`、`q-metahub`、`q-devops-platform`）。

## 规则

1. 分支统一：
主仓库和所有参与开发的子模块，必须使用同一个需求分支名，例如 `feat/xxx需求-20250320`。
2. 分支来源统一：
无论主仓库还是子模块，创建需求分支前都必须先同步并基于各自 `origin/main` 切出。
3. 新增模块同规则：
开发中途新增子模块时，也必须先从该模块 `origin/main` 切出同名需求分支。
4. 提交/推送与合并分离：
用户只说“提交、推送”时，只提交并推送当前需求分支，不主动合并 `main`。
5. 合并由用户触发：
只有用户明确说“合并 main 分支”时，才执行主仓库和相关子模块的 `main` 合并流程。
6. 合并后必须双更新：
合并完成后，不仅更新主仓库子模块指针，还要更新主项目中的子模块工作副本到最新 `main`。

## 流程

1. 初始化需求分支：
主仓库和目标子模块先 `fetch/pull origin main`，再切同名需求分支。
2. 需求开发：
只在需求分支上开发；中途新增模块时按同样规则补齐同名分支。
3. 提交与推送：
按用户指令提交并推送需求分支，不自动执行 main 合并。
4. 合并 main（仅用户明确要求时）：
先合并并推送各子模块 `main`，再回主仓库更新并提交子模块指针到主仓 `main`。
5. 主项目回填：
回到非 worktree 主项目目录，执行 `pull + submodule sync/update`，确保主项目与远端一致。
6. 结束校验：
以主项目（非 worktree）`status` 与 `submodule status` 作为最终完成依据。
