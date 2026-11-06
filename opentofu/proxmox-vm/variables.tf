variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.178.210:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token ('user@realm!tokenid=uuid')"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for the Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

# Pinned to a dated release so the image is downloaded once; bumped by Renovate.
variable "cloud_image_url" {
  description = "Cloud-init disk image URL"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/20261103-2651/debian-13-genericcloud-amd64-20261103-2651.qcow2"
}

variable "cloud_image_file_name" {
  description = "Image filename on Proxmox (must end in .qcow2 for content_type import)"
  type        = string
  default     = "debian-13-genericcloud-amd64.qcow2"
}

variable "image_datastore_id" {
  description = "Proxmox datastore for the cloud image (requires 'Import' content type)"
  type        = string
  default     = "local"
}

variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
  default     = 100
}

variable "vm_name" {
  description = "VM hostname"
  type        = string
  default     = "k3s"
}

variable "vm_cores" {
  description = "Number of vCPUs"
  type        = number
  default     = 12
}

variable "vm_memory" {
  description = "RAM in MB"
  type        = number
  default     = 30720
}

variable "vm_disk_size" {
  description = "OS disk size in GB"
  type        = number
  default     = 32
}

variable "vm_data_disk_size" {
  description = "OpenEBS LVM data disk size in GB"
  type        = number
  default     = 200
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks and cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

# Fixed FritzBox ULA address; ISP prefix is dynamic.
variable "vm_ipv6_address" {
  description = "Static IPv6 address with prefix length"
  type        = string
  default     = "fd14:d507:58a5::234/64"
}

variable "vm_ip_address" {
  description = "Static IPv4 address"
  type        = string
  default     = "192.168.178.234"
}

variable "vm_subnet_mask" {
  description = "IPv4 subnet prefix length"
  type        = number
  default     = 24
}

variable "vm_gateway" {
  description = "IPv4 default gateway"
  type        = string
  default     = "192.168.178.1"
}

variable "vm_user" {
  description = "Cloud-init user account"
  type        = string
  default     = "debian"
}

variable "ssh_public_key" {
  description = "SSH public key for the VM user"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK872K+2ovo7CLGbqGzB+cCpJTGqfCbtDwYbQUpgrAqI luca-laptop"
}
