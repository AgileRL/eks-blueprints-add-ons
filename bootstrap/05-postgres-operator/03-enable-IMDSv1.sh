#!/bin/bash

# spilo need access to IMDSv1

INSTANCE_ID=$1

if [[ $# -lt 1 ]]; then
  echo $0 instance_id
  exit 1
fi


aws ec2 modify-instance-metadata-options --instance-id ${INSTANCE_ID} --http-tokens optional
aws ec2 describe-instances --instance-id ${INSTANCE_ID} --query 'Reservations[].Instances[].MetadataOptions'

# should use terraform
# aws ec2 create-launch-template-version \
#   --launch-template-id lt-01234567890 \
#   --source-version 123 \
#   --version-description "Your description here" \
#   --launch-template-data '{
#     "MetadataOptions": {
#         "HttpTokens": "optional", "HttpProtocolIpv6": "disabled", "InstanceMetadataTags": "disabled",
#         "HttpPutResponseHopLimit": 2, "HttpEndpoint": "enabled"
#     }
# }'

