#!/bin/bash

# add repo for postgres-operator
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator

kubectl create ns postgres-system

# install the postgres-operator
helm install pgopr postgres-operator-charts/postgres-operator -n postgres-system -f values.yaml

# add repo for postgres-operator-ui
# helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui
# # install the postgres-operator-ui
# helm install pgopr-ui postgres-operator-ui-charts/postgres-operator-ui -n pg-ops
