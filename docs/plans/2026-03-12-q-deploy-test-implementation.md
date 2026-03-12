# q-deploy App Layer Test Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add unit tests for app/deploy/app.go ExecuteDeployPlan method with dependency injection support.

**Architecture:** Refactor AppService to support dependency injection of engine and renderer factories, then write unit tests using fake objects to mock dependencies.

**Tech Stack:** Go 1.25, testing package, fake objects pattern (no external mock frameworks)

---

## Task 1: Refactor AppService to support dependency injection

**Files:**
- Modify: `q-deploy/app/deploy/app.go`

**Step 1: Add factory function fields to AppService**

Modify the AppService struct to include factory functions for engine and renderer creation:

```go
type AppService struct {
	engineFactory  func(cfg engine.Config, renderer render.Renderer, gitClient gitops.GitClient, releaseRepo gitops.ReleaseRepo) (engine.Engine, error)
	rendererFactory func(cfg render.Config) render.Renderer
}
```

**Step 2: Update NewAppService constructor**

Update the constructor to initialize factory functions with default implementations:

```go
func NewAppService() *AppService {
	return &AppService{
		engineFactory:  engine.New,
		rendererFactory: render.New,
	}
}
```

**Step 3: Update ExecuteDeployPlan to use injected factories**

Replace direct calls to `render.New()` and `engine.New()` with calls to the injected factory functions:

```go
renderer := s.rendererFactory(render.Config{Type: rendererType})

eng, err := s.engineFactory(cfg, renderer, gitclient.New(), nil)
```

**Step 4: Verify code compiles**

Run: `cd q-deploy && go build ./app/deploy`
Expected: Success (no compilation errors)

**Step 5: Commit refactoring**

```bash
cd q-deploy
git add app/deploy/app.go
git commit -m "refactor(app/deploy): add dependency injection support for testing

- Add engineFactory and rendererFactory fields to AppService
- Update NewAppService to initialize with default implementations
- Update ExecuteDeployPlan to use injected factories

This enables unit testing by allowing mock factories to be injected.

Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Create test file with fake engine

**Files:**
- Create: `q-deploy/app/deploy/app_test.go`

**Step 1: Write failing test skeleton**

Create the test file with package declaration and imports:

```go
package deploy

import (
	"context"
	"testing"

	"github.com/richer421/q-deploy/app/deploy/vo"
	"github.com/richer421/q-deploy/domain/engine"
	"github.com/richer421/q-deploy/domain/engine/gitops"
	"github.com/richer421/q-deploy/domain/render"
	rendermodel "github.com/richer421/q-deploy/domain/render/model"
)

// fakeEngine implements engine.Engine interface for testing
type fakeEngine struct {
	publishResult *gitops.ExecuteResult
	publishError  error
}

func (f *fakeEngine) Publish(ctx context.Context, in gitops.AppSpec) (*gitops.ExecuteResult, error) {
	if f.publishError != nil {
		return nil, f.publishError
	}
	return f.publishResult, nil
}

func TestExecuteDeployPlan_HappyPath(t *testing.T) {
	t.Fatal("test not implemented yet")
}
```

**Step 2: Run test to verify it fails**

Run: `cd q-deploy && go test ./app/deploy -v -run TestExecuteDeployPlan_HappyPath`
Expected: FAIL with "test not implemented yet"

**Step 3: Implement the test**

Replace the test body with full implementation:

```go
func TestExecuteDeployPlan_HappyPath(t *testing.T) {
	// Prepare test data
	cmd := &vo.ExecuteDeployPlanCmd{
		Plan: vo.DeployPlanSpec{
			BusinessUnitID: 1,
			PlanID:         2,
			CIConfig:       vo.CIConfigSpec{ConfigID: 3},
			CDConfig: vo.CDConfigSpec{
				ConfigID: 4,
				Strategy: rendermodel.ReleaseStrategy{
					DeploymentMode: "rolling",
					BatchRule: rendermodel.BatchRule{
						BatchCount:  3,
						BatchRatio:  []float64{0.1, 0.3, 0.6},
						TriggerType: "auto",
						Interval:    10,
					},
				},
			},
			InstanceConfig: vo.InstanceConfigSpec{
				ConfigID: 5,
				Spec: rendermodel.InstanceConfig{
					InstanceType: "deployment",
					Env:          "prod",
					Spec: map[string]any{
						"metadata": map[string]any{
							"name": "test-service",
							"labels": map[string]any{
								"project": "test-project",
							},
						},
					},
				},
			},
		},
		Artifact: vo.ArtifactSpec{
			ID:       6,
			ImageRef: "registry.example.com/project/service:v1",
		},
	}

	// Create fake engine with expected result
	fakeEng := &fakeEngine{
		publishResult: &gitops.ExecuteResult{
			ReleaseID: 42,
			GitOpsSnapshot: gitops.GitOpsSnapshot{
				RepoURL:      "https://github.com/example/gitops.git",
				Branch:       "main",
				ManifestPath: "manifests/test-project/prod/test-service",
				AppPath:      "apps/test-project/prod/test-service.yaml",
				AppName:      "test-project-test-service-prod",
			},
		},
	}

	// Create AppService with injected fake factory
	svc := &AppService{
		engineFactory: func(cfg engine.Config, renderer render.Renderer, gitClient gitops.GitClient, releaseRepo gitops.ReleaseRepo) (engine.Engine, error) {
			return fakeEng, nil
		},
		rendererFactory: func(cfg render.Config) render.Renderer {
			return nil // Not used in this test since fake engine doesn't call renderer
		},
	}

	// Execute test
	result, err := svc.ExecuteDeployPlan(context.Background(), cmd)

	// Verify results
	if err != nil {
		t.Fatalf("ExecuteDeployPlan returned error: %v", err)
	}
	if result == nil {
		t.Fatalf("ExecuteDeployPlan returned nil result")
	}
	if result.ReleaseID != 42 {
		t.Errorf("unexpected ReleaseID: got %d, want 42", result.ReleaseID)
	}
	if result.GitOps.RepoURL != "https://github.com/example/gitops.git" {
		t.Errorf("unexpected RepoURL: got %s, want https://github.com/example/gitops.git", result.GitOps.RepoURL)
	}
	if result.GitOps.Branch != "main" {
		t.Errorf("unexpected Branch: got %s, want main", result.GitOps.Branch)
	}
	if result.GitOps.ManifestPath != "manifests/test-project/prod/test-service" {
		t.Errorf("unexpected ManifestPath: got %s", result.GitOps.ManifestPath)
	}
	if result.GitOps.AppPath != "apps/test-project/prod/test-service.yaml" {
		t.Errorf("unexpected AppPath: got %s", result.GitOps.AppPath)
	}
	if result.GitOps.AppName != "test-project-test-service-prod" {
		t.Errorf("unexpected AppName: got %s", result.GitOps.AppName)
	}
}
```

**Step 4: Run test to verify it passes**

Run: `cd q-deploy && go test ./app/deploy -v -run TestExecuteDeployPlan_HappyPath`
Expected: PASS

**Step 5: Run all tests in the package**

Run: `cd q-deploy && go test ./app/deploy -v`
Expected: All tests PASS

**Step 6: Commit test**

```bash
cd q-deploy
git add app/deploy/app_test.go
git commit -m "test(app/deploy): add unit test for ExecuteDeployPlan happy path

- Implement fakeEngine to mock engine.Engine interface
- Test ExecuteDeployPlan with valid input
- Verify ReleaseDTO conversion is correct

Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Verify test coverage and update documentation

**Files:**
- Read: `q-deploy/app/deploy/app.go`
- Read: `q-deploy/app/deploy/app_test.go`

**Step 1: Run tests with coverage**

Run: `cd q-deploy && go test ./app/deploy -cover`
Expected: Coverage report showing test coverage for app.go

**Step 2: Verify all tests pass**

Run: `cd q-deploy && make test`
Expected: All tests in the project PASS

**Step 3: Update main repo to reference new q-deploy commit**

```bash
cd /Users/richer/richer/q-paas-studio
git add q-deploy
git commit -m "chore: update q-deploy reference - add app layer tests

Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Verification Checklist

- [ ] AppService refactored with dependency injection support
- [ ] Test file created with fakeEngine implementation
- [ ] TestExecuteDeployPlan_HappyPath passes
- [ ] All existing tests still pass
- [ ] Code follows project conventions (CLAUDE.md)
- [ ] Commits follow conventional commit format
- [ ] Main repo updated to reference new q-deploy commit

---

## Notes

- This implementation follows the existing test pattern from `domain/engine/gitops/engine_test.go`
- The fake object pattern is used instead of mock frameworks to maintain consistency
- Only the happy path is tested as specified in the design document
- Error handling tests and edge cases can be added in future iterations
