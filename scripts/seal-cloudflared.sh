#!/usr/bin/env bash
# Seals the tunnel token from tofu state into Git; ArgoCD syncs from the remote, so it is pushed.
set -euo pipefail
cd "$(dirname "$0")/.."

target=kubernetes/apps/cloudflared/secret.enc.yaml
token=$(tofu -chdir=opentofu/cloudflare-tunnel output -raw tunnel_token)
current=$(sops decrypt --extract '["stringData"]["TUNNEL_TOKEN"]' "$target" 2>/dev/null || true)

if [[ "$token" == "$current" ]]; then
    echo "$target is up to date"
    exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
sops encrypt --filename-override "$target" --input-type yaml --output-type yaml /dev/stdin > "$tmp" <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-credentials
  namespace: cloudflared
type: Opaque
stringData:
  TUNNEL_TOKEN: $token
YAML
mv "$tmp" "$target"

git add "$target"
git commit --message "update cloudflared tunnel token" -- "$target"
git push
