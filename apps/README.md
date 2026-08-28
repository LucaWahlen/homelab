# Apps

This directory holds every application ArgoCD manages on the cluster, using
the "app-of-apps" pattern.

## How it works

1. The Ansible bootstrap (`ansible/roles/argocd`) applies one root ArgoCD
   `Application` that watches `apps/applications/*.yaml` in this repo.
2. Each file in `apps/applications/` is itself an ArgoCD `Application`
   pointing at that app's manifests, elsewhere under `apps/`.
3. ArgoCD syncs automatically (prune + self-heal), so once the root app
   exists, adding a new app is just a `git push`.

## Adding a new app

1. Create `apps/<name>/manifests/` with plain Kubernetes YAML or a
   `kustomization.yaml`.
2. Add `apps/applications/<name>.yaml`, an `Application` resource pointing
   `source.path` at `apps/<name>/manifests` (copy
   `apps/applications/example-app.yaml` as a starting point).
3. Commit and push. ArgoCD picks it up on its next sync (default: within a
   few minutes, or trigger manually from the ArgoCD UI/CLI).

`apps/example-app/` is a working demo (nginx) - safe to delete once you have
real apps in place.

## Exposing an app on the internet

A Cloudflare Tunnel (`opentofu/cloudflare-tunnel/`) routes all of
`*.lucawahlen.com` to Traefik (k3s's built-in ingress controller), and the
`cloudflared` app (`apps/cloudflared/`) runs the tunnel connector in-cluster.
Because the DNS and tunnel config are both wildcards, exposing a new app
needs no changes to either - just add an `Ingress` to the app's own
manifests:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <name>
spec:
  ingressClassName: traefik
  rules:
    - host: <name>.lucawahlen.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <name>
                port:
                  number: 80
```

See `apps/example-app/manifests/ingress.yaml` for a working copy of this.
