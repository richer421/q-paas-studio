SHELL := /bin/bash

FRONTEND_MODULE := q-devops-platform
BACKEND_MODULES := q-ci q-deploy q-workflow q-metahub

# Backend default sub-command for air (can override: make dev-ci CMD=worker)
CMD ?= server

.PHONY: help dev-frontend dev-backend dev-ci dev-deploy dev-workflow dev-metahub

help:
	@echo "Q-PaaS Studio Debug Makefile"
	@echo ""
	@echo "Frontend (debug):"
	@echo "  make dev-frontend"
	@echo ""
	@echo "Backend (air hot-reload):"
	@echo "  make dev-ci [CMD=server]"
	@echo "  make dev-deploy [CMD=server]"
	@echo "  make dev-workflow [CMD=server]"
	@echo "  make dev-metahub [CMD=server]"
	@echo ""
	@echo "Generic backend launcher:"
	@echo "  make dev-backend MODULE=<q-ci|q-deploy|q-workflow|q-metahub> [CMD=server]"

dev-frontend:
	$(MAKE) -C $(FRONTEND_MODULE) dev

dev-ci:
	$(MAKE) -C q-ci dev CMD=$(CMD)

dev-deploy:
	$(MAKE) -C q-deploy dev CMD=$(CMD)

dev-workflow:
	$(MAKE) -C q-workflow dev CMD=$(CMD)

dev-metahub:
	$(MAKE) -C q-metahub dev CMD=$(CMD)

dev-backend:
	@if [ -z "$(MODULE)" ]; then \
		echo "Error: MODULE is required."; \
		echo "Usage: make dev-backend MODULE=<q-ci|q-deploy|q-workflow|q-metahub> [CMD=server]"; \
		exit 1; \
	fi
	@if [[ " $(BACKEND_MODULES) " != *" $(MODULE) "* ]]; then \
		echo "Error: invalid MODULE '$(MODULE)'."; \
		echo "Allowed: $(BACKEND_MODULES)"; \
		exit 1; \
	fi
	$(MAKE) -C $(MODULE) dev CMD=$(CMD)
