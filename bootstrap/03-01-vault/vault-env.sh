#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "$0 <clusetr>"
  echo "   - cluster: e.g. agrl-core"
  exit 1
fi

CLUSTER=$1

export VAULT_ADDR=https://vault.agilerl.rlops.ai
