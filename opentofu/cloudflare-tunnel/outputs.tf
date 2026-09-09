output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.homelab.id
}

# v5 no longer exports the connector token from the tunnel resource; it moved
# to a read-only data source.
data "cloudflare_zero_trust_tunnel_cloudflared_token" "homelab" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id
}

output "tunnel_token" {
  description = "Connector token for cloudflared - seal it into Git with 'make seal-cloudflared' so ArgoCD applies it as the cloudflared-credentials Secret."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.homelab.token
  sensitive   = true
}

output "wildcard_hostname" {
  value = "*.${var.domain}"
}
