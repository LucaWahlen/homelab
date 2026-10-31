FROM quay.io/fedora/fedora:46

RUN dnf -y install \
        git \
        jq \
        make \
        openssh-clients \
        ansible-core \
        ansible-lint \
        yamllint \
        ShellCheck \
    && dnf clean all

# renovate: datasource=galaxy-collection depName=community.general
ARG COMMUNITY_GENERAL_VERSION=13.5.0
RUN ansible-galaxy collection install --collections-path /usr/share/ansible/collections \
        "community.general==${COMMUNITY_GENERAL_VERSION}"

RUN useradd -u 1000 -ms /bin/bash vscode \
    && mkdir -p /home/vscode/.config/opencode /home/vscode/.local/share/opencode \
    && chown -R vscode:vscode /home/vscode

# renovate: datasource=github-releases depName=kubernetes/kubernetes extractVersion=^v(?<version>.*)$
ARG KUBECTL_VERSION=1.37.2
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>.*)$
ARG HELM_VERSION=4.3.1
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize extractVersion=^kustomize/v(?<version>.*)$
ARG KUSTOMIZE_VERSION=5.8.3
# renovate: datasource=github-releases depName=fluxcd/flux2 extractVersion=^v(?<version>.*)$
ARG FLUX_VERSION=2.10.0
# renovate: datasource=github-releases depName=getsops/sops extractVersion=^v(?<version>.*)$
ARG SOPS_VERSION=3.13.3
# renovate: datasource=github-releases depName=opentofu/opentofu extractVersion=^v(?<version>.*)$
ARG OPENTOFU_VERSION=1.13.2
# renovate: datasource=github-releases depName=FiloSottile/age extractVersion=^v(?<version>.*)$
ARG AGE_VERSION=1.3.2
# renovate: datasource=github-releases depName=yannh/kubeconform extractVersion=^v(?<version>.*)$
ARG KUBECONFORM_VERSION=0.8.0
# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.54.1
# renovate: datasource=github-releases depName=home-operations/flate extractVersion=^v(?<version>.*)$
ARG FLATE_VERSION=0.6.5
# renovate: datasource=github-releases depName=evilmartians/lefthook extractVersion=^v(?<version>.*)$
ARG LEFTHOOK_VERSION=2.2.2
# renovate: datasource=github-releases depName=stackrox/kube-linter extractVersion=^v(?<version>.*)$
ARG KUBE_LINTER_VERSION=0.8.3
# renovate: datasource=github-releases depName=aquasecurity/trivy extractVersion=^v(?<version>.*)$
ARG TRIVY_VERSION=0.76.1
# renovate: datasource=github-releases depName=gitleaks/gitleaks extractVersion=^v(?<version>.*)$
ARG GITLEAKS_VERSION=8.30.1
# renovate: datasource=github-releases depName=derailed/k9s extractVersion=^v(?<version>.*)$
ARG K9S_VERSION=0.51.0
# renovate: datasource=github-releases depName=anomalyco/opencode extractVersion=^v(?<version>.*)$
ARG OPENCODE_VERSION=2.2.5

# Every download is checked against the SHA-256 its project publishes. Where a
# release ships no usable checksum list, GitHub's recorded asset digest is used.
RUN set -eu; \
    case "$(uname -m)" in \
        x86_64)  k=amd64;  oc=x64;   tv=64bit; kl="";       lh=x86_64 ;; \
        aarch64) k=arm64;  oc=arm64; tv=ARM64; kl="_arm64"; lh=arm64  ;; \
        *) echo "unsupported arch $(uname -m)" >&2; exit 1 ;; \
    esac; \
    gh=https://github.com; \
    listed() { curl -fsSL "$1" | awk -v f="$2" '$2 == f || $2 == "*" f { print $1 }'; }; \
    digest() { curl -fsSL "https://api.github.com/repos/$1/releases/tags/$2" \
        | jq -r --arg f "$3" '.assets[] | select(.name == $f) | .digest | ltrimstr("sha256:")'; }; \
    fetch() { \
        [ -n "$2" ] || { echo "no checksum for $1" >&2; exit 1; }; \
        curl -fsSL "$1" -o "$3"; \
        echo "$2  $3" | sha256sum --check --quiet -; \
    }; \
    dl=$(mktemp -d); cd "$dl"; \
    u="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${k}"; \
    fetch "$u/kubectl" "$(curl -fsSL "$u/kubectl.sha256")" /usr/local/bin/kubectl; \
    f="helm-v${HELM_VERSION}-linux-${k}.tar.gz"; \
    fetch "https://get.helm.sh/$f" "$(listed "https://get.helm.sh/$f.sha256sum" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin --strip-components=1 "linux-${k}/helm"; \
    u="$gh/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}"; f="kustomize_v${KUSTOMIZE_VERSION}_linux_${k}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/checksums.txt" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin kustomize; \
    u="$gh/fluxcd/flux2/releases/download/v${FLUX_VERSION}"; f="flux_${FLUX_VERSION}_linux_${k}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/flux_${FLUX_VERSION}_checksums.txt" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin flux; \
    u="$gh/getsops/sops/releases/download/v${SOPS_VERSION}"; f="sops-v${SOPS_VERSION}.linux.${k}"; \
    fetch "$u/$f" "$(listed "$u/sops-v${SOPS_VERSION}.checksums.txt" "$f")" /usr/local/bin/sops; \
    u="$gh/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}"; f="tofu_${OPENTOFU_VERSION}_linux_${k}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/tofu_${OPENTOFU_VERSION}_SHA256SUMS" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin tofu; \
    f="age-v${AGE_VERSION}-linux-${k}.tar.gz"; \
    fetch "$gh/FiloSottile/age/releases/download/v${AGE_VERSION}/$f" "$(digest FiloSottile/age "v${AGE_VERSION}" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin --strip-components=1 age/age age/age-keygen; \
    f="opencode-linux-${oc}.tar.gz"; \
    fetch "$gh/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/$f" "$(digest anomalyco/opencode "v${OPENCODE_VERSION}" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin opencode; \
    u="$gh/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}"; f="kubeconform-linux-${k}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/CHECKSUMS" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin kubeconform; \
    f="yq_linux_${k}"; \
    fetch "$gh/mikefarah/yq/releases/download/v${YQ_VERSION}/$f" "$(digest mikefarah/yq "v${YQ_VERSION}" "$f")" /usr/local/bin/yq; \
    u="$gh/home-operations/flate/releases/download/v${FLATE_VERSION}"; f="flate_${FLATE_VERSION}_linux_${k}.tar.gz"; \
    fetch "$u/$f" "$(curl -fsSL "$u/$f.sha256")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin flate; \
    u="$gh/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}"; f="lefthook_${LEFTHOOK_VERSION}_Linux_${lh}.gz"; \
    fetch "$u/$f" "$(listed "$u/lefthook_checksums.txt" "$f")" "$f"; \
    gunzip -c "$f" > /usr/local/bin/lefthook; \
    f="kube-linter-linux${kl}.tar.gz"; \
    fetch "$gh/stackrox/kube-linter/releases/download/v${KUBE_LINTER_VERSION}/$f" "$(digest stackrox/kube-linter "v${KUBE_LINTER_VERSION}" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin kube-linter; \
    u="$gh/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}"; f="trivy_${TRIVY_VERSION}_Linux-${tv}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/trivy_${TRIVY_VERSION}_checksums.txt" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin trivy; \
    u="$gh/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}"; f="gitleaks_${GITLEAKS_VERSION}_linux_${oc}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/gitleaks_${GITLEAKS_VERSION}_checksums.txt" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin gitleaks; \
    u="$gh/derailed/k9s/releases/download/v${K9S_VERSION}"; f="k9s_Linux_${k}.tar.gz"; \
    fetch "$u/$f" "$(listed "$u/checksums.sha256" "$f")" "$f"; \
    tar -xzf "$f" -C /usr/local/bin k9s; \
    cd /; rm -rf "$dl"; \
    chmod +x /usr/local/bin/kubectl /usr/local/bin/helm /usr/local/bin/kustomize /usr/local/bin/flux /usr/local/bin/sops /usr/local/bin/tofu /usr/local/bin/age /usr/local/bin/age-keygen /usr/local/bin/opencode /usr/local/bin/kubeconform /usr/local/bin/yq /usr/local/bin/flate /usr/local/bin/lefthook /usr/local/bin/kube-linter /usr/local/bin/trivy /usr/local/bin/gitleaks /usr/local/bin/k9s

# k9s Vercel skin from the same release; selected with K9S_SKIN in devcontainer.json.
RUN mkdir -p /home/vscode/.config/k9s/skins \
    && curl -fsSL "https://raw.githubusercontent.com/derailed/k9s/v${K9S_VERSION}/skins/vercel.yaml" \
        -o /home/vscode/.config/k9s/skins/vercel.yaml \
    && chown -R vscode:vscode /home/vscode/.config
