---
name: submodule-worktree-release-guard
description: Use when working on q-paas-studio tasks that involve submodule + worktree delivery, integration branches, "update all modules", or any request that must guarantee each submodule is merged to origin/main, root pointers are pushed, and MAIN_REPO is fully backfilled.
---

# Submodule Worktree Release Guard

## Overview

Use this skill to avoid false completion in q-paas-studio release flows.
It enforces an evidence-first sequence: discover branch reality per module, merge the right branches, push remote mains, update root submodule pointers, and verify MAIN_REPO consistency before claiming done.

## Required Inputs

Before execution, lock these inputs:

1. `ROOT_REPO` (worktree path, usually current dir)
2. `MAIN_REPO` (must be `/Users/richer/richer/q-paas-studio`)
3. `ROOT_BRANCH` (example: `feat/integration-midscene`)
4. Module list (default: `q-ci q-deploy q-workflow q-devops-platform q-metahub`)

## Branch Discovery Rule (Do Not Assume)

Never assume all modules use the same integration branch name.

For each module, detect existing remote branch candidates in this order:
1. `origin/$ROOT_BRANCH`
2. `origin/test/${ROOT_BRANCH#feat/}`
3. Explicit branch name provided by user for that module

If none exists, mark `branch_exists=no` and report it explicitly.

## Execution Flow

### Step 0: Precheck (Both Repos)

Run and inspect:

```bash
git -C "$ROOT_REPO" status --short
git -C "$ROOT_REPO" submodule status
git -C "$MAIN_REPO" status --short
git -C "$MAIN_REPO" submodule status
```

If dirty state exists, report it first. Do not hide it.

### Step 1: Merge Integration Branches in Submodules

For each module with existing integration branch:

```bash
git -C "$m" fetch origin --prune
git -C "$m" checkout main
git -C "$m" pull --ff-only origin main
# use resolved branch name: $BR
git -C "$m" merge --no-ff "origin/$BR" -m "merge: integrate $BR"
git -C "$m" push origin main
```

### Step 2: Merge Root Integration Branch (If Present)

```bash
git -C "$ROOT_REPO" fetch origin --prune
git -C "$ROOT_REPO" checkout main
git -C "$ROOT_REPO" pull --ff-only origin main
git -C "$ROOT_REPO" merge --no-ff "origin/$ROOT_BRANCH" -m "merge: integrate $ROOT_BRANCH"
```

If root branch does not exist, report `root_branch_exists=no`.

### Step 3: Refresh Root Submodule Pointers and Push

After submodule merges:

```bash
for m in q-ci q-deploy q-workflow q-devops-platform q-metahub; do
  git -C "$ROOT_REPO/$m" fetch origin --prune
  git -C "$ROOT_REPO/$m" checkout main
  git -C "$ROOT_REPO/$m" pull --ff-only origin main
done

git -C "$ROOT_REPO" add q-ci q-deploy q-workflow q-devops-platform q-metahub
git -C "$ROOT_REPO" commit -m "chore: refresh submodule references after integration merges" || true
git -C "$ROOT_REPO" push origin main
```

### Step 4: Backfill MAIN_REPO (Mandatory)

```bash
git -C "$MAIN_REPO" checkout main
git -C "$MAIN_REPO" pull --ff-only origin main
git -C "$MAIN_REPO" submodule sync --recursive
git -C "$MAIN_REPO" submodule update --init --recursive
```

## Mandatory Verification (Evidence Before Claim)

Run and report these exact checks:

```bash
# 1) branch inclusion check (must be 0 for each relevant branch)
git -C "$module" rev-list --count origin/main..origin/$BR

# 2) module freshness check (must be behind=0 ahead=0)
git -C "$module" rev-list --count HEAD..origin/main
git -C "$module" rev-list --count origin/main..HEAD

# 3) dual-repo clean checks
git -C "$ROOT_REPO" status --short
git -C "$MAIN_REPO" status --short
```

Do not say "completed" until all required checks pass.

## Output Format

Always provide:
1. Which branch was detected per module
2. Which modules were merged and pushed
3. Root commit pushed on `origin/main`
4. Final pointer commits for all modules in `MAIN_REPO`
5. Any module without target branch (explicit `not_found`)

## Red Flags

- Running `git submodule update --remote` and claiming branch merge is complete
- Assuming all modules use `feat/...` while some use `test/...`
- Verifying only worktree but not `MAIN_REPO`
- Claiming success without `rev-list` numeric evidence
