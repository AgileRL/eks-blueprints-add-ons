#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "$0 <clusetr>"
  echo "   - cluster: e.g. agrl-core"
  exit 1
fi

CLUSTER=$1

KMS_KEY_ID=alias/eks/${CLUSTER}-vault-unseal

ROOT_TOKEN=$(cat data/vault.recovery-keys | grep Root | sed -e 's/^.*: //' | base64)

echo "Storing root token $(echo $ROOT_TOKEN | base64 -d)"

ROOT_ENC=$(aws kms encrypt --key-id ${KMS_KEY_ID} --plaintext $ROOT_TOKEN --encryption-context Tool=vault-unsealer --output text --query CiphertextBlob)

if [[ -n "${ROOT_ENC}" ]]; then
    echo "Creating a new SSM parameter key ${CLUSTER}-vault-unseal-root for Vault root token"
    aws ssm put-parameter --name "${CLUSTER}-vault-unseal-root" --value "${ROOT_ENC}" --type String --overwrite
fi

