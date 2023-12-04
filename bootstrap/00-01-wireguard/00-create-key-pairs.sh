#!/bin/bash

KEY_NAME=agrl-core-wg-key-pair

if [[ ! -f "${KEY_NAME}.pem" ]]; then
  aws ec2 create-key-pair \
    --key-name agrl-core-wg-key-pair \
    --key-type ed25519 \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > ${KEY_NAME}.pem
  chmod 400 ${KEY_NAME}.pem
fi

ssh-keygen -y -f ${KEY_NAME}.pem > ${KEY_NAME}.pub
