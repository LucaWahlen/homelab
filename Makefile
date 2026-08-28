.PHONY: tf-init tf-plan tf-apply tf-destroy ansible-bootstrap \
        tunnel-init tunnel-plan tunnel-apply tunnel-destroy

TF_DIR := opentofu/proxmox-vm
TUNNEL_DIR := opentofu/cloudflare-tunnel
ANSIBLE_DIR := ansible

tf-init:
	cd $(TF_DIR) && tofu init

tf-plan:
	cd $(TF_DIR) && tofu plan

tf-apply:
	cd $(TF_DIR) && tofu apply

tf-destroy:
	cd $(TF_DIR) && tofu destroy

ansible-bootstrap:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yml

tunnel-init:
	cd $(TUNNEL_DIR) && tofu init

tunnel-plan:
	cd $(TUNNEL_DIR) && tofu plan

# Requires ansible-bootstrap to have run first (needs ansible/kubeconfig).
tunnel-apply:
	cd $(TUNNEL_DIR) && tofu apply

tunnel-destroy:
	cd $(TUNNEL_DIR) && tofu destroy
