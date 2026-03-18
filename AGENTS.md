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

## Submodule + AI 标准开发流程（强约束）

```bash
# 0) 在主仓库确认状态（若已有未提交改动，先停下来确认是否继续）
git status --short
git submodule status

# 1) 锁定目标子模块和需求分支（示例）
TARGET=q-deploy
REQ=fix-deploy-pagination
BRANCH=fix/$REQ
ROOT_BRANCH=main

# 2) 同步目标子模块 main 到远端最新，并从 main 拉出需求分支
git submodule update --init --remote "$TARGET"
git -C "$TARGET" fetch origin
git -C "$TARGET" checkout main
git -C "$TARGET" pull --ff-only origin main
git -C "$TARGET" checkout -B "$BRANCH"

# 3) 仅在子模块内实现需求并完成验证（按模块文档执行）
# 例如：test/lint/build

# 4) 在子模块需求分支内提交并推送到远端同名分支
git -C "$TARGET" add -A
git -C "$TARGET" commit -m "feat: xxx"
git -C "$TARGET" push origin "$BRANCH"

# 5) 将子模块需求分支合并回 main，并推送 main
git -C "$TARGET" checkout main
git -C "$TARGET" pull --ff-only origin main
git -C "$TARGET" merge --no-ff "$BRANCH"
git -C "$TARGET" push origin main

# 6) 回到主仓库 main，提交 submodule 指针更新
git checkout main
git pull --ff-only origin main
git submodule update --init "$TARGET"
git add "$TARGET"
git commit -m "chore: update $TARGET submodule reference"
git push origin "$ROOT_BRANCH"

# 7) 回填非-worktree主工作目录（必须执行）
# MAIN_REPO 为你的常驻主仓库目录（非 worktree）
MAIN_REPO=/Users/richer/richer/q-paas-studio
git -C "$MAIN_REPO" checkout "$ROOT_BRANCH"
git -C "$MAIN_REPO" pull --ff-only origin "$ROOT_BRANCH"
git -C "$MAIN_REPO" submodule sync --recursive
git -C "$MAIN_REPO" submodule update --init --recursive

# 8) 收尾校验（当前仓库与 MAIN_REPO 都应无未提交变更）
git status --short
git submodule status
git -C "$MAIN_REPO" status --short
git -C "$MAIN_REPO" submodule status
```

## Worktree 场景要求（重点）

在 `git worktree` 模式下，开发发生在哪个 worktree 不重要，关键是任务结束后必须回填非-worktree主工作目录。

强制要求：
1. 在工作用 worktree 完成子模块需求分支开发、子模块 `main` 合并，以及主仓 `main` 的指针提交。
2. 立即执行上面流程第 7 步，回填 `MAIN_REPO`。
3. 以 `MAIN_REPO` 的 `status/submodule status` 结果作为“当前代码已最新”的最终依据。

推荐固定别名（可选）：
```bash
alias qsync-main='git -C /Users/richer/richer/q-paas-studio pull --ff-only origin main && git -C /Users/richer/richer/q-paas-studio submodule sync --recursive && git -C /Users/richer/richer/q-paas-studio submodule update --init --recursive'
```

## 需求与分支管理方案

在当前 `worktree + submodule` 模式下，需求和分支按以下固定方案执行，不使用“推荐策略”或临时约定。

固定规则：

1. **一个任务先绑定一个需求标识**，再开始建分支。需求标识可以是需求名、Issue 编号、工单号，例如 `deploy-env-sync`、`REQ-142`。
2. **worktree 目录名只是工作载体，不是最终交付依据**。真正需要对齐的是“目标模块 + 需求标识 + 分支名”。
3. **业务开发分支只存在于目标子模块**。主仓远程只追踪 `main`，不建立用于交付的主仓需求分支。
4. **子模块完成开发后，必须先把需求分支合并回子模块 `main` 并推送远端 `main`，然后主仓才能更新 submodule 指针并推送主仓 `main`。**
5. **不允许主干直接改业务代码**。业务改动统一先进入子模块需求分支，再合并回子模块 `main`。
6. **用户若明确指定子模块分支名，则使用该分支名；未指定时，统一按本文档命名规范创建分支。**

命名规范：

- 子模块分支：`feat/<需求标识>`、`fix/<需求标识>`、`chore/<需求标识>`
- 主仓远程分支：固定为 `main`
- worktree 本地目录：`../wt-<模块名>-<需求标识>`

执行顺序：

1. 先确认 **目标模块**。
2. 再确认 **需求标识/需求名**。
3. 在目标子模块从 `main` 创建对应需求分支。
4. 在该需求分支内完成开发、验证、提交，并推送到远端同名分支。
5. 将该需求分支合并回子模块 `main`，并推送子模块远端 `main`。
6. 回到主仓 `main` 更新 submodule 指针并推送主仓远端 `main`。
7. 最后回填 `MAIN_REPO`，并以 `MAIN_REPO` 状态作为完成依据。

示例：

```bash
# 需求：修复 q-deploy 中的发布记录分页问题
TARGET=q-deploy
REQ=deploy-pagination
BRANCH=fix/$REQ
ROOT_BRANCH=main

# 工作用目录围绕同一需求标识命名；主仓最终仍只提交到 main
git worktree add ../wt-$TARGET-$REQ
git -C "$TARGET" checkout main
git -C "$TARGET" pull --ff-only origin main
git -C "$TARGET" checkout -b "$BRANCH"
```

## 关键边界（避免模棱两可）

1. **业务代码提交发生在子模块仓库**，不是主仓库。
2. **主仓库只提交“子模块指针变更”**（以及必要的主仓文档/配置变更）。
3. **不要在一次任务里混改多个子模块**，除非用户明确要求。
4. `q-infra` 不是子模块：修改 `q-infra` 时，不需要 submodule 指针提交流程。
5. **主仓远程分支固定为 `main`；子模块若未指定分支，则按需求类型创建 `feat/<需求标识>`、`fix/<需求标识>` 或 `chore/<需求标识>`。**
6. **主仓或子模块如果是脏工作区，先报告当前状态再继续操作**。
7. **任务完成判定以非-worktree主工作目录（`MAIN_REPO`）为准**，不是以开发用 worktree 为准。

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
