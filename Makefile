STACKS := opentofu/proxmox-vm opentofu/cloudflare-tunnel

.PHONY: init plan infra seal bootstrap apply destroy lint

init:
	for s in $(STACKS); do tofu -chdir=$$s init || exit 1; done

plan:
	for s in $(STACKS); do sops exec-env $$s/secrets.enc.yaml "tofu -chdir=$$s plan" || exit 1; done

infra:
	for s in $(STACKS); do sops exec-env $$s/secrets.enc.yaml "tofu -chdir=$$s apply" || exit 1; done

# Commits and pushes the re-encrypted tunnel token to main when it changed,
# because Flux syncs from the remote.
seal:
	scripts/seal-cloudflared.sh

bootstrap:
	cd ansible && ansible-playbook site.yml

apply: infra seal bootstrap

destroy:
	for s in $(STACKS); do sops exec-env $$s/secrets.enc.yaml "tofu -chdir=$$s destroy" || exit 1; done

lint:
	lefthook run pre-commit --all-files --force
	lefthook run pre-push --all-files --force
