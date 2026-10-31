variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://proxmox.example.lan:8006/"
  type        = string
  default     = "https://192.168.178.210:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form 'user@realm!tokenid=uuid'"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for the Proxmox API (needed for self-signed certs)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Name of the Proxmox node to deploy the VM on"
  type        = string
  default     = "pve"
}

# Pinned to a dated Debian release rather than .../trixie/latest/... so the image
# is fetched only once. Renovate bumps the version (see renovate.json); `url` is
# a ForceNew attribute, so a bump replaces the resource and re-downloads the new
# image automatically on the next apply.
variable "cloud_image_url" {
  description = "URL of the cloud-init-ready disk image OpenTofu downloads onto the Proxmox node and boots the VM from"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/20261026-2643/debian-13-genericcloud-amd64-20261026-2643.qcow2"
}

variable "cloud_image_file_name" {
  description = "File name for the image on Proxmox; must end in .qcow2 for content_type import (Debian's genericcloud image is qcow2). Kept unversioned so the VM disk's import_from does not change when the pinned release is bumped"
  type        = string
  default     = "debian-13-genericcloud-amd64.qcow2"
}

variable "image_datastore_id" {
  description = "Proxmox datastore to download the cloud image onto (needs the 'Import' content type enabled, e.g. the default 'local')"
  type        = string
  default     = "local"
}

variable "vm_id" {
  description = "VM ID to assign to the new VM"
  type        = number
  default     = 100
}

variable "vm_name" {
  description = "Name/hostname of the VM"
  type        = string
  default     = "k3s"
}

variable "vm_cores" {
  description = "Number of vCPUs for the VM"
  type        = number
  default     = 12
}

variable "vm_memory" {
  description = "RAM for the VM, in MB"
  type        = number
  default     = 30720
}

variable "vm_disk_size" {
  description = "Disk size for the VM, in GB"
  type        = number
  default     = 32
}

variable "vm_data_disk_size" {
  description = "Size of the data disk backing the OpenEBS LVM volume group, in GB"
  type        = number
  default     = 200
}

variable "storage_pool" {
  description = "Proxmox storage pool to use for the VM disk and cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge to attach the VM to"
  type        = string
  default     = "vmbr0"
}

# From the FritzBox's ULA prefix, which stays fixed; the provider's 2003:...
# prefix changes, so an address in it stops working. Statically assigned so it
# never depends on the (random) NIC MAC. Blocky listens on it for DNS (see
# kubernetes/apps/blocky/config.yaml).
variable "vm_ipv6_address" {
  description = "Static IPv6 address (with prefix length) for the VM"
  type        = string
  default     = "fd14:d507:58a5::234/64"
}

variable "vm_ip_address" {
  description = "Static IPv4 address for the VM, e.g. 192.168.1.50"
  type        = string
  default     = "192.168.178.234"
}

variable "vm_subnet_mask" {
  description = "Subnet mask in CIDR bits, e.g. 24"
  type        = number
  default     = 24
}

variable "vm_gateway" {
  description = "Default gateway for the VM's network, e.g. 192.168.1.1"
  type        = string
  default     = "192.168.178.1"
}

variable "vm_user" {
  description = "Default user account created on the VM via cloud-init"
  type        = string
  default     = "debian"
}

variable "ssh_public_key" {
  description = "Your SSH public key contents, e.g. file(\"~/.ssh/id_ed25519.pub\")"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK872K+2ovo7CLGbqGzB+cCpJTGqfCbtDwYbQUpgrAqI luca-laptop"
}
