#!/usr/bin/env bash
# Fails if a secret under kubernetes/ could end up in Git unencrypted.
set -euo pipefail
cd "$(dirname "$0")/.."

failed=0

while IFS= read -r -d '' file; do
    if [[ "$(yq '.sops.mac // ""' "$file")" != ENC\[* ]]; then
        echo "$file: missing sops metadata" >&2
        failed=1
    fi
    plain=$(yq '((.data // {}) + (.stringData // {})) | to_entries | .[] | select(.value | test("^ENC\[") | not) | .key' "$file")
    if [[ -n "$plain" ]]; then
        echo "$file: unencrypted keys: $plain" >&2
        failed=1
    fi
done < <(find kubernetes -path kubernetes/argocd/charts -prune -o -name '*.enc.yaml' -print0)

while IFS= read -r -d '' file; do
    if [[ -n "$(yq 'select(.kind == "Secret") | .kind' "$file")" ]]; then
        echo "$file: Secret outside an .enc.yaml file" >&2
        failed=1
    fi
done < <(find kubernetes -path kubernetes/argocd/charts -prune -o -name '*.yaml' ! -name '*.enc.yaml' -print0)

exit "$failed"
