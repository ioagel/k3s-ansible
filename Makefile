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

CURRENT_SCENARIO ?= three_masters
CURRENT_FIRST_MASTER_IP ?= $(THREE_MASTERS_FIRST_MASTER_IP)

ifeq ($(CURRENT_SCENARIO), single_node)
	CURRENT_FIRST_MASTER_IP := $(SINGLE_NODE_FIRST_MASTER_IP)
else ifeq ($(CURRENT_SCENARIO), default)
	CURRENT_FIRST_MASTER_IP := $(DEFAULT_FIRST_MASTER_IP)
endif

##### FUNCTIONS
define download_kubeconfig
	@scp -q -i ~/.cache/molecule/$(notdir $(shell pwd))/$(1)/.vagrant/machines/$(FIRST_MASTER_NAME)/virtualbox/private_key \
		-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
		vagrant@$(2):~/.kube/config \
		kubeconfig.$(1)
endef

define converge
	ANSIBLE_K3S_LOG_DIR=$(LOG_DIR)/$(1) molecule converge -s $(1)
	$(call download_kubeconfig,$(1),$(2))
	@echo -e "To access the cluster, run: $(GREEN)export KUBECONFIG=kubeconfig.$(1)$(NC)"
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

mol-three:
	molecule test -s three_masters

mol-three-nodestroy:
	molecule test -s three_masters --destroy=never

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
	rm -f kubeconfig.three_masters

#########

###### single_node scenario
mol-single_node: mol-single

mol-single:
	molecule test -s single_node

mol-single-nodestroy:
	molecule test -s single_node --destroy=never

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
	rm -f kubeconfig.single_node

#########

####### default scenario
mol-default: mol

mol:
	molecule test

mol-nodestroy:
	molecule test --destroy=never

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
	rm -f kubeconfig.default

###########