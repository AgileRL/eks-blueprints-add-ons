#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "$0 <clusetr>"
  echo "   - cluster: e.g. agrl-core"
  exit 1
fi

CLUSTER=$1

KMS_KEY_ID=alias/eks/${CLUSTER}-vault-unseal

ROOT_ENC=$(aws kms encrypt --key-id ${KMS_KEY_ID} --plaintext fileb://./data/vault.recovery-keys --encryption-context Tool=vault-recovery-keys --output text --query CiphertextBlob)

if [[ -n "${ROOT_ENC}" ]]; then
    echo "Creating a new SSM parameter key ${CLUSTER}-vault-recovery-keys for Vault recovery keys"
    aws ssm put-parameter --name "${CLUSTER}-vault-recovery-keys" --value "${ROOT_ENC}" --type String --overwrite
fi

