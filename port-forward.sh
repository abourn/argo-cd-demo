#!/bin/bash

# Port forward three Kubernetes services
kubectl -n argocd port-forward svc/argocd-server 8080:80 &
ARGOCD_PID=$!

kubectl port-forward -n keycloak svc/keycloak-keycloakx-http 9000:80 &
KEYCLOAK_PID=$!

kubectl port-forward -n prometheus svc/prometheus-server 9090:80 &
PROMETHEUS_PID=$!

# Trap Ctrl+C to clean up all processes
trap "kill $ARGOCD_PID $KEYCLOAK_PID $PROMETHEUS_PID 2>/dev/null; exit" INT TERM

# Wait for all background processes
wait
