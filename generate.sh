#!/bin/bash
echo "Generating ArgoCD manifests..."

helm template -n argocd argocd ./charts/argo-cd --values ./values/argo-cd/values.yaml > ./manifests/argo-cd/manifest.yaml

echo "Generating Prometheus manifests..."
helm template -n prometheus prometheus ./charts/prometheus --values ./values/prometheus/values.yaml > ./manifests/prometheus/manifest.yaml

echo "Generating Keycloak manifests..."
helm template -n keycloak keycloak ./charts/keycloakx --values ./values/keycloak/values.yaml > ./manifests/keycloak/manifest.yaml

echo "Generating Guestbook manifests..."
helm template -n guestbook-staging guestbook-staging ./charts/helm-guestbook --values ./values/guestbook/staging/values.yaml > ./manifests/guestbook/staging/manifest.yaml
helm template -n guestbook-prod guestbook-prod ./charts/helm-guestbook --values ./values/guestbook/prod/values.yaml > ./manifests/guestbook/prod/manifest.yaml