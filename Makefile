.PHONY: init plan apply destroy ansible-bootstrap

init:
	cd opentofu/proxmox-vm && tofu init
	cd opentofu/cloudflare-tunnel && tofu init

plan:
	cd opentofu/proxmox-vm && tofu plan
	cd opentofu/cloudflare-tunnel && tofu plan

apply:
	cd opentofu/proxmox-vm && tofu apply
	cd ansible && ansible-playbook playbooks/site.yml
	cd opentofu/cloudflare-tunnel && tofu apply

destroy:
	cd opentofu/cloudflare-tunnel && tofu destroy
	cd opentofu/proxmox-vm && tofu destroy
