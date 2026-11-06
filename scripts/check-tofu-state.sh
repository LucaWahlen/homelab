#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

failed=0

while IFS= read -r file; do
    [ -n "$file" ] || continue
    content=$(git show ":$file" 2>/dev/null || true)
    if [[ "$content" != *'"encrypted_data"'* ]]; then
        echo "$file: not an encrypted OpenTofu state file" >&2
        failed=1
    elif [[ "$content" == *'"resources"'* ]]; then
        echo "$file: contains plaintext resources" >&2
        failed=1
    fi
done < <(git ls-files -- 'opentofu/*/terraform.tfstate')

while IFS= read -r -d '' file; do
    if [[ "$(yq '.sops.mac // ""' "$file")" != ENC\[* ]]; then
        echo "$file: missing sops metadata" >&2
        failed=1
    fi
done < <(find opentofu -type f -name '*.enc.yaml' -print0)

while IFS= read -r file; do
    [ -n "$file" ] || continue
    echo "$file: plaintext tfvars must not be committed" >&2
    failed=1
done < <(git diff --cached --name-only --diff-filter=ACMR -- '*.tfvars')

exit "$failed"
