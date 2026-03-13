# GitOps CI/CD Framework Design

## Summary

Build a complete GitOps-oriented CI/CD demo flow on top of the existing submodule-based repository structure, centered on `q-infra`, `q-metahub`, `q-ci`, and `q-deploy`.

The flow must use:

- Mock business metadata stored in `q-metahub`
- A real GitHub application repository named `q-demo`
- A real GitHub GitOps repository named `q-demo-gitops`
- Real image build and push to local Harbor
- Real GitOps commit and ArgoCD sync into the local Kubernetes cluster currently reachable through `kubectl`

The orchestration model for this phase is:

- No standalone workflow service
- Each module exposes both HTTP/API and MCP tools
- The large model acts as the MCP client and coordinates the modules

## Goals

- Deliver one complete closed loop for one demo business unit in one `dev` environment
- Make each module own its domain capability instead of hiding logic in scripts
- Keep the orchestration surface AI-friendly through MCP tools
- Keep the underlying business surface reusable through HTTP APIs
- Make the flow repeatable, observable, and safe to rerun

## Non-Goals

- Multi-business-unit tenancy
- Multi-environment rollout beyond the initial `dev` environment
- GitHub webhook automation
- Argo Workflow integration in this phase
- A generalized UI for metadata management

## Constraints

- The local Kubernetes cluster is already available via `kubectl`
- The demo must use real GitHub repositories, not local-only mock repositories
- Build execution must be real: clone source, build container image, push to Harbor
- Release execution must be real: update GitOps repository, let ArgoCD sync to cluster
- The implementation should preserve clear module boundaries

## Architecture

### Module Responsibilities

`q-metahub` is the source of truth for deployment metadata.

It owns:

- Project
- BusinessUnit
- CIConfig
- CDConfig
- InstanceConfig
- DeployPlan

It must provide:

- CRUD-oriented HTTP APIs required for the demo setup
- Read APIs that return a complete deployable specification
- MCP tools for seed and query operations

`q-ci` owns build execution and build artifacts.

It must provide:

- A trigger-build HTTP API
- Artifact query APIs
- Domain logic that reads deployment metadata from `q-metahub`
- Real repository clone, image build, and Harbor push
- MCP tools for triggering and querying builds

`q-deploy` owns release execution and GitOps publication.

It must provide:

- A release execution HTTP API
- Release query APIs
- Logic that combines deploy plan metadata with build artifacts
- GitOps repository updates targeting `q-demo-gitops`
- MCP tools for executing and inspecting releases

`q-infra` owns the local platform dependencies and deployment support assets.

It must provide:

- Harbor, ArgoCD, and supporting infrastructure for the local demo
- Scripts and configuration needed to bootstrap and verify the platform

### Control Model

There is no dedicated orchestration service in this phase.

Instead:

- Each service exposes MCP tools for AI-driven control
- The large model connects to `q-metahub`, `q-ci`, and `q-deploy` MCP servers
- The large model coordinates the sequence end to end

HTTP APIs remain required because:

- They are the formal business interfaces of each module
- MCP tools should be thin wrappers over app/domain logic, not a separate implementation path
- Future non-MCP clients must be able to use the same capabilities

## Demo Topology

### GitHub Repositories

Two GitHub repositories are required:

- `q-demo`: application source repository
- `q-demo-gitops`: GitOps configuration repository

### Demo Business Shape

The initial delivery supports exactly one closed loop:

- One project
- One business unit
- One deploy plan
- One environment: `dev`

### GitOps Repository Layout

`q-demo-gitops` should use this structure:

```text
apps/
  q-demo-dev.yaml
manifests/
  q-demo/
    dev/
      deployment.yaml
      service.yaml
      configmap.yaml
```

This matches the existing `q-deploy` assumptions around:

- `AppRoot=apps`
- `ManifestRoot=manifests`

## Demo Data Model

### q-demo Source Repository

`q-demo` should be a small HTTP application that is cheap to build and easy to verify.

Required characteristics:

- A `Dockerfile`
- A `Makefile`
- A health endpoint such as `/healthz`
- A root endpoint returning service identity and version information

This keeps CI real while minimizing build complexity.

### q-metahub Mock Data

The seeded demo metadata should include:

Project:

- Name: `q-demo-project`
- Source repository: GitHub repository `q-demo`

BusinessUnit:

- Name: `q-demo`

CIConfig:

- Bound to the demo business unit
- Source reference set to branch `main`
- Dockerfile path set to `./Dockerfile`
- Make command set to `build`
- Image registry pointing to local Harbor
- Image repository set for the demo application

CDConfig:

- GitOps enabled
- GitOps repository set to `q-demo-gitops`
- Branch set to `main`
- `app_root=apps`
- `manifest_root=manifests`
- Release strategy set to rolling

InstanceConfig:

- Environment set to `dev`
- Workload type set to `Deployment`
- One application container exposing port `8080`
- A `Service` attached for in-cluster access

DeployPlan:

- Binds the CIConfig, CDConfig, and InstanceConfig into one deployable plan

## Required Runtime Flow

The target runtime sequence is:

1. AI calls `q-metahub` MCP tool to seed or retrieve the demo setup
2. `q-metahub` returns `business_unit_id` and `deploy_plan_id`
3. AI calls `q-ci` MCP tool to trigger a build using `deploy_plan_id`
4. `q-ci` loads plan data from `q-metahub`
5. `q-ci` clones `q-demo`, builds the image, and pushes it to Harbor
6. `q-ci` records a `BuildArtifact` and returns `artifact_id`
7. AI polls `q-ci` for artifact completion status
8. AI calls `q-deploy` MCP tool with `deploy_plan_id` and `artifact_id`
9. `q-deploy` renders manifests and ArgoCD `Application`
10. `q-deploy` commits and pushes changes to `q-demo-gitops`
11. ArgoCD detects the Git change and syncs to the local cluster
12. AI verifies application health in ArgoCD and Kubernetes

## API Design

### q-metahub HTTP/API

The demo requires these APIs:

- `POST /api/v1/projects`
- `POST /api/v1/business-units`
- `POST /api/v1/ci-configs`
- `POST /api/v1/cd-configs`
- `POST /api/v1/instance-configs`
- `POST /api/v1/deploy-plans`
- `GET /api/v1/deploy-plans/:id`
- `GET /api/v1/business-units/:id/full-spec`

The important read shape is a complete deployable specification that includes:

- project repository information
- business unit information
- CI config
- CD config
- instance config
- deploy plan identity

### q-ci HTTP/API

The demo requires these APIs:

- `POST /api/v1/builds/trigger`
- `GET /api/v1/artifacts/:id`
- `GET /api/v1/artifacts`

The trigger API should accept a minimal request based on `deploy_plan_id`.

`q-ci` is responsible for:

- loading the referenced plan data from `q-metahub`
- deriving build input from CIConfig and project metadata
- persisting the resulting artifact lifecycle

### q-deploy HTTP/API

The demo requires these APIs:

- `POST /api/v1/releases/execute`
- `GET /api/v1/releases/:id`

The execute API should accept:

- `deploy_plan_id`
- `artifact_id`

The service should resolve the rest of the required context itself through existing module boundaries.

## MCP Tool Design

### q-metahub MCP Tools

Required tools:

- `seed_demo_setup`
- `get_deploy_plan`
- `get_business_unit_full_spec`

`seed_demo_setup` must be idempotent.

It should either:

- create the demo records if they do not exist
- or return the existing demo records if they already exist

### q-ci MCP Tools

Required tools:

- `trigger_build`
- `get_artifact`
- `list_artifacts`

The MCP tools must return structured operation results, not only plain log text.

### q-deploy MCP Tools

Required tools:

- `execute_release`
- `get_release`

These tools should expose release identity plus GitOps output details such as:

- repository URL
- branch
- manifest path
- application path
- application name

## Build Execution Design

For this phase, build execution must be real.

That means:

- `q-ci` clones `q-demo` from GitHub
- the repository is built using the configured `Makefile` and `Dockerfile`
- the image is pushed to the local Harbor registry

The initial implementation can use the existing Jenkins-oriented shape where practical, but the externally visible behavior must be:

- trigger build
- observe running state
- observe success or failure
- retrieve the final image reference

The artifact record is the source of truth for build status.

## Release Execution Design

`q-deploy` must:

- resolve release inputs from deploy plan and build artifact
- render Kubernetes manifests using the existing render pipeline
- render an ArgoCD `Application`
- write both into `q-demo-gitops`
- commit and push the changes
- persist a release record in its own store

The GitOps repository becomes the deployment control plane for ArgoCD.

## Error Handling

### q-metahub

- Demo seeding must be idempotent
- Duplicate runs must not create duplicate demo records unless the model explicitly asks for a new dataset
- Query APIs must return precise not-found errors

### q-ci

Build failures must be attributed to a clear stage, at minimum:

- deploy plan lookup failure
- source clone failure
- build failure
- image push failure
- external trigger failure if Jenkins remains part of the execution path

On failure:

- `BuildArtifact` must move to a failed state
- the error message must be persisted

### q-deploy

Release failures must distinguish:

- deploy plan lookup failure
- artifact lookup failure
- render failure
- git write or push failure
- release persistence failure

The service must never return success if the GitOps commit did not complete.

## Observability

Each module must expose enough information for the AI operator to inspect progress without reading raw source code.

That includes:

- structured MCP tool responses
- HTTP responses with stable IDs and statuses
- persisted records for artifacts and releases
- log reading support, which already exists as `read_logs`

## Verification Strategy

### Automated Verification

The implementation must include runnable verification commands or scripts that prove:

1. Demo metadata can be seeded into `q-metahub`
2. A build can be triggered in `q-ci`
3. The resulting image appears in Harbor
4. A release can be executed in `q-deploy`
5. A new commit appears in `q-demo-gitops`
6. ArgoCD syncs the application
7. The Kubernetes workload becomes ready in the local cluster

### Test Coverage

At minimum:

- unit tests for new app/domain logic in `q-metahub`
- unit tests for new trigger-build logic in `q-ci`
- unit tests for new release execution flow in `q-deploy`
- integration-style verification scripts for the full loop

## Acceptance Criteria

The work is complete only when all of the following are true:

1. GitHub contains repositories named `q-demo` and `q-demo-gitops`
2. `q-metahub` can create and query the demo plan over HTTP and MCP
3. `q-ci` can trigger a real build from `deploy_plan_id` and push the image to local Harbor
4. `q-deploy` can execute a real GitOps release from `deploy_plan_id` and `artifact_id`
5. ArgoCD automatically syncs the resulting application to the local cluster
6. The deployed `q-demo` workload is reachable and healthy
7. The flow can be rerun without corrupting demo metadata

## Implementation Notes

The implementation should favor:

- thin HTTP handlers
- thin MCP tools
- app/domain services that hold the actual workflow logic
- explicit IDs and structured DTOs between layers

The implementation should avoid:

- putting orchestration logic into ad hoc shell-only flows
- duplicating business logic between HTTP and MCP
- adding a separate workflow service for this phase
