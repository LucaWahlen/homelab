# homelab

Monorepo for my homelab: one big VM on Proxmox, provisioned with OpenTofu,
configured with Ansible into a single-node k3s cluster running ArgoCD, which
then manages every app in this repo via GitOps.

```
opentofu/proxmox-vm/        OpenTofu config that downloads a cloud image and boots a new VM from it
opentofu/cloudflare-tunnel/ OpenTofu config for the Cloudflare Tunnel + wildcard DNS + its k8s Secret
ansible/                     Ansible playbook/roles that install k3s + ArgoCD on that VM
apps/                        Every app ArgoCD deploys (app-of-apps pattern)
```

Everything here is meant to be run from a control machine (not the Proxmox
host, not the VM itself) that has `tofu`, `ansible`, and network access to
Proxmox / Cloudflare / the VM. Run all the steps below from the same
checkout on that machine - step 2 writes a kubeconfig file that step 3
depends on.

## Prerequisites

- A Proxmox node reachable over the network, with an API token
  (Datacenter -> Permissions -> API Tokens) whose role has the privileges
  below - the default `PVEVMAdmin`-style roles are not enough, since
  downloading the cloud image needs API-level access most starter roles
  don't grant:

  ```sh
  # Run on the Proxmox host
  pveum role add Terraform -privs "Datastore.Allocate Datastore.AllocateSpace \
    Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit \
    Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM \
    VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType \
    VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate \
    VM.Monitor VM.PowerMgmt VM.Snapshot VM.Snapshot.Rollback"
  pveum aclmod / -user terraform@pve -role Terraform
  pveum user token add terraform@pve terraform --privsep 0
  ```

  `Sys.Audit` on `/` in particular is what the download step needs - without
  it, `tofu apply` fails with `HTTP 403 ... Permission check failed` (that's
  Proxmox rejecting the token, not Ubuntu blocking the download).
  `--privsep 0` makes the token inherit the user's own ACLs; if you already
  have a token, just add the role/ACL to its user and it applies retroactively.
- `image_datastore_id` (default `local`) needs the **Import** content type
  enabled: Datacenter -> Storage -> `local` -> Edit -> Content, tick
  "Import". Not on by default on a fresh Proxmox VE install; without it, the
  disk-import step fails.
- A Cloudflare account managing the `lucawahlen.com` zone, with an API token
  (Zero Trust: Edit + DNS: Edit) and your account ID / zone ID.
- [OpenTofu](https://opentofu.org/) installed (`tofu` on your PATH).
- [Ansible](https://docs.ansible.com/) installed.
- An SSH key pair you're happy to have injected into the VM.
- This repo pushed to a git remote the cluster can reach (ArgoCD pulls from
  it directly). Simplest: a **public** GitHub repo with an `https://`
  `git_repo_url` (`ansible/inventory/group_vars/all.yml`) and matching
  `repoURL` in every `apps/applications/*.yaml` - ArgoCD needs no
  credentials for that. A private repo needs a deploy key registered with
  ArgoCD separately (not covered by this repo).

## 1. Provision the VM with OpenTofu

OpenTofu downloads the Ubuntu cloud image straight onto the Proxmox node and
boots the VM from it - no manual template-building step needed.

```sh
cd opentofu/proxmox-vm
cp terraform.tfvars.example terraform.tfvars
# fill in proxmox_endpoint, proxmox_api_token, proxmox_node, storage_pool,
# vm_ip_address / vm_gateway for your network, and ssh_public_key
tofu init
tofu apply
```

Defaults size the VM at 10 vCPU / 24GB RAM / 800GB disk, leaving headroom on
a 12 vCPU / 32GB / 1TB node for Proxmox itself. Adjust `vm_cores`,
`vm_memory`, `vm_disk_size` in your `terraform.tfvars` if needed.

## 2. Install k3s + ArgoCD with Ansible

```sh
cd ansible
cp inventory/hosts.yml.example inventory/hosts.yml
cp inventory/group_vars/all.yml.example inventory/group_vars/all.yml
# set ansible_host to the vm_ip_address from step 1, and git_repo_url to
# this repo's actual clone URL
ansible-playbook playbooks/site.yml
```

This installs k3s (single-node server), installs ArgoCD into the `argocd`
namespace, and applies a root ArgoCD `Application` that watches
`apps/applications/` in this repo - from here on, apps are added via `git
push`, not by re-running Ansible.

A kubeconfig for the cluster is written to `./kubeconfig` (gitignored) -
step 3 needs this file, so run it from the same checkout:

```sh
export KUBECONFIG=$(pwd)/kubeconfig
kubectl -n argocd get pods
```

Get the initial ArgoCD admin password:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 3. Expose services on *.lucawahlen.com

A Cloudflare Tunnel routes all of `*.lucawahlen.com` into the cluster's
Traefik ingress, so any app just needs an `Ingress` resource to go live on
the internet - no per-app tunnel or DNS changes. See
[apps/README.md](apps/README.md#exposing-an-app-on-the-internet) for that
convention.

```sh
cd opentofu/cloudflare-tunnel
cp terraform.tfvars.example terraform.tfvars
# fill in cloudflare_api_token, cloudflare_account_id, cloudflare_zone_id
tofu init
tofu apply
```

This provisions the tunnel and wildcard DNS record with the `cloudflare`
provider, and - via the `kubernetes` provider, pointed at the kubeconfig
step 2 wrote - creates the `cloudflared` namespace and the Secret holding
the tunnel's connector token directly in the cluster. Nothing manual: once
ArgoCD syncs the `cloudflared` app (already wired into the app-of-apps),
`https://example.lucawahlen.com` should reach `apps/example-app`'s nginx.

## 4. Add apps

See [apps/README.md](apps/README.md) for the app-of-apps pattern. In short:
drop manifests under `apps/<name>/manifests/`, add a matching `Application`
in `apps/applications/<name>.yaml`, push - ArgoCD does the rest.

## Convenience targets

`make tf-init` / `tf-plan` / `tf-apply` / `tf-destroy` and
`make tunnel-init` / `tunnel-plan` / `tunnel-apply` / `tunnel-destroy` and
`make ansible-bootstrap` wrap the commands above (see [Makefile](Makefile)).
