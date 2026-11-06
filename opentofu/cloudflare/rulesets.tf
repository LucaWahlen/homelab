resource "cloudflare_ruleset" "cache" {
  zone_id = var.cloudflare_zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [
    {
      action      = "set_cache_settings"
      description = "S3 API host: bypass cache so Cloudflare never converts HEAD to GET (breaks SigV4-signed HEAD)"
      enabled     = true
      expression  = "(http.host eq \"s3.lucawahlen.com\")"
      action_parameters = {
        cache = false
      }
    }
  ]
}

resource "cloudflare_ruleset" "config" {
  zone_id = var.cloudflare_zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_config_settings"

  rules = [
    {
      action      = "set_config"
      description = "Block Email Obfuscation for Bedrock"
      enabled     = true
      expression  = "(not http.request.full_uri contains \"https://bedrock.lucawahlen.com\")"
      action_parameters = {
        email_obfuscation = false
      }
    }
  ]
}

resource "cloudflare_ruleset" "ratelimit" {
  zone_id = var.cloudflare_zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [
    {
      action      = "block"
      description = "Leaked credential check"
      enabled     = true
      expression  = "(cf.waf.credential_check.password_leaked)"
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 10
        requests_per_period = 5
        mitigation_timeout  = 10
      }
    }
  ]
}
