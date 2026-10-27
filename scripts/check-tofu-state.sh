#!/usr/bin/env bash
# Fails if OpenTofu state committed to the repo is not encrypted, if an
# encrypted input lacks sops metadata, or if a plaintext tfvars/state file is
# staged. State encryption is configured in opentofu/*/encryption.tf and
# implemented by scripts/tofu-state-key.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

failed=0

# 1. Every tracked OpenTofu state file must be an encryption envelope.
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

# 2. Encrypted inputs (the TF_VAR_* secrets files) must carry sops metadata.
while IFS= read -r -d '' file; do
    if [[ "$(yq '.sops.mac // ""' "$file")" != ENC\[* ]]; then
        echo "$file: missing sops metadata" >&2
        failed=1
    fi
done < <(find opentofu -type f -name '*.enc.yaml' -print0)

# 3. No plaintext variable files may be staged for commit.
while IFS= read -r file; do
    [ -n "$file" ] || continue
    echo "$file: plaintext tfvars must not be committed" >&2
    failed=1
done < <(git diff --cached --name-only --diff-filter=ACMR -- '*.tfvars')

exit "$failed"
