.ONESHELL:
SHELL := /usr/bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
INFO_COLOR := \033[36;1m
ERROR_COLOR := \033[31;1m
SUCCESS_COLOR := \033[32;1m
WARNING_COLOR := \033[33;1m
RESET_COLOR := \033[m

.PHONY: check-tools
check-tools:
	@for software in pre-commit terraform ansible gh gitaws; do
			command -v "$$software" >/dev/null 2>&1 ||\
				{ echo -e "$(ERROR_COLOR)software $$software does not exist$(RESET_COLOR)"; \
			exit 1; }
	done


tf.init: ## dry-run terraform init
	@echo "Terraform init"

help: ## Show this help message
	@echo -e "\n$(INFO_COLOR)===================================== MENU ==================$(RESET_COLOR)\n"
	@grep -hE "^[a-zA-Z_.-]+:.*?## .*$$" $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS=":.*?##"}{printf "$(INFO_COLOR)%-20s$(RESET_COLOR)%s\n", $$1, $$2}'
	@echo -e "\n${INFO_COLOR}========================== END OF MENU ====================${RESET_COLOR}\n"


