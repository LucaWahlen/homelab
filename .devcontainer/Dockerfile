FROM registry.fedoraproject.org/fedora:44

RUN dnf -y install \
        git \
        curl \
        unzip \
        tar \
        less \
        make \
        procps \
        openssh-clients \
        ansible-core \
        opentofu \
        age \
        python3-bcrypt \
    && dnf clean all

# Pinned operator tooling: kubectl applies, kustomize renders the ArgoCD
# bootstrap (its helmCharts path needs helm v3 - v4 dropped a flag kustomize
# uses), ksops decrypts sealed secrets during local builds, sops seals them.
# (sops has age support built in; the dnf 'age' package only provides
# age-keygen.)
RUN set -e; \
    case "$(uname -m)" in \
        x86_64)  k=amd64;  ks=x86_64 ;; \
        aarch64) k=arm64;  ks=arm64  ;; \
    esac; \
    curl -fsSL "https://dl.k8s.io/release/v1.30.5/bin/linux/${k}/kubectl" -o /usr/local/bin/kubectl; \
    curl -fsSL "https://get.helm.sh/helm-v3.18.4-linux-${k}.tar.gz" | tar -xz -C /tmp; \
    mv "/tmp/linux-${k}/helm" /usr/local/bin/helm; \
    curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.5.0/kustomize_v5.5.0_linux_${k}.tar.gz" | tar -xz -C /usr/local/bin kustomize; \
    curl -fsSL "https://github.com/viaduct-ai/kustomize-sops/releases/download/v4.5.1/ksops_4.5.1_Linux_${ks}.tar.gz" | tar -xz -C /usr/local/bin ksops; \
    curl -fsSL "https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.${k}" -o /usr/local/bin/sops; \
    chmod +x /usr/local/bin/kubectl /usr/local/bin/helm /usr/local/bin/kustomize /usr/local/bin/ksops /usr/local/bin/sops

RUN useradd -u 1000 -ms /bin/bash vscode \
    && mkdir -p /home/vscode/.config/opencode /home/vscode/.local/share/opencode \
    && chown -R vscode:vscode /home/vscode

ENV PATH=/home/vscode/.opencode/bin:${PATH}
USER vscode
RUN VERSION=1.18.29 curl -fsSL https://opencode.ai/install | bash
USER vscode
