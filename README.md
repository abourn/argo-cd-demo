# ArgoCD Demo

A repository with configuration files to create a Kind cluster with an ArgoCD instance.

Ingress to the cluster is provided through Contour.  ArgoCD authentication is provided through a locally running Keycloak instance.

ArgoCD is responsible for deploying itself, Contour, Keycloak, Prometheus, and two guestbook applications in different environments.

## Prerequisites

To work with this repository and to deploy the Kind cluster, the following tools are required.

| Tool  | Tested with version |
|-------|-----|
| Docker | Docker Desktop 4.83.0 |
| Kind | v0.32.0 |
| Helm | v4.2.3 |
| Kubectl | v1.36.3 | 

## Repository Structure

| File  | Description |
|-------|-----|
| [`argo-cd-apps/`](argo-cd-apps/) | A collection of ArgoCD Application and ApplicationSet manifests. Critically, [`argo-cd-apps/app-of-apps/`](argo-cd-apps/app-of-apps/) contains an ArgoCD Application which is responsible for applying all the other Applications/ApplicationSets under [`argo-cd-apps/`](argo-cd-apps/), following the "app of apps" pattern. |
| [`charts/`](charts/) | Contains local copies of Helm charts used to render Kubernetes manifests for the services deployed. These local copies can be refreshed with `helm pull`. |
| [`cluster/`](cluster/) | Configuration of the Kind cluster itself, including a custom CoreDNS Corefile. |
| [`manifests/`](manifests/) | Fully rendered Kubernetes manifests for each service to deploy. Not intended to be edited manually, but rather recreated with [`./generate.sh`](./generate.sh). |
| [`values/`](values/) | Helm `values.yaml` files for each service. |
| [`./bootstrap.sh`](./bootstrap.sh) | Script to create the Kind cluster and perform the initial bootstrapping steps of the ArgoCD installation. |
| [`./generate.sh`](./generate.sh) | Script to regenerate [`manifests/`](manifests/), using `helm template` against [`charts/`](charts/) and [`values/`](values/). |

## Bootstrapping

To get started, you can simply run the included `./bootstrap.sh` script.  This script will create the Kind cluster, apply a custom CoreDNS Corefile required for the ingress setup, perfom the initial installation of ArgoCD, and then apply the root "app of apps" to trigger ArgoCD to deploy all the other applications.

Afterwards, you should add the following entries to your `/etc/hosts` file:

```
127.0.0.1 argocd.local
127.0.0.1 keycloak.local
127.0.0.1 prometheus.local
```

Without the Keycloak and ArgoCD entries, when trying to perform SSO to ArgoCD, the redirect URL will be incorrect and authentication will fail.

## ArgoCD Syncs Explained

![ArgoCD Architecture](assets/sync-explained.png.jpg)

The above diagram explains the auto sync process of ArgoCD when changes to Kubernetes Manifests are published to source control.

## Ingress Explained

Ingress is provided through Contour/Envoy.  

The Kind cluster is configured with `extraPortMappings` in order to map the local machine's ports 80 and 443 to the cluster's node.

Contour's Envoy Pod is then configured to bind to the node's port 80 and 443 (through `hostPort` on the Pod), which allows Envoy to be reached from the Kind host machine.

The Contour Envoy Service is configured with a static cluster IP at `10.96.200.1`.  This then enables a `hosts{}` block to be set in a custom CoreDNS Corefile ([`cluster/coredns-cm.yaml`](cluster/coredns-cm.yaml)) which maps friendly hostnames like `argocd.local` and `keycloak.local` to this Envoy Service IP.  This allows those friendly hostnames to be resolvable inside the cluster. Envoy is an L7 proxy, so it ensures requests to specific hostnames are routed to the correct Service.

Finally, the `/etc/hosts` entries mentioned in [bootstrapping](#bootstrapping) ensure that those hostnames can be resolved from the machine running Kind.

## Updating Helm Charts

To update the local copies of Helm charts in [charts/](./charts/), you can run `helm pull` for the relevant chart.

First, make sure that you have added the necessary Helm repositories:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add contour https://projectcontour.github.io/helm-charts/
```

Then, you should remove the local copy of whatever Helm chart you are updating:

```bash
rm -r charts/argo-cd
rm -r charts/contour
rm -r charts/keycloakx
rm -r charts/prometheus
```

And then you can `helm pull` to update the charts:

```bash
helm pull prometheus-community/prometheus --untar --destination ./charts
helm pull contour/contour --untar --destination ./charts

# These OCI Helm Charts do not require the initial `helm repo add`.
helm pull oci://ghcr.io/argoproj/argo-helm/argo-cd --untar --destination ./charts
helm pull oci://ghcr.io/codecentric/helm-charts/keycloakx --untar --destination ./charts
```

After updating the charts, you can run `./generate.sh` to confirm the manifest output is as expected.

Please note, the [`charts/helm-guestbook`](./charts/helm-guestbook/) directory is copied manually from the [argocd-example-apps repository](https://github.com/argoproj/argocd-example-apps/tree/master/helm-guestbook).

## Troubleshooting

If Pods are taking a long time to start and it is seemingly due to image pulls taking a long time, you can try restarting the kubelet service:

```bash
docker exec demo-control-plane systemctl restart kubelet
```

If you are on macOS and it seems like the `.local` addresses are failing to resolve, you can flush your DNS cache with:

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

## Teardown

Tearing down the setup is as simple as:

```bash
kind delete clusters demo
```

And then removing the `.local` entries from `/etc/hosts`.

## Known Limitations

As this is a simple demonstration that is running in a local Kind cluster, there are some known limitations. In particular:

- ArgoCD runs in insecure mode. Moreover, TLS is not configured for the ingresses running in the cluster.
- The Keycloak installation is purely for demonstration purposes, so the OIDC Client Secret is hardcoded in source control, as are the credentials for a demo user.
- The Kind cluster is configured as a single node cluster.
