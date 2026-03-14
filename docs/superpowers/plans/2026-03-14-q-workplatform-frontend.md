# q-workplatform Frontend Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing `q-workplatform` Ant Design Pro/Umi frontend with a new React + Vite + Tailwind application that faithfully reproduces the current `Figmadesignpaas` UI and interactions with stronger code organization and baseline engineering tooling.

**Architecture:** Add `q-workplatform` to the main repository as a submodule, then do the frontend rebuild inside the submodule's own git worktree. Use a client-rendered React Router shell, central mock data, reusable UI primitives, page-specific business components, and test-first implementation for routing and key interactions.

**Tech Stack:** Git submodules, git worktrees, Node.js 22, pnpm 10, React 18.3.1, TypeScript 5, Vite 6.3.5, React Router 7.13.x, Tailwind CSS 3.4.19, Vitest, Testing Library, ESLint 9, Prettier, Docker, nginx

---

## Chunk 1: Repository Setup

### Task 1: Add `q-workplatform` as a submodule in the main repository

**Files:**
- Modify: `.gitmodules`
- Modify: git index entry for `q-workplatform`

- [ ] **Step 1: Confirm the main-repo worktree is clean enough to proceed**

Run: `git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend status --short`
Expected: no unrelated modifications inside the worktree

- [ ] **Step 2: Add the new submodule**

Run:

```bash
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend submodule add -b main https://github.com/richer421/q-workplatform.git q-workplatform
```

Expected:
- `.gitmodules` now contains `q-workplatform`
- `q-workplatform/` exists as a gitlink

- [ ] **Step 3: Sync and initialize the submodule**

Run:

```bash
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend submodule update --init --remote q-workplatform
```

Expected: submodule checked out to the latest `main`

- [ ] **Step 4: Verify submodule state**

Run:

```bash
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend submodule status
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend config -f .gitmodules --get-regexp '^submodule\\.q-workplatform\\.(path|url|branch)$'
```

Expected: `q-workplatform` appears with `branch = main`

- [ ] **Step 5: Commit the submodule addition**

```bash
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend add .gitmodules q-workplatform
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend commit -m "chore: add q-workplatform submodule"
```

### Task 2: Create a dedicated worktree for the `q-workplatform` submodule

**Files:**
- Create: `worktrees/q-workplatform-app/` (git worktree path outside the submodule repo history)

- [ ] **Step 1: Confirm the target worktree directory does not already exist**

Run: `test ! -e /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && echo ok`
Expected: `ok`

- [ ] **Step 2: Create a feature branch worktree for the submodule**

Run:

```bash
git -C /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend/q-workplatform worktree add /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app -b feat/frontend-rebuild
```

Expected:
- a new worktree exists at `/Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app`
- branch `feat/frontend-rebuild` is checked out there

- [ ] **Step 3: Install dependencies in the submodule worktree to establish the current baseline**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm install
```

Expected: dependencies install successfully

- [ ] **Step 4: Run the current baseline checks and record the result**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm test -- --runInBand
pnpm lint
```

Expected:
- either the current repo passes, or failures are recorded before replacement work begins
- note any failures in the implementation log before proceeding

## Chunk 2: Replace the Existing Frontend Scaffold

### Task 3: Remove the Ant Design Pro/Umi implementation

**Files:**
- Delete: legacy Umi/Antd project files inside `q-workplatform`

- [ ] **Step 1: Inventory the files to remove**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
rg --files . > /tmp/q-workplatform-before-rebuild-files.txt
```

Expected: inventory captured for review

- [ ] **Step 2: Write a failing smoke test that expects the new app shell route structure**

Create test file:
- `src/app/router/router.test.tsx`

Test sketch:

```tsx
it('redirects the root route to /business', async () => {
  expect(true).toBe(false);
});
```

- [ ] **Step 3: Run the targeted test and verify it fails**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm vitest run src/app/router/router.test.tsx
```

Expected: FAIL because the new router does not exist yet

- [ ] **Step 4: Remove the legacy scaffold**

Delete the existing app files that are specific to the old implementation, including:
- `src/pages/`
- `src/components/` legacy files
- `src/services/`
- `config/`
- `mock/`
- legacy test setup tied to Umi/Jest
- obsolete styles and generated type caches

Keep only assets that remain useful after review, such as logo or favicon files if they are still desired.

- [ ] **Step 5: Commit the legacy removal**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add -A
git commit -m "refactor: remove legacy antd pro frontend"
```

### Task 4: Scaffold the new Vite + React + TypeScript app

**Files:**
- Create: `package.json`
- Create: `pnpm-lock.yaml`
- Create: `tsconfig.json`
- Create: `tsconfig.node.json`
- Create: `vite.config.ts`
- Create: `index.html`
- Create: `src/main.tsx`
- Create: `src/vite-env.d.ts`

- [ ] **Step 1: Write a failing build command expectation**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm build
```

Expected: FAIL because the new Vite toolchain is not installed yet

- [ ] **Step 2: Create the new package manifest with explicit versions**

Include at minimum:

```json
{
  "name": "q-workplatform",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "packageManager": "pnpm@10",
  "engines": {
    "node": ">=22.0.0"
  }
}
```

Dependencies:
- `react@18.3.1`
- `react-dom@18.3.1`
- `react-router@7.13.x`
- `react-router-dom@7.13.x`
- `lucide-react`
- `clsx`

Dev dependencies:
- `vite@6.3.5`
- `@vitejs/plugin-react`
- `typescript`
- `tailwindcss@3.4.19`
- `postcss`
- `autoprefixer`
- `vitest`
- `jsdom`
- `@testing-library/react`
- `@testing-library/jest-dom`
- `eslint`
- `@eslint/js`
- `typescript-eslint`
- `eslint-plugin-react-hooks`
- `prettier`

- [ ] **Step 3: Create the base Vite entry files**

Create:
- `index.html`
- `src/main.tsx`
- `src/vite-env.d.ts`
- `tsconfig.json`
- `tsconfig.node.json`
- `vite.config.ts`

- [ ] **Step 4: Install dependencies**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm install
```

Expected: lockfile created and install succeeds

- [ ] **Step 5: Run build to verify the scaffold passes**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm build
```

Expected: PASS with a minimal app

- [ ] **Step 6: Commit the scaffold**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: scaffold vite react frontend"
```

## Chunk 3: Tooling and Engineering Baseline

### Task 5: Add Tailwind, shared styles, and app-level tokens

**Files:**
- Create: `tailwind.config.ts`
- Create: `postcss.config.js`
- Create: `src/styles/index.css`
- Create: `src/styles/tokens.css`
- Modify: `src/main.tsx`

- [ ] **Step 1: Write a failing style smoke test**

Create:
- `src/test/app-shell-style.test.tsx`

Test sketch:

```tsx
it('renders the shell background token class on the app root', () => {
  expect(document.body.innerHTML).toContain('bg-[#F2F3F5]');
});
```

- [ ] **Step 2: Run the targeted test and verify failure**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm vitest run src/test/app-shell-style.test.tsx
```

Expected: FAIL because the shell is not implemented yet

- [ ] **Step 3: Configure Tailwind and global stylesheet imports**

Use the style guide tokens:
- primary blue `#1664FF`
- hover blue `#0E50D3`
- text `#1D2129`
- border `#E5E6EB`
- content background `#F2F3F5`

- [ ] **Step 4: Verify CSS-aware build still passes**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm build`
Expected: PASS

### Task 6: Add linting, testing, formatting, Makefile, and Dockerfile

**Files:**
- Create: `eslint.config.js`
- Create: `vitest.config.ts`
- Create: `src/test/setup.ts`
- Create: `Makefile`
- Create: `Dockerfile`
- Create: `.dockerignore`
- Create: `.prettierrc.json`
- Modify: `package.json`
- Modify: `README.md`

- [ ] **Step 1: Add failing references to the missing tooling commands**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
make lint
```

Expected: FAIL because `Makefile` does not exist yet

- [ ] **Step 2: Add npm scripts**

Add scripts:
- `dev`
- `build`
- `preview`
- `lint`
- `test`
- `test:watch`

- [ ] **Step 3: Add ESLint and Vitest configuration**

Requirements:
- browser-aware TS linting
- React Hooks rules
- jsdom test environment
- Testing Library setup import

- [ ] **Step 4: Add Makefile targets**

Required targets:
- `install`
- `dev`
- `build`
- `lint`
- `test`
- `preview`
- `docker-build`

- [ ] **Step 5: Add Dockerfile**

Use:

```Dockerfile
FROM node:22-alpine AS build
...
FROM nginx:alpine
...
```

- [ ] **Step 6: Verify each engineering command**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
make lint
make test
make build
make docker-build
```

Expected: all commands PASS

- [ ] **Step 7: Commit the tooling baseline**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "chore: add frontend engineering baseline"
```

## Chunk 4: Routing and Shared Application Shell

### Task 7: Add app shell, navigation config, and router bootstrap

**Files:**
- Create: `src/app/router/index.tsx`
- Create: `src/app/router/routes.tsx`
- Create: `src/app/layout/AppShell.tsx`
- Create: `src/app/layout/SidebarNav.tsx`
- Create: `src/app/layout/navigation.ts`
- Create: `src/app/App.tsx`
- Modify: `src/main.tsx`
- Test: `src/app/router/router.test.tsx`

- [ ] **Step 1: Implement the previously failing router test fully**

Test cases:
- root redirects to `/business`
- `/cicd` renders the CI/CD navigation state
- unknown route renders not-found content

- [ ] **Step 2: Run the test and verify it fails for the right reason**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
pnpm vitest run src/app/router/router.test.tsx
```

Expected: FAIL because routes and shell components do not yet exist

- [ ] **Step 3: Implement the app shell and router**

Requirements:
- left sidebar width `220px`
- collapsed width `64px`
- main content shell background `#F2F3F5`
- nav items for `业务中心` and `CI&CD 工作台`
- active nav state mirrors the reference app

- [ ] **Step 4: Re-run router tests**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/app/router/router.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit the app shell**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add app shell and routing"
```

### Task 8: Add reusable UI primitives and status helpers

**Files:**
- Create: `src/components/ui/Button.tsx`
- Create: `src/components/ui/Card.tsx`
- Create: `src/components/ui/Badge.tsx`
- Create: `src/components/ui/PageHeader.tsx`
- Create: `src/components/ui/StatusIcon.tsx`
- Create: `src/components/ui/index.ts`
- Create: `src/lib/cn.ts`
- Create: `src/lib/status.ts`
- Test: `src/lib/status.test.ts`

- [ ] **Step 1: Write failing tests for status mappings**

Test cases:
- success state maps to green foreground and light green background
- failed state maps to red foreground and light red background
- running state preserves blue active color

- [ ] **Step 2: Run the targeted tests and confirm failure**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/lib/status.test.ts`
Expected: FAIL because helper file does not exist

- [ ] **Step 3: Implement the shared primitives and helpers**

Keep primitives small and prop-driven.

- [ ] **Step 4: Re-run targeted tests**

Expected: PASS

- [ ] **Step 5: Commit the shared primitives**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add shared ui primitives"
```

## Chunk 5: Business Pages

### Task 9: Implement central mock data for business and CI/CD domains

**Files:**
- Create: `src/data/business.ts`
- Create: `src/data/cicd.ts`
- Create: `src/data/index.ts`
- Test: `src/data/data-shape.test.ts`

- [ ] **Step 1: Write failing data-shape tests**

Test cases:
- business list contains at least three seeded business units
- build list contains both running and failed examples
- release list contains a deploying example

- [ ] **Step 2: Run the targeted test and verify failure**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/data/data-shape.test.ts`
Expected: FAIL because data modules do not exist

- [ ] **Step 3: Implement the data modules by extracting the reference content**

Keep content aligned with `Figmadesignpaas`.

- [ ] **Step 4: Re-run the targeted test**

Expected: PASS

- [ ] **Step 5: Commit the central data layer**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add mock platform data"
```

### Task 10: Implement the business list page with route navigation

**Files:**
- Create: `src/pages/business/BusinessListPage.tsx`
- Create: `src/components/business/BusinessToolbar.tsx`
- Create: `src/components/business/BusinessMetrics.tsx`
- Create: `src/components/business/BusinessTable.tsx`
- Modify: `src/app/router/routes.tsx`
- Test: `src/pages/business/BusinessListPage.test.tsx`

- [ ] **Step 1: Write failing route interaction tests**

Test cases:
- renders the business list by default
- clicking a business row or detail action navigates to `/business/:id`

- [ ] **Step 2: Run the targeted test and verify failure**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/pages/business/BusinessListPage.test.tsx`
Expected: FAIL

- [ ] **Step 3: Implement the business list page**

Requirements:
- match the reference spacing and table/card styling
- expose navigation into detail pages
- preserve the visible text and seeded data structure from the reference project

- [ ] **Step 4: Re-run the targeted test**

Expected: PASS

- [ ] **Step 5: Commit the business list page**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add business list page"
```

### Task 11: Implement the business detail page

**Files:**
- Create: `src/pages/business-detail/BusinessDetailPage.tsx`
- Create: `src/components/business/BusinessSummary.tsx`
- Create: `src/components/business/RepoCard.tsx`
- Create: `src/components/business/EnvStatusPanel.tsx`
- Create: `src/components/business/InstanceTable.tsx`
- Test: `src/pages/business-detail/BusinessDetailPage.test.tsx`

- [ ] **Step 1: Write failing detail-page tests**

Test cases:
- business detail route renders seeded business metadata
- invalid business id shows a not-found-like empty state within the shell

- [ ] **Step 2: Run the targeted test and verify failure**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/pages/business-detail/BusinessDetailPage.test.tsx`
Expected: FAIL

- [ ] **Step 3: Implement the detail page and supporting components**

Requirements:
- preserve the information layout and labels from the reference page
- derive child sections from the centralized data layer

- [ ] **Step 4: Re-run the targeted test**

Expected: PASS

- [ ] **Step 5: Commit the business detail page**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add business detail page"
```

## Chunk 6: CI/CD and Not Found Pages

### Task 12: Implement the CI/CD page with preserved interaction behavior

**Files:**
- Create: `src/pages/cicd/CicdPage.tsx`
- Create: `src/components/cicd/BuildList.tsx`
- Create: `src/components/cicd/BuildItem.tsx`
- Create: `src/components/cicd/BuildStepTimeline.tsx`
- Create: `src/components/cicd/DeployStagePanel.tsx`
- Create: `src/components/cicd/RolloutPreview.tsx`
- Create: `src/components/cicd/LogViewer.tsx`
- Test: `src/pages/cicd/CicdPage.test.tsx`

- [ ] **Step 1: Write failing interaction tests**

Test cases:
- seeded build records render
- clicking a build item expands stage or log details
- CI/CD route keeps the correct nav item active

- [ ] **Step 2: Run the targeted test and verify failure**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/pages/cicd/CicdPage.test.tsx`
Expected: FAIL

- [ ] **Step 3: Implement the CI/CD page and child components**

Requirements:
- preserve the reference interaction model
- keep visual fidelity for status icons, pills, cards, and log blocks
- split the original long file into focused components

- [ ] **Step 4: Re-run the targeted test**

Expected: PASS

- [ ] **Step 5: Commit the CI/CD page**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add cicd workbench page"
```

### Task 13: Implement the not-found page and route fallback

**Files:**
- Create: `src/pages/not-found/NotFoundPage.tsx`
- Modify: `src/app/router/routes.tsx`
- Test: `src/pages/not-found/NotFoundPage.test.tsx`

- [ ] **Step 1: Write a failing fallback test**

Test case:
- unknown route shows the not-found page content

- [ ] **Step 2: Run the targeted test and verify failure**

Run: `cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app && pnpm vitest run src/pages/not-found/NotFoundPage.test.tsx`
Expected: FAIL

- [ ] **Step 3: Implement the not-found page**

Keep the look aligned with the reference implementation.

- [ ] **Step 4: Re-run the targeted test**

Expected: PASS

- [ ] **Step 5: Commit the not-found page**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git add .
git commit -m "feat: add not-found page"
```

## Chunk 7: Verification and Integration

### Task 14: Run full verification inside the submodule worktree

**Files:**
- Read: all modified files for verification only

- [ ] **Step 1: Run full lint, test, and build**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
make lint
make test
make build
```

Expected: all PASS

- [ ] **Step 2: Build the container image**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
make docker-build
```

Expected: PASS

- [ ] **Step 3: Review git status and diff**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git status --short
git diff --stat origin/main...HEAD
```

Expected: only intended frontend rebuild changes are present

- [ ] **Step 4: Push the submodule branch**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-app
git push -u origin feat/frontend-rebuild
```

Expected: remote branch created successfully

### Task 15: Update the main repository to the new submodule revision

**Files:**
- Modify: submodule pointer for `q-workplatform`
- Modify: `.gitmodules` only if needed from the earlier submodule addition

- [ ] **Step 1: Refresh the submodule pointer in the main-repo worktree**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend
git status --short
git add q-workplatform
```

Expected: submodule pointer staged

- [ ] **Step 2: Commit the updated pointer**

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend
git commit -m "chore: update q-workplatform submodule"
```

- [ ] **Step 3: Verify the main-repo worktree state**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend
git status --short
git submodule status
```

Expected: clean worktree and updated `q-workplatform` SHA

- [ ] **Step 4: Push the main repository branch**

Run:

```bash
cd /Users/richer/richer/q-paas-studio/worktrees/q-workplatform-frontend
git push -u origin feat/q-workplatform-frontend
```

Expected: remote branch created successfully
