#!/bin/bash

helm upgrade --install agrl-core oci://registry-1.docker.io/bitnamicharts/keycloak --create-namespace --namespace auth-system -f values.yaml
