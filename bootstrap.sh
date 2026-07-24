#!/bin/bash
echo "Creating cluster..."
kind create cluster --name akuity

# Create ArgoCD namespace manually, as the Helm Chart does not render Namespace manifest
echo "Creating ArgoCD namespace..."
kubectl create namespace argocd

# Wait, then kubectl apply ArgoCD, separate dir for Applications?
echo "Installing ArgoCD..."
kubectl apply -n argocd -f manifests/argo-cd/manifest.yaml

# TODO: maybe move app-of-apps.yaml into manifests/ for organization?
echo "Initializing app of apps..."
kubectl apply -n argocd -f app-of-apps.yaml
