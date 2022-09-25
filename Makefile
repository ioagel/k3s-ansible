SHELL := /bin/bash

# colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
# No Color
NC := \033[0m

##### Variables
# IMPORTANT: if you change any of these in molecule.yml then adapt the variables below.
SINGLE_NODE_FIRST_MASTER_IP := 192.168.30.50
DEFAULT_FIRST_MASTER_IP := 192.168.30.38
FIRST_MASTER_NAME := control1

##### FUNCTIONS
define download_kubeconfig
	@scp -q -i ~/.cache/molecule/$(notdir $(shell pwd))/$(1)/.vagrant/machines/$(FIRST_MASTER_NAME)/virtualbox/private_key \
		-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
		vagrant@$(2):~/.kube/config \
		kubeconfig.$(1)
endef

.PHONY: mol-single_node mol-single mol-single-nodestroy mol-single-create mol-single-conv mol-single-ver mol-single-side mol-single-destroy
		mol-default	mol mol-nodestroy mol-create mol-conv mol-ver mol-side mol-destroy

###### single_node scenario
mol-single_node: mol-single

mol-single:
	molecule test -s single_node

mol-single-nodestroy:
	molecule test -s single_node --destroy=never

mol-single-create:
	molecule create -s single_node

mol-single-conv: 
	molecule converge -s single_node
	$(call download_kubeconfig,single_node,$(SINGLE_NODE_FIRST_MASTER_IP))
	@echo -e "To access the cluster, run: $(GREEN)export KUBECONFIG=kubeconfig.single_node$(NC)"

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
	molecule converge
	$(call download_kubeconfig,default,$(DEFAULT_FIRST_MASTER_IP))
	@echo -e "To access the cluster, run: $(GREEN)export KUBECONFIG=kubeconfig.default$(NC)"

mol-ver:
	molecule verify

mol-side:
	molecule side-effect

mol-destroy:
	molecule destroy
	rm -f kubeconfig.default

###########