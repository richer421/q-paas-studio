# q-workplatform Frontend Design

## Summary

Build `q-workplatform` as a new frontend submodule under `q-paas-studio`, replacing the remote repository's existing Ant Design Pro/Umi codebase with a fresh `React + TypeScript + Vite + Tailwind` implementation.

The first version is a high-fidelity frontend rebuild of the existing `Figmadesignpaas` UI. Visual style, route behavior, and page interaction patterns must remain consistent with the reference project, while the codebase is reorganized into clearer React page, component, data, and app-shell boundaries.

This phase does not integrate any backend APIs.

## Goals

- Replace the current `q-workplatform` frontend code entirely.
- Preserve the current `Figmadesignpaas` visual language.
- Preserve route transitions and page-level interaction behavior.
- Rebuild the frontend with clearer React structure and stronger engineering discipline.
- Add baseline engineering assets required for local development, CI, and containerized delivery.

## Non-Goals

- Backend integration
- Authentication and authorization flows
- Reinterpreting the information architecture
- Visual redesign beyond code-quality-driven implementation cleanup
- Introducing global state libraries without immediate need

## Constraints

- `q-workplatform` remains an independently versioned submodule repository.
- Development must happen in an isolated git worktree.
- The existing Ant Design Pro/Umi implementation is discarded rather than incrementally migrated.
- UI must remain aligned with `Figmadesignpaas`, not merely inspired by it.
- The route structure and interactive behavior from the reference implementation must be kept.

## Recommended Technical Stack

- Node.js `22 LTS`
- pnpm `10.x`
- React `18.3.1`
- TypeScript `5.x`
- Vite `6.3.5`
- React Router `7.13.x`
- Tailwind CSS `3.4.19`
- Vitest + Testing Library + jsdom
- ESLint `9` + `typescript-eslint` + `eslint-plugin-react-hooks`
- Prettier
- Makefile
- Dockerfile + nginx runtime image

## Tailwind Version Decision

Tailwind CSS v4 is already on a stable release line, but this project values conservative maintainability over adopting the newest styling model. Tailwind CSS `3.4.19` is the preferred choice for this implementation because it is mature, predictable, and matches the utility-first authoring style already present in the reference UI.

## Architecture

### Repository and Delivery Model

- Add `q-workplatform` as a new submodule in the main `q-paas-studio` repository.
- Update the submodule before development.
- Create a dedicated git worktree for `q-workplatform` feature development.
- Push the rebuilt frontend to the `q-workplatform` remote repository.
- Return to the main repository and commit the updated submodule pointer.

### Application Structure

Use a client-rendered SPA structure with React Router:

- `/business`
- `/business/:id`
- `/cicd`
- `*`

Default entry redirects to `/business`.

The shell structure matches the reference app:

- left sidebar
- top-level main content container
- page-level independent scrolling
- collapsible navigation

### Code Organization

```text
q-workplatform/
├── public/
├── src/
│   ├── app/
│   │   ├── layout/
│   │   ├── providers/
│   │   └── router/
│   ├── components/
│   │   ├── business/
│   │   ├── cicd/
│   │   ├── shared/
│   │   └── ui/
│   ├── data/
│   ├── lib/
│   ├── pages/
│   │   ├── business/
│   │   ├── business-detail/
│   │   ├── cicd/
│   │   └── not-found/
│   ├── styles/
│   ├── test/
│   ├── main.tsx
│   └── vite-env.d.ts
├── Dockerfile
├── Makefile
├── eslint.config.js
├── package.json
├── tsconfig.json
├── vite.config.ts
└── vitest.config.ts
```

### Boundaries

- `pages/` assembles screen-level composition only.
- `components/ui/` holds reusable primitives such as button, card, badge, table shell, and status display.
- `components/business/` and `components/cicd/` hold domain-specific UI blocks.
- `data/` holds mock data and domain types.
- `lib/` holds pure helpers and mappings.
- `app/layout/` contains shell and navigation logic.
- `app/router/` contains route declarations and router bootstrap.

## UI and Interaction Requirements

### Visual Fidelity

The application must visually match the current `Figmadesignpaas` implementation:

- enterprise console density
- white primary surfaces
- blue primary action color
- neutral gray borders and separators
- compact card spacing
- restrained hover feedback
- consistent status colors and pills

The visual target is fidelity, not reinterpretation.

### Interaction Fidelity

The rebuilt frontend must preserve reference behavior including:

- default redirect to `/business`
- sidebar route switching between business center and CI/CD workbench
- navigation highlight behavior
- sidebar collapse and expand interaction
- business list to detail navigation
- CI/CD build item expansion and collapse
- deployment stage and log display interactions
- 404 fallback routing

## Page Plan

### Business List

Responsibility:

- business overview landing page
- summary metrics
- search/filter toolbar
- business table with navigation to detail

Expected decomposition:

- `BusinessListPage`
- `BusinessToolbar`
- `BusinessMetrics`
- `BusinessTable`

### Business Detail

Responsibility:

- business summary
- repository and delivery metadata
- environment and deployment status
- instance/resource display

Expected decomposition:

- `BusinessDetailPage`
- `BusinessSummary`
- `RepoCard`
- `EnvStatusPanel`
- `InstanceTable`

### CI/CD

Responsibility:

- build list
- build state indicators
- build step timeline
- log viewer
- release and rollout stage display

Expected decomposition:

- `CicdPage`
- `BuildList`
- `BuildItem`
- `BuildStepTimeline`
- `DeployStagePanel`
- `RolloutPreview`
- `LogViewer`

### Not Found

Responsibility:

- route fallback
- consistent shell-compatible empty/error state

## Engineering Requirements

### Tooling

Add a `Makefile` with at least:

- `install`
- `dev`
- `build`
- `lint`
- `test`
- `preview`
- `docker-build`

Add a production `Dockerfile` using multi-stage build:

- build stage: `node:22-alpine`
- runtime stage: `nginx:alpine`

### Quality Rules

- Prefer Tailwind utility classes over scattered inline styles.
- Centralize status-to-color and status-to-label mappings.
- Avoid `any` unless there is no practical typed alternative.
- Keep page files focused on composition, not low-level rendering detail.
- Extract repeated UI patterns before copying them across pages.
- Favor prop-driven components and pure helper functions.

### Testing

Use test-first implementation for new code.

Minimum initial coverage:

- redirect to `/business`
- sidebar navigation route switching
- business list navigation to business detail
- CI/CD expand or collapse interactions
- not-found route rendering
- pure helper mappings for status presentation

## Delivery Sequence

1. Add or sync the `q-workplatform` submodule.
2. Create an isolated worktree for the feature branch.
3. Remove the existing Ant Design Pro/Umi implementation.
4. Scaffold the new Vite + React + TypeScript app.
5. Add Tailwind, linting, testing, Makefile, and Dockerfile.
6. Build the shared shell and route foundation.
7. Recreate the reference pages with componentized structure.
8. Verify tests, lint, and production build.
9. Push `q-workplatform` changes to its remote.
10. Commit the updated submodule reference in the main repository.

## Risks and Mitigations

- Risk: behavior drift while refactoring large page files
  - Mitigation: keep routing and interactions under test before broader cleanup
- Risk: visual mismatch despite matching data and structure
  - Mitigation: compare against the reference project page by page and preserve tokens, spacing, and layout rhythm
- Risk: over-abstracting too early
  - Mitigation: extract only repeated patterns that appear in multiple places

## Definition of Done

- `q-workplatform` no longer contains Ant Design Pro/Umi code
- new frontend stack is in place and documented
- the reference UI is visually matched for the first route set
- page transitions and key interactions are preserved
- `make dev`, `make build`, `make lint`, `make test`, and `make docker-build` work
- Docker image builds successfully
- remote repository is updated
- main repository submodule pointer is updated
