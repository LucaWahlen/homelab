output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.homelab.id
}

output "tunnel_token" {
  description = "Connector token for cloudflared - already written into the cluster as the cloudflared-credentials Secret, exposed here only for debugging."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.homelab.token
  sensitive   = true
}

output "wildcard_hostname" {
  value = cloudflare_record.wildcard.hostname
}
