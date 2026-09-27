FROM quay.io/fedora/fedora:46

RUN dnf -y install \
        git \
        make \
        openssh-clients \
        ansible-core \
        ansible-lint \
        yamllint \
        ShellCheck \
    && dnf clean all

RUN useradd -u 1000 -ms /bin/bash vscode \
    && mkdir -p /home/vscode/.config/opencode /home/vscode/.local/share/opencode \
    && chown -R vscode:vscode /home/vscode

# renovate: datasource=github-releases depName=kubernetes/kubernetes extractVersion=^v(?<version>.*)$
ARG KUBECTL_VERSION=1.37.1
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>.*)$
ARG HELM_VERSION=4.3.0
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize extractVersion=^kustomize/v(?<version>.*)$
ARG KUSTOMIZE_VERSION=5.8.1
# renovate: datasource=github-releases depName=viaduct-ai/kustomize-sops extractVersion=^v(?<version>.*)$
ARG KSOPS_VERSION=4.5.1
# renovate: datasource=github-releases depName=getsops/sops extractVersion=^v(?<version>.*)$
ARG SOPS_VERSION=3.13.3
# renovate: datasource=github-releases depName=opentofu/opentofu extractVersion=^v(?<version>.*)$
ARG OPENTOFU_VERSION=1.12.6
# renovate: datasource=github-releases depName=FiloSottile/age extractVersion=^v(?<version>.*)$
ARG AGE_VERSION=1.3.2
# renovate: datasource=github-releases depName=anomalyco/opencode extractVersion=^v(?<version>.*)$
ARG OPENCODE_VERSION=1.18.32
# renovate: datasource=github-releases depName=yannh/kubeconform extractVersion=^v(?<version>.*)$
ARG KUBECONFORM_VERSION=0.8.0
# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.*)$
ARG YQ_VERSION=4.53.6

RUN set -e; \
    case "$(uname -m)" in \
        x86_64)  k=amd64;  ks=x86_64; oc=x64   ;; \
        aarch64) k=arm64;  ks=arm64;  oc=arm64 ;; \
        *) echo "unsupported arch $(uname -m)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${k}/kubectl" -o /usr/local/bin/kubectl; \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${k}.tar.gz" | tar -xz -C /tmp; \
    mv "/tmp/linux-${k}/helm" /usr/local/bin/helm && rm -rf "/tmp/linux-${k}"; \
    curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${k}.tar.gz" | tar -xz -C /usr/local/bin kustomize; \
    curl -fsSL "https://github.com/viaduct-ai/kustomize-sops/releases/download/v${KSOPS_VERSION}/ksops_${KSOPS_VERSION}_Linux_${ks}.tar.gz" | tar -xz -C /usr/local/bin ksops; \
    curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${k}" -o /usr/local/bin/sops; \
    curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${k}.tar.gz" | tar -xz -C /usr/local/bin tofu; \
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${k}.tar.gz" | tar -xz -C /tmp; \
    mv "/tmp/age/age" "/tmp/age/age-keygen" /usr/local/bin/ && rm -rf "/tmp/age"; \
    curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${oc}.tar.gz" | tar -xz -C /usr/local/bin opencode; \
    curl -fsSL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-${k}.tar.gz" | tar -xz -C /usr/local/bin kubeconform; \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${k}" -o /usr/local/bin/yq; \
    chmod +x /usr/local/bin/kubectl /usr/local/bin/helm /usr/local/bin/kustomize /usr/local/bin/ksops /usr/local/bin/sops /usr/local/bin/tofu /usr/local/bin/age /usr/local/bin/age-keygen /usr/local/bin/opencode /usr/local/bin/kubeconform /usr/local/bin/yq