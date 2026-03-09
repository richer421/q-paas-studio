# Q-PaaS Studio

PaaS 开发工作室

## 项目结构

```
q-paas-studio/
├── knowledge/     # 知识库（主仓库内容）
├── q-deploy/      # 部署服务（子模块）
├── q-ci/          # 持续集成服务（子模块）
├── q-workflow/    # 工作流引擎服务（子模块）
└── q-metahub/     # 元数据中心服务（子模块）
```

## Git Submodule 工作模式

本项目采用 Git Submodule 组织，每个子模块是**独立的 Git 仓库**：

| 子模块 | 远程仓库 |
|--------|----------|
| q-deploy | https://github.com/richer421/q-deploy.git |
| q-ci | https://github.com/richer421/q-ci.git |
| q-workflow | https://github.com/richer421/q-workflow.git |
| q-metahub | https://github.com/richer421/q-metahub.git |

### 工作规则

1. **子模块是独立仓库**：内容从各自的远程仓库管理，不在主仓库中直接修改
2. **主仓库只保存引用**：主仓库记录子模块的 commit hash，不保存子模块内容
3. **修改子模块**：在子模块目录内 commit & push，然后在主仓库更新引用

### 常用命令

```bash
# 初始化所有子模块
git submodule update --init --recursive

# 更新子模块到最新
git submodule update --remote

# 修改子模块后，更新主仓库引用
git add <submodule-path>
git commit -m "chore: update <submodule> reference"
```

## 知识库

开发前请阅读 `knowledge/` 目录下的文档，了解项目核心概念。

## 提交规范

使用 Conventional Commits：`feat` / `fix` / `docs` / `refactor` / `chore`
