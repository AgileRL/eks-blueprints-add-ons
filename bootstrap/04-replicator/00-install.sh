#!/bin/bash

helm repo add mittwald https://helm.mittwald.de

helm repo update

helm upgrade --install kubernetes-replicator -n cert-manager mittwald/kubernetes-replicator
