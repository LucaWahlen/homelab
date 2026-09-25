#!/usr/bin/env bash
# Renders every kustomization and validates it against the Kubernetes and CRD schemas.
set -euo pipefail
cd "$(dirname "$0")/.."

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R kubernetes "$work/"
rm -rf "$work/kubernetes/argocd/charts"

# The k3s version Renovate keeps up to date, e.g. v1.37.0+k3s1 -> 1.37.0.
k8s_version=$(yq '.k3s_version' ansible/inventory/group_vars/all.yml)
k8s_version=${k8s_version#v}
k8s_version=${k8s_version%%+*}

kubeconform=(
    kubeconform -strict -summary
    -kubernetes-version "$k8s_version"
    # No published schema exists for CRDs themselves.
    -skip CustomResourceDefinition
    -schema-location default
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
)

"${kubeconform[@]}" kubernetes/root.yaml

for dir in "$work"/kubernetes/root "$work"/kubernetes/argocd "$work"/kubernetes/apps/*; do
    echo "--- ${dir#"$work"/}"
    # ksops generators need the age key, which CI does not have.
    yq -i 'del(.generators)' "$dir/kustomization.yaml"
    kustomize build --enable-helm "$dir" | "${kubeconform[@]}" -
done
