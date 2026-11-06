variable "cloudflare_api_token" {
  description = "Cloudflare API token (Account: Cloudflare Tunnel: Edit; Zone: DNS, Config Rules, Cache Rules, Rate Limiting: Edit)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = "918313ddac1a5febb3798b7630b4b7d4"
}

variable "cloudflare_zone_id" {
  description = "Zone ID for lucawahlen.com"
  type        = string
  default     = "5a19f3bb1df1a405987998ac9f1773bb"
}

variable "domain" {
  description = "Domain to expose cluster services under"
  type        = string
  default     = "lucawahlen.com"
}

variable "tunnel_name" {
  description = "Name of the Cloudflare Tunnel"
  type        = string
  default     = "k3s"
}

variable "reverse_proxy_service" {
  description = "In-cluster reverse proxy address forwarded to by the tunnel"
  type        = string
  default     = "http://traefik.kube-system.svc.cluster.local:80"
}
