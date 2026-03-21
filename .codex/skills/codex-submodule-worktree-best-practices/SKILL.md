---
name: codex-submodule-worktree-best-practices
description: Use when working in this project with Codex, the repository uses git submodules, or any task involves worktree branches, branch switching, commit/push, merging main, or the project keyword “接收”.
---

# Codex Submodule Worktree Best Practices

## 优先级

这是本项目的高优先级流程 skill。

只要任务涉及以下任一场景，就必须优先使用本 skill，而不是按通用 git / worktree 习惯自行判断：

1. 在本项目中进行分支创建、切换、提交、推送、合并。
2. 在 worktree 中开发，或需要切回主项目目录执行 main 合并。
3. 用户明确说“接收”。
4. 处理子模块指针更新、子模块 main 合并、主项目回填。

项目关键词约定：

- **接收**：表示“提交当前工作分支改动、推送当前分支、按本 skill 切换到主项目目录合并 `main`、推送 `origin/main`，并完成最终状态校验”。
- 以后用户只要说“接收”，默认按上面的完整流程执行；除非用户明确缩小范围。

执行要求：

1. 命中上述场景时，必须先说明“正在按 `codex-submodule-worktree-best-practices` 执行”。
2. 必须先说明当前所在的是“worktree 项目”还是“主项目”。
3. 若要合并 `main`，必须明确说明为什么要切到主项目目录执行。
4. 若本 skill 与通用习惯冲突，以本 skill 为准；除非用户明确要求覆盖。

## 基本概念

1. 主项目：真实开发项目（非 worktree 常驻目录）。
2. worktree 项目：从主项目切出的工作副本，用于某个需求的隔离开发。
3. 子模块：主项目中通过 git submodule 管理的模块集合，以主仓 `.gitmodules` 为准，不硬编码模块名单。
4. 非子模块目录：如 `q-infra` 属于主仓普通目录，不走 submodule 指针提交流程。

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
只有用户明确说“合并 main 分支”或“接收”时，才执行主仓库和相关子模块的 `main` 合并流程。
6. 合并后必须双更新：
合并完成后，不仅更新主仓库子模块指针，还要更新主项目中的子模块工作副本到最新 `main`。
7. 执行前置说明必做：
凡是命中本 skill 的任务，开始执行前都必须先说明当前目录角色（主项目 / worktree 项目）、目标分支、以及是否会切换到主项目目录处理 `main`。

## 流程

1. 初始化需求分支：
主仓库和目标子模块先 `fetch/pull origin main`，再切同名需求分支。
2. 需求开发：
只在需求分支上开发；中途新增模块时按同样规则补齐同名分支。
3. 提交与推送：
按用户指令提交并推送需求分支，不自动执行 main 合并。
4. 合并 main / 接收（仅用户明确要求时）：
先合并并推送各子模块 `main`，再回主仓库更新并提交子模块指针到主仓 `main`。
5. 主项目回填：
回到非 worktree 主项目目录，执行 `pull + submodule sync/update`，确保主项目与远端一致。
6. 结束校验：
以主项目（非 worktree）`status` 与 `submodule status` 作为最终完成依据。
