.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
# ====================================================
INFO_COLOR := \033[36;1m
UI_COLOR := \033[35;1m
ERROR_COLOR := \033[31;1m
SUCCESS_COLOR := \033[32;1m
WARNING_COLOR := \033[33;1m
RESET_COLOR := \033[m
# ====================================================

.PHONY: check-tools check-list

check-tools:
	@for software in terraform ansible gh git aws; do
		if command -v "$$software" >/dev/null 2>&1; then
				echo -e "$(SUCCESS_COLOR) $$software present $(RESET_COLOR)"
		else
				if command --version "$$software"; then
					echo -e "$(SUCCESS_COLOR) $$software present $(RESET_COLOR)"
				else
					echo -e "$(ERROR_COLOR) $$software absent $(RESET_COLOR)"
				fi
		fi
	done


require-%:
	@[ command -v $($^)] || { "$(ERROR_COLOR) $$software $^ required $(RESET_COLOR)"; exit 1 }


help: ## shows this help
	@echo -e "\n$(UI_COLOR)=================MENU===========================$(RESET_COLOR)\n"
	@grep -hE "^[a-zA-Z_.-]+:.*?## .*$$" $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS=":.*?##"}{printf "$(INFO_COLOR)%-20s$(RESET_COLOR)%s\n", $$1, $$2}'
	@echo -e "\n$(UI_COLOR)==================END OF MENU================$(RESET_COLOR)\n"
