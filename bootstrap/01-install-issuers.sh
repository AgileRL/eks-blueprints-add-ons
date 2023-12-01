#!/bin/bash

ROLE=$( aws iam list-roles --query "Roles[*].Arn" --output json | grep cert-manager | sed -e 's/^.*"arn/arn/; s/",//')

cat << EOT | kubectl apply -f -  
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: wei@agilerl.com

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging

    # ACME DNS-01 provider configurations
    solvers:
    # An empty 'selector' means that this solver matches all domains
    - selector: 
        dnsZones:
          - "agilerl.rlops.ai"
      dns01:
        route53:
          region: eu-west-1
          hostedZoneID: Z09132382KDIGS27ISIPC
          role: $ROLE
EOT


cat << EOT | kubectl apply -f -  
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: wei@agilerl.com

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod

    # ACME DNS-01 provider configurations
    solvers:
    # An empty 'selector' means that this solver matches all domains
    - selector: 
        dnsZones:
          - "agilerl.rlops.ai"
      dns01:
        route53:
          region: eu-west-1
          hostedZoneID: Z09132382KDIGS27ISIPC
          role: $ROLE
EOT


cat << EOT | kubectl apply -f -  
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
EOT
