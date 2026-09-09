resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id    = var.cloudflare_account_id
  name          = var.tunnel_name
  config_src    = "cloudflare"
  tunnel_secret = random_id.tunnel_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  # v5 turned the config block into an object attribute and renamed
  # ingress_rule -> ingress.
  config = {
    # Every hostname under the domain goes to the in-cluster reverse proxy;
    # it does host-based routing per app from there via each app's Ingress.
    ingress = [
      {
        hostname = "*.${var.domain}"
        service  = var.reverse_proxy_service
      },
      {
        # Required catch-all - unmatched requests get a 404 instead of an error.
        service = "http_status:404"
      }
    ]
  }
}

# cloudflare v4 -> v5 renamed cloudflare_record to cloudflare_dns_record.
# Migrated with: tofu state mv cloudflare_record.wildcard cloudflare_dns_record.wildcard
# (v5 does not support moved blocks across these types.)
resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

