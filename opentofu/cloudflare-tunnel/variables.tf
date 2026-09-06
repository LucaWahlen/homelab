variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zero Trust: Edit and DNS: Edit permissions on the zone/account"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for the domain (lucawahlen.com)"
  type        = string
}

variable "domain" {
  description = "Domain to expose cluster services under, e.g. *.lucawahlen.com"
  type        = string
  default     = "lucawahlen.com"
}

variable "tunnel_name" {
  description = "Name of the Cloudflare Tunnel"
  type        = string
  default     = "homelab"
}

variable "reverse_proxy_service" {
  description = "In-cluster address of the reverse proxy the tunnel forwards all hostnames to (k3s's built-in Traefik by default)"
  type        = string
  default     = "http://traefik.kube-system.svc.cluster.local:80"
}

variable "kubeconfig_path" {
  description = "Path to the cluster kubeconfig produced by the Ansible bootstrap (run that first)"
  type        = string
  default     = "../../ansible/kubeconfig"
}

variable "cloudflared_namespace" {
  description = "Namespace the cloudflared connector runs in - must match apps/cloudflared/manifests"
  type        = string
  default     = "cloudflared"
}
