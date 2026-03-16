# ============================================================
# Q-PaaS Infrastructure Makefile
# ============================================================

INFRA_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS   := $(INFRA_DIR)scripts

SERVICE ?=
MODE    ?= auto

# 构造脚本参数
ifdef SERVICE
  _SVC_ARG := --service $(SERVICE)
else
  _SVC_ARG := --service all
endif

ifneq ($(MODE),auto)
  _MODE_ARG := --mode $(MODE)
else
  _MODE_ARG :=
endif

.PHONY: infra-deploy infra-deploy-all infra-destroy infra-destroy-all infra-status infra-env infra-help infra-gitops

## 部署单个或指定服务：make infra-deploy SERVICE=jenkins [MODE=helm]
infra-deploy:
ifndef SERVICE
	$(error SERVICE is required. Usage: make infra-deploy SERVICE=jenkins|harbor|argocd|mysql|redis|postgresql|minio|kafka)
endif
	@bash $(SCRIPTS)/deploy.sh deploy --service $(SERVICE) $(_MODE_ARG)

## 部署全部基建服务
infra-deploy-all:
	@bash $(SCRIPTS)/deploy.sh deploy --service all $(_MODE_ARG)

## 销毁单个服务：make infra-destroy SERVICE=jenkins
infra-destroy:
ifndef SERVICE
	$(error SERVICE is required. Usage: make infra-destroy SERVICE=jenkins|harbor|argocd|mysql|redis|postgresql|minio|kafka)
endif
	@bash $(SCRIPTS)/deploy.sh destroy --service $(SERVICE) $(_MODE_ARG)

## 销毁全部基建服务
infra-destroy-all:
	@bash $(SCRIPTS)/deploy.sh destroy --service all $(_MODE_ARG)

## 查看服务状态：make infra-status [SERVICE=jenkins]
infra-status:
ifdef SERVICE
	@bash $(SCRIPTS)/status.sh $(SERVICE)
else
	@bash $(SCRIPTS)/status.sh all
endif

## 从模板初始化 .env 文件
infra-env:
	@if [ ! -f $(INFRA_DIR).env ]; then \
		cp $(INFRA_DIR)env/.env.example $(INFRA_DIR).env; \
		echo "Created .env from template. Please edit $(INFRA_DIR).env"; \
	else \
		echo ".env already exists at $(INFRA_DIR).env"; \
	fi

## 一键部署 GitOps 全流程（Jenkins + Harbor + ArgoCD）
infra-gitops:
	@bash $(SCRIPTS)/deploy-gitops.sh

## 显示帮助
infra-help:
	@echo ""
	@echo "Q-PaaS Infrastructure Management"
	@echo "================================="
	@echo ""
	@echo "  make infra-env                          Initialize .env from template"
	@echo "  make infra-deploy SERVICE=<name>        Deploy a service (jenkins|harbor|argocd|mysql|redis|postgresql|minio|kafka)"
	@echo "  make infra-deploy-all                   Deploy all infrastructure services"
	@echo "  make infra-status                       Check all services status"
	@echo "  make infra-status SERVICE=<name>        Check single service status"
	@echo "  make infra-destroy SERVICE=<name>       Destroy a service"
	@echo "  make infra-destroy-all                  Destroy all infrastructure services"
	@echo ""
	@echo "Options:"
	@echo "  MODE=compose|helm                       Force deploy mode (default: auto-detect)"
	@echo ""
