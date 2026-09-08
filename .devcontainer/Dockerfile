FROM registry.fedoraproject.org/fedora:43

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
    && dnf clean all

RUN useradd -u 1000 -ms /bin/bash vscode \
    && mkdir -p /home/vscode/.config/opencode /home/vscode/.local/share/opencode \
    && chown -R vscode:vscode /home/vscode

ENV PATH=/home/vscode/.opencode/bin:${PATH}
USER vscode
RUN VERSION=1.18.29 curl -fsSL https://opencode.ai/install | bash
USER vscode
