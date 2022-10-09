#!/usr/bin/env bash
# Wraps 'k9s' with our individual scenario environment
# 'k9s' is a useful terminal based program to work with your cluster
# You need it installed: https://github.com/derailed/k9s and added to $PATH

case "$1" in
  "single")
    export CURRENT_SCENARIO=single_node
    echo "Selected 'single_node' scenario"
    ;;
  "three")
    export CURRENT_SCENARIO=three_masters
    echo "Selected 'three_masters' scenario"
    ;;
  ""|"default")
    export CURRENT_SCENARIO=default
    echo "Selected 'default' scenario"
    ;;
  *)
    echo "Select molecule scenario:"
    printf "\tdefault:       '' or 'default'\n"
    printf "\tsingle_node:   'single'\n"
    printf "\tthree_masters: 'three'\n"
    echo "Usage: ./k9s.sh <single | three | ''>"
    exit 1
    ;;
esac

export KUBECONFIG=$PWD/kubeconfig.$CURRENT_SCENARIO
make mol-kubeconfig > /dev/null || exit 1
k9s
