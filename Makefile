SHELL := /bin/bash

# colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
# No Color
NC := \033[0m

##### Variables
GIT_ROOT := $(shell git rev-parse --show-toplevel)
LOG_DIR := $(GIT_ROOT)/.logs
# IMPORTANT: if you change any of these in molecule.yml then adapt the variables below.
SINGLE_NODE_FIRST_MASTER_IP := 192.168.30.50
DEFAULT_FIRST_MASTER_IP := 192.168.30.38
THREE_MASTERS_FIRST_MASTER_IP := 192.168.30.61
FIRST_MASTER_NAME := control1

# Default scenario
CURRENT_SCENARIO ?= default
CURRENT_FIRST_MASTER_IP ?= $(DEFAULT_FIRST_MASTER_IP)

ANSIBLE_SSH_RETRIES ?= 5
ANSIBLE_TIMEOUT ?= 30
export ANSIBLE_SSH_RETRIES
export ANSIBLE_TIMEOUT

ifeq ($(CURRENT_SCENARIO), single_node)
	CURRENT_FIRST_MASTER_IP := $(SINGLE_NODE_FIRST_MASTER_IP)
else ifeq ($(CURRENT_SCENARIO), three_masters)
	CURRENT_FIRST_MASTER_IP := $(THREE_MASTERS_FIRST_MASTER_IP)
endif
#####

##### FUNCTIONS
define download_kubeconfig
	@scp -q -i ~/.cache/molecule/$(notdir $(shell pwd))/$(1)/.vagrant/machines/$(FIRST_MASTER_NAME)/virtualbox/private_key \
		-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
		vagrant@$(2):~/.kube/config \
		$(GIT_ROOT)/kubeconfig.$(1)
	@echo -e "To access the cluster, run: $(GREEN)export KUBECONFIG=$(GIT_ROOT)/kubeconfig.$(1)$(NC)"
endef

define converge
	ANSIBLE_K3S_LOG_DIR=$(LOG_DIR)/$(1) molecule converge -s $(1)
	$(call download_kubeconfig,$(1),$(2))
endef
###############

.PHONY: mol-single_node mol-single mol-single-nodestroy mol-single-create mol-single-conv mol-single-ver mol-single-side mol-single-destroy
		mol-default	mol mol-nodestroy mol-create mol-conv mol-ver mol-side mol-destroy mol-three_masters mol-three mol-three-nodestroy
		mol-three-create mol-three-conv mol-three-ver mol-three-side mol-three-destroy lint mol-kubeconfig

# download kubeconfig from first master depending on scenario
# CURRENT_SCENARIO=single_node make mol-kubeconfig # (default: three_masters)
mol-kubeconfig:
	$(call download_kubeconfig,$(CURRENT_SCENARIO),$(CURRENT_FIRST_MASTER_IP))

###### Linting
lint:
	@echo -e "$(GREEN)Check Linting using 'yamllint' and 'ansible-lint' ...$(NC)"
	yamllint .
	ansible-lint
	@echo -e "$(GREEN)Linting Passed!$(NC)"

####### three_masters scenario
mol-three_masters: mol-three

# ANSIBLE_K3S_LOG_DIR is set in GitHUb action
mol-three:
	molecule test -s three_masters

mol-three-nodestroy:
	ANSIBLE_K3S_LOG_DIR=$(LOG_DIR)/three_masters molecule test -s three_masters --destroy=never

mol-three-create:
	molecule create -s three_masters

mol-three-conv:
	$(call converge,three_masters,$(THREE_MASTERS_FIRST_MASTER_IP))

mol-three-ver:
	molecule verify -s three_masters

mol-three-side:
	molecule side-effect -s three_masters

mol-three-destroy:
	molecule destroy -s three_masters
	rm -f $(GIT_ROOT)/kubeconfig.three_masters
#########

###### single_node scenario
mol-single_node: mol-single

# ANSIBLE_K3S_LOG_DIR is set in GitHUb action
mol-single:
	molecule test -s single_node

mol-single-nodestroy:
	ANSIBLE_K3S_LOG_DIR=$(LOG_DIR)/single_node molecule test -s single_node --destroy=never

mol-single-create:
	molecule create -s single_node

mol-single-conv:
	$(call converge,single_node,$(SINGLE_NODE_FIRST_MASTER_IP))

mol-single-ver:
	molecule verify -s single_node

mol-single-side:
	molecule side-effect -s single_node

mol-single-destroy:
	molecule destroy -s single_node
	rm -f $(GIT_ROOT)/kubeconfig.single_node
#########

####### default scenario
mol-default: mol

# ANSIBLE_K3S_LOG_DIR is set in GitHUb action
mol:
	molecule test

mol-nodestroy:
	ANSIBLE_K3S_LOG_DIR=$(LOG_DIR)/default molecule test --destroy=never

mol-create:
	molecule create

mol-conv:
	$(call converge,default,$(DEFAULT_FIRST_MASTER_IP))

mol-ver:
	molecule verify

mol-side:
	molecule side-effect

mol-destroy:
	molecule destroy
	rm -f $(GIT_ROOT)/kubeconfig.default
###########
