#!/bin/bash
echo "Creating cluster..."
kind create cluster --name demo

# Create ArgoCD namespace manually, as the Helm Chart does not render Namespace manifest
echo "Creating ArgoCD namespace..."
kubectl create namespace argocd

echo -e "\n"

# Initial bootstrapping installation of ArgoCD.
# SSA is needed here due to the size of CRDs being installed
echo "Installing ArgoCD..."
kubectl apply -n argocd --server-side --force-conflicts -f manifests/argo-cd/manifest.yaml

echo -e "\n"

echo "Initializing app of apps..."
kubectl apply -n argocd -f argo-cd-apps/app-of-apps/Application.yaml
