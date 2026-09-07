resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  config_src = "cloudflare"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config {
    # Every hostname under the domain goes to the in-cluster reverse proxy;
    # it does host-based routing per app from there via each app's Ingress.
    ingress_rule {
      hostname = "*.${var.domain}"
      service  = var.reverse_proxy_service
    }

    # Required catch-all - unmatched requests get a 404 instead of an error.
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = true
}

# Secret for the in-cluster cloudflared connector (apps/cloudflared). The
# namespace itself is owned by ArgoCD (CreateNamespace=true on the cloudflared
# Application) - managing it here too would collide with every ArgoCD sync,
# and this apply is documented to run after the Ansible bootstrap anyway.
resource "kubernetes_secret" "cloudflared_credentials" {
  metadata {
    name      = "cloudflared-credentials"
    namespace = var.cloudflared_namespace
  }

  data = {
    TUNNEL_TOKEN = cloudflare_zero_trust_tunnel_cloudflared.homelab.tunnel_token
  }
}
