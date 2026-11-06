#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "usage: ${0##*/} [--recipient AGE]... [--identity-file FILE]" >&2
    exit 2
}

recipients=()
identity_file=""

while (( $# )); do
    case "$1" in
        --recipient|-r)
            (( $# >= 2 )) || usage
            IFS=',' read -r -a new_recipients <<<"$2"
            recipients+=("${new_recipients[@]}")
            shift 2
            ;;
        --identity-file)
            (( $# >= 2 )) || usage
            identity_file="$2"
            shift 2
            ;;
        *) usage ;;
    esac
done

for value in "${AGE_RECIPIENTS:-}" "${SOPS_AGE_RECIPIENTS:-}" "${AGE_RECIPIENT:-}"; do
    [ -n "$value" ] || continue
    IFS=',' read -r -a new_recipients <<<"$value"
    recipients+=("${new_recipients[@]}")
done

if [ -z "$identity_file" ]; then
    identity_file="${AGE_IDENTITY_FILE:-${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}}"
fi

printf '%s\n' '{"magic":"OpenTofu-External-Key-Provider","version":1}'
input=$(cat)

if [ "$(jq -r 'type' <<<"$input")" = "null" ]; then
    (( ${#recipients[@]} )) || { echo "${0##*/}: no age recipients configured" >&2; exit 1; }

    key_file=$(mktemp)
    wrapped_file=$(mktemp)
    trap 'rm -f "$key_file" "$wrapped_file"' EXIT

    head -c 32 /dev/urandom > "$key_file"

    age_args=()
    for r in "${recipients[@]}"; do
        age_args+=(-r "$r")
    done
    age "${age_args[@]}" < "$key_file" > "$wrapped_file"

    jq -n \
        --arg key "$(base64 -w0 < "$key_file")" \
        --arg wrapped "$(base64 -w0 < "$wrapped_file")" \
        '{keys:{encryption_key:$key}, meta:{external_data:{wrapped:$wrapped}}}'
else
    wrapped=$(jq -r '.external_data.wrapped' <<<"$input")
    key=$(printf '%s' "$wrapped" | base64 -d | age --decrypt --identity "$identity_file" | base64 -w0)
    jq -n \
        --arg key "$key" \
        --arg wrapped "$wrapped" \
        '{keys:{encryption_key:$key, decryption_key:$key}, meta:{external_data:{wrapped:$wrapped}}}'
fi
