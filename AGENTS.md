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

# 1) 锁定目标子模块和分支（示例）
TARGET=q-deploy
BRANCH=main
ROOT_BRANCH=main

# 2) 同步目标子模块到远端最新
git submodule update --init --remote "$TARGET"
git -C "$TARGET" fetch origin
git -C "$TARGET" checkout "$BRANCH"
git -C "$TARGET" pull --ff-only origin "$BRANCH"

# 3) 仅在子模块内实现需求并完成验证（按模块文档执行）
# 例如：test/lint/build

# 4) 在子模块内提交并推送
git -C "$TARGET" add -A
git -C "$TARGET" commit -m "feat: xxx"
git -C "$TARGET" push origin "$BRANCH"

# 5) 回到主仓库提交 submodule 指针更新
git add "$TARGET"
git commit -m "chore: update $TARGET submodule reference"
git push origin "$ROOT_BRANCH"

# 6) 回填非-worktree主工作目录（必须执行）
# MAIN_REPO 为你的常驻主仓库目录（非 worktree）
MAIN_REPO=/Users/richer/richer/q-paas-studio
git -C "$MAIN_REPO" checkout "$ROOT_BRANCH"
git -C "$MAIN_REPO" pull --ff-only origin "$ROOT_BRANCH"
git -C "$MAIN_REPO" submodule sync --recursive
git -C "$MAIN_REPO" submodule update --init --recursive

# 7) 收尾校验（当前仓库与 MAIN_REPO 都应无未提交变更）
git status --short
git submodule status
git -C "$MAIN_REPO" status --short
git -C "$MAIN_REPO" submodule status
```

## Worktree 场景要求（重点）

在 `git worktree` 模式下，开发发生在哪个 worktree 不重要，关键是任务结束后必须回填非-worktree主工作目录。

强制要求：
1. 在工作用 worktree 完成子模块代码提交与主仓指针提交。
2. 立即执行上面流程第 6 步，回填 `MAIN_REPO`。
3. 以 `MAIN_REPO` 的 `status/submodule status` 结果作为“当前代码已最新”的最终依据。

推荐固定别名（可选）：
```bash
alias qsync-main='git -C /Users/richer/richer/q-paas-studio pull --ff-only origin main && git -C /Users/richer/richer/q-paas-studio submodule sync --recursive && git -C /Users/richer/richer/q-paas-studio submodule update --init --recursive'
```

## 关键边界（避免模棱两可）

1. **业务代码提交发生在子模块仓库**，不是主仓库。
2. **主仓库只提交“子模块指针变更”**（以及必要的主仓文档/配置变更）。
3. **不要在一次任务里混改多个子模块**，除非用户明确要求。
4. `q-infra` 不是子模块：修改 `q-infra` 时，不需要 submodule 指针提交流程。
5. **分支默认跟随用户指令**；用户未指定时，先确认是否使用 `main`。
6. **主仓或子模块如果是脏工作区，先报告当前状态再继续操作**。
7. **任务完成判定以非-worktree主工作目录（`MAIN_REPO`）为准**，不是以开发用 worktree 为准。

## Skill 使用判定规则（固定）

为避免流程过重或执行跑偏，按以下规则执行：

1. **小修小补：直接修改，不强制走 skill**。
2. **较大改动：必须先走 skill，再进入实现**。

判定标准：

- **小改（可直接改）**：单模块、少量文件、样式/文案/小交互微调，不涉及接口契约、数据模型、数据库迁移。
- **大改（必须走 skill）**：跨模块联动、涉及 API/数据库/数据模型、页面结构重做、流程新增、需要 worktree 分支联动。

执行要求：

- 开始动手前，先给出一句“**规模判定 + 原因**”。
- 若判定为大改，先进入对应 skill 流程（如 `brainstorming`、`using-git-worktrees`），完成后再编码。

## 知识库

开发前请阅读 `knowledge/` 目录下的文档，了解项目核心概念。

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
