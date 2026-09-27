STACKS := opentofu/proxmox-vm opentofu/cloudflare-tunnel

.PHONY: init plan infra seal bootstrap apply destroy lint lint-tofu lint-yaml lint-ansible lint-shell lint-sops lint-k8s

init:
	for s in $(STACKS); do tofu -chdir=$$s init || exit 1; done

plan:
	for s in $(STACKS); do tofu -chdir=$$s plan || exit 1; done

infra:
	for s in $(STACKS); do tofu -chdir=$$s apply || exit 1; done

seal:
	scripts/seal-cloudflared.sh

bootstrap:
	cd ansible && ansible-playbook site.yml

apply: infra seal bootstrap

destroy:
	tofu -chdir=opentofu/proxmox-vm destroy
	tofu -chdir=opentofu/cloudflare-tunnel destroy

lint: lint-tofu lint-yaml lint-ansible lint-shell lint-sops lint-k8s

lint-tofu:
	tofu fmt -check -recursive opentofu
	for s in $(STACKS); do \
		tofu -chdir=$$s init -backend=false -input=false -lockfile=readonly >/dev/null && \
		tofu -chdir=$$s validate || exit 1; \
	done

lint-yaml:
	yamllint --strict .

lint-ansible:
	cd ansible && ansible-lint

lint-shell:
	shellcheck scripts/*.sh

lint-sops:
	scripts/check-sops.sh

lint-k8s:
	scripts/render-manifests.sh
