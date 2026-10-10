#!/usr/bin/env bash
# Renders the Flux graph offline with flate (HelmReleases included), validates it
# against the Kubernetes and CRD schemas with kubeconform, then runs the advisory
# security/best-practice scanners over the same rendered output.
set -euo pipefail
cd "$(dirname "$0")/.."

rendered=$(mktemp "${TMPDIR:-/tmp}/flate-manifests-XXXXXX.yaml")
trap 'rm -f "$rendered"' EXIT

# Renders every Kustomization and HelmRelease exactly like Flux would, offline.
flate build all --path ./kubernetes >"$rendered"

# The k3s version Renovate keeps up to date, e.g. v1.37.1+k3s1 -> 1.37.1.
k8s_version=$(yq '.k3s_version' ansible/inventory/group_vars/all.yml)
k8s_version=${k8s_version#v}
k8s_version=${k8s_version%%+*}

# No published schema exists for CRDs themselves. VLAgent's catalog schema lags
# the operator (missing spec.k8sCollector); it is chart-owned rather than
# authored here, so skip it.
kubeconform -strict -summary \
    -kubernetes-version "$k8s_version" \
    -skip CustomResourceDefinition,VLAgent \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    "$rendered"

# Advisory scanners: they flag upstream chart defaults (resource requests,
# hostPath, securityContext) as well as authored mistakes, so they report but do
# not fail. Promote either by dropping `|| true` (trivy: add --exit-code 1).
echo "--- kube-linter ---"
kube-linter lint "$rendered" || true
echo "--- trivy config ---"
trivy config --quiet --severity HIGH,CRITICAL "$rendered" || true
