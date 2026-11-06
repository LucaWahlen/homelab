#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rendered=$(mktemp "${TMPDIR:-/tmp}/flate-manifests-XXXXXX.yaml")
trap 'rm -f "$rendered"' EXIT

flate build all --path ./kubernetes >"$rendered"

k8s_version=$(yq '.k3s_version' ansible/inventory/group_vars/all.yml)
k8s_version=${k8s_version#v}
k8s_version=${k8s_version%%+*}

# Skip CustomResourceDefinition (no upstream schema) and VLAgent (CRD catalog lags k8sCollector).
kubeconform -strict -summary \
    -kubernetes-version "$k8s_version" \
    -skip CustomResourceDefinition,VLAgent \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    "$rendered"

echo "--- kube-linter ---"
kube-linter lint "$rendered" || true
echo "--- trivy config ---"
trivy config --quiet --severity HIGH,CRITICAL "$rendered" || true
