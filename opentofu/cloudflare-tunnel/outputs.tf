output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.homelab.id
}

output "tunnel_token" {
  description = "Connector token for cloudflared - seal it into Git with 'make seal-cloudflared' so ArgoCD applies it as the cloudflared-credentials Secret."
  value       = cloudflare_zero_trust_tunnel_cloudflared.homelab.tunnel_token
  sensitive   = true
}

output "wildcard_hostname" {
  value = cloudflare_record.wildcard.hostname
}
