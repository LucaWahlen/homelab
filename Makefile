STACKS := opentofu/proxmox-vm opentofu/cloudflare-tunnel

.PHONY: init plan infra seal bootstrap apply destroy lint

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

# Everything lint-related lives in lefthook.yml and runs via git hooks too.
lint:
	lefthook run pre-commit --all-files --force
	lefthook run pre-push --all-files --force
