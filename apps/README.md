# Apps

This directory holds every application ArgoCD manages on the cluster.

## How it works

Everything ArgoCD manages is defined here, not in Ansible - `apps/` is the
single source of truth. Ansible's only job is registering the Applications
below (`ansible/roles/argocd` pipes every `apps/*/application.yaml` into
`k3s kubectl apply` on the node); from there, every change is ArgoCD's
automated sync.

1. Each app lives in `apps/<name>/`: its `application.yaml` is the ArgoCD
   `Application` pointing at the `manifests/` next to it. Each Application
   is fully individual - its own namespace, sync policy, Helm or kustomize
   source, whatever - no conventions imposed. `apps/argocd/` configures
   ArgoCD's own Ingress and `server.insecure` setting the same way as any
   other app.
2. ArgoCD syncs each Application automatically (prune + self-heal), so once
   an Application is registered, changes to its manifests are just a
   `git push` - no Ansible re-run.

## Adding a new app

1. Create `apps/<name>/manifests/` with plain Kubernetes YAML and a
   `kustomization.yaml` listing them (copy `apps/example-app/manifests/` as
   a starting point).
2. Add `apps/<name>/application.yaml`, an `Application` resource pointing
   `source.path` at `apps/<name>/manifests` (copy
   `apps/example-app/application.yaml` as a starting point).
3. Register it by re-running the ArgoCD role
   (`ansible-playbook ansible/playbooks/site.yml`). This one-time apply is
   the only Ansible involvement; subsequent changes are a `git push`.

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
