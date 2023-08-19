SHELL := /bin/bash

# Allows user to specify private hostname in ".inventory file"
PRIVATE_INVENTORY = ".inventory"
ifeq ($(shell test -e $(PRIVATE_INVENTORY) && echo -n yes),yes)
	INVENTORY=$(PRIVATE_INVENTORY)
else
    INVENTORY = "inventory"
endif

# See https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run/14061796#14061796
SUPPORTED_COMMANDS := install
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

# Main Ansible Playbook Command (prompts for password)
ANSIBLE=. .tox/py3/bin/activate && ansible-playbook workstation.yml --inventory $(INVENTORY) --ask-become-pass --become

.PHONY: help
help: ## Display help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

update: clean ## Update this repository
	@git pull
	@tox

clean: ## Clean tox directory
	@rm -Rf .tox/

prepare: ## Install dependencies needed to run this playbook
	@sudo apt update 
	@sudo apt install -y wget curl tar unzip python3 python3-dev python3-pip python3-apt
	@sudo pip3 install tox
	@tox

lint: ## Lint
	yamllint .
	ansible-lint .

check: ## Checks workstation.yml playbook
	@$(ANSIBLE) --check

list: ## List all available tags
	@$(ANSIBLE) --list-tags

install: ## Run workstation.yml playbook with tags
	@$(ANSIBLE) --tags=$(COMMAND_ARGS)

all: ## Install everything from workstation.yml playbook
	@echo $(ANSIBLE)
