#!/usr/bin/env bash
# Renders every kustomization and validates it against the Kubernetes and CRD schemas.
set -euo pipefail
cd "$(dirname "$0")/.."

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R kubernetes "$work/"
find "$work/kubernetes" -type d -name charts -prune -exec rm -rf {} +

# The k3s version Renovate keeps up to date, e.g. v1.37.0+k3s1 -> 1.37.0.
k8s_version=$(yq '.k3s_version' ansible/inventory/group_vars/all.yml)
k8s_version=${k8s_version#v}
k8s_version=${k8s_version%%+*}

# No published schema exists for CRDs themselves.
# VLAgent's catalog schema lags the operator (missing spec.k8sCollector);
# it is chart-owned rather than authored here, so skip it.
# Flux CRDs are validated by the flux CLI, not kubeconform.
skip_kinds=CustomResourceDefinition,VLAgent,Kustomization,GitRepository,HelmRelease,HelmRepository

kubeconform=(
    kubeconform -strict -summary
    -kubernetes-version "$k8s_version"
    -skip "$skip_kinds"
    -schema-location default
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
)

"${kubeconform[@]}" kubernetes/root.yaml kubernetes/root

# Every directory with a kustomization, including nested ones (e.g. cert-manager/issuers).
while IFS= read -r dir; do
    echo "--- ${dir#"$work"/}"
    # Flux decrypts the *.enc.yaml secrets at reconcile time; strip the SOPS
    # metadata so the rendered Secret validates as a plain Kubernetes object.
    kustomize build --enable-helm "$dir" | yq 'del(.sops)' | "${kubeconform[@]}" -
done < <(find "$work/kubernetes/apps" -name kustomization.yaml -printf '%h\n' | sort)
