output "vm_id" {
  value = proxmox_virtual_environment_vm.k3s_node.vm_id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.k3s_node.name
}

output "vm_ip_address" {
  value = var.vm_ip_address
}
