# ArgoCD Demo

## Prerequisites
- Docker
- Kind
- Helm
- Kubectl

# TODO
ApplicationSet for guestbook to demonstrate multiple environments (make sure to -CreateNamespace=true or add to helm chart)
Kubectl-slice?

Add example alert in alertmanager

For Bonuses:
- Install ArgoCD in HA
- Secrets Management example?
- TLS, Ingress, Tunneling?
- CRDs separately?


# Upgrading ArgoCD Chart
Helm pull... > charts/argo-cd

# Teardown
kind delete clusters demo