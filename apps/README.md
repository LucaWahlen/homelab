# Apps

This directory holds every application ArgoCD manages on the cluster, using
the "app-of-apps" pattern.

## How it works

Everything ArgoCD does is defined here, not in Ansible - `apps/` is the
single source of truth. Ansible's only job is applying `apps/root.yaml`
as-is (`ansible/roles/argocd`) to bootstrap the chain below; from there,
every change is a `git push`, not a re-run of Ansible.

1. `apps/root.yaml` is the root ArgoCD `Application`, pointing at
   `apps/applications/`. ArgoCD auto-detects the `kustomization.yaml` there
   and builds it like any other Kustomize source.
2. Each resource listed in `apps/applications/kustomization.yaml` is itself
   an ArgoCD `Application`, pointing at that app's manifests elsewhere
   under `apps/` - including `apps/argocd/`, which configures ArgoCD's own
   Ingress and `server.insecure` setting the same way as any other app.
3. ArgoCD syncs automatically (prune + self-heal), so once `apps/root.yaml`
   is applied once, adding a new app is just a `git push`.

## Adding a new app

1. Create `apps/<name>/manifests/` with plain Kubernetes YAML and a
   `kustomization.yaml` listing them.
2. Add `apps/applications/<name>.yaml`, an `Application` resource pointing
   `source.path` at `apps/<name>/manifests` (copy
   `apps/applications/example-app.yaml` as a starting point), and list it in
   `apps/applications/kustomization.yaml`'s `resources`.
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
