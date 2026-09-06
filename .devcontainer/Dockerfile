FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://get.opentofu.org/opentofu.gpg -o /etc/apt/keyrings/opentofu.gpg \
    && curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
        | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg \
    && chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" \
        > /etc/apt/sources.list.d/opentofu.list \
    && chmod a+r /etc/apt/sources.list.d/opentofu.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends tofu ansible-core \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/vscode/.config/opencode /home/vscode/.local/share/opencode \
    && chown -R vscode:vscode /home/vscode/.config /home/vscode/.local

ENV PATH=/home/vscode/.opencode/bin:${PATH}
USER vscode
RUN VERSION=1.18.29 curl -fsSL https://opencode.ai/install | bash
USER root
