.PHONY: init plan apply destroy

init:
	cd opentofu/proxmox-vm && tofu init
	cd opentofu/cloudflare-tunnel && tofu init

plan:
	cd opentofu/proxmox-vm && tofu plan
	cd opentofu/cloudflare-tunnel && tofu plan

apply:
	cd opentofu/proxmox-vm && tofu apply
	cd opentofu/cloudflare-tunnel && tofu apply
	scripts/seal-cloudflared.sh
	cd ansible && ansible-playbook playbooks/site.yml

destroy:
	cd opentofu/cloudflare-tunnel && tofu destroy
	cd opentofu/proxmox-vm && tofu destroy
