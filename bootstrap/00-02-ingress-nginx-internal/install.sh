#!/bin/bash

helm install gitlab-operator gitlab-operator/gitlab-operator --create-namespace --namespace gitlab-system
