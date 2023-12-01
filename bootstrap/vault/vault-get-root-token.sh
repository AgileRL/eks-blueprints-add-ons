#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "$0 <clusetr>"
  echo "   - cluster: e.g. agrl-core"
  exit 1
fi

CLUSTER=$1

ENC=$(aws ssm get-parameters --name "${CLUSTER}-vault-unseal-root" | jq -r ".Parameters[0].Value")

aws kms decrypt --ciphertext-blob fileb://<(echo -n ${ENC} | base64 -d) --output text \
  --query Plaintext --encryption-context Tool=vault-unsealer | base64 -d
