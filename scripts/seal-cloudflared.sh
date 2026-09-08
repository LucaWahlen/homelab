#!/usr/bin/env bash
# Seal the cloudflared tunnel token from tofu state into Git. Idempotent: the
# sealed file is only rewritten when the token actually changed - it is then
# committed and pushed so ArgoCD (which syncs from the remote repo) deploys
# the new token.
set -eu
cd "$(dirname "$0")/.."

token=$(tofu -chdir=opentofu/cloudflare-tunnel output -raw tunnel_token)
if [ -z "$token" ]; then
    echo "tunnel_token output missing - run 'tofu apply' in opentofu/cloudflare-tunnel first" >&2
    exit 1
fi

target=apps/cloudflared/manifests/secret.enc.yaml
current=""
if [ -f "$target" ]; then
    # Tolerate decrypt failures (missing/mismatched key) by treating the file
    # as outdated - encryption only needs the recipient from .sops.yaml.
    current=$(sops --decrypt "$target" 2>/dev/null | sed -n 's/^[[:space:]]*TUNNEL_TOKEN:[[:space:]]*//p')
fi
if [ "$token" = "$current" ]; then
    echo "$target is up to date"
    exit 0
fi

cat > "$target" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-credentials
  namespace: cloudflared
type: Opaque
stringData:
  TUNNEL_TOKEN: $token
EOF
sops encrypt --in-place "$target"
# Only the sealed secret is committed, never unrelated local changes. A failed
# push aborts the run loudly: ArgoCD syncs from the remote and would otherwise
# deploy a stale token.
git add "$target"
git commit --message "update cloudflared tunnel token" -- "$target"
git push
echo "Sealed $target - committed and pushed"
