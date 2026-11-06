# Records owned by other systems are omitted so OpenTofu never overwrites them:
#   - *.lucawahlen.com        tunnel CNAME, defined in main.tf
#   - mail.lucawahlen.com A   updated dynamically by cloudflare-ddns
#   - _acme-challenge.*       managed by cert-manager for DNS-01
#
# Names are relative to the zone ("@" for apex); TXT values include surrounding quotes.
locals {
  dns_records = {
    # Proton Mail DKIM
    "protonmail._domainkey" = {
      name    = "protonmail._domainkey"
      type    = "CNAME"
      content = "protonmail.domainkey.dlthhqjv75ayhxgc3gyffefcy3zct45ytzipci3c5w5gcmpn7sv5a.domains.proton.ch"
    }
    "protonmail2._domainkey" = {
      name    = "protonmail2._domainkey"
      type    = "CNAME"
      content = "protonmail2.domainkey.dlthhqjv75ayhxgc3gyffefcy3zct45ytzipci3c5w5gcmpn7sv5a.domains.proton.ch"
    }
    "protonmail3._domainkey" = {
      name    = "protonmail3._domainkey"
      type    = "CNAME"
      content = "protonmail3.domainkey.dlthhqjv75ayhxgc3gyffefcy3zct45ytzipci3c5w5gcmpn7sv5a.domains.proton.ch"
    }
    "dkim._domainkey.alias" = {
      name    = "dkim._domainkey.alias"
      type    = "CNAME"
      content = "dkim._domainkey.alias.proton.me"
    }
    "dkim02._domainkey.alias" = {
      name    = "dkim02._domainkey.alias"
      type    = "CNAME"
      content = "dkim02._domainkey.alias.proton.me"
    }
    "dkim03._domainkey.alias" = {
      name    = "dkim03._domainkey.alias"
      type    = "CNAME"
      content = "dkim03._domainkey.alias.proton.me"
    }

    # Proton Mail MX (apex and alias subdomain)
    "apex-mx-primary" = {
      name     = "@"
      type     = "MX"
      content  = "mail.protonmail.ch"
      priority = 10
    }
    "apex-mx-secondary" = {
      name     = "@"
      type     = "MX"
      content  = "mailsec.protonmail.ch"
      priority = 20
    }
    "alias-mx-primary" = {
      name     = "alias"
      type     = "MX"
      content  = "mx1.alias.proton.me"
      priority = 10
    }
    "alias-mx-secondary" = {
      name     = "alias"
      type     = "MX"
      content  = "mx2.alias.proton.me"
      priority = 20
    }

    # SPF / verification / DMARC
    "apex-spf" = {
      name    = "@"
      type    = "TXT"
      content = "\"v=spf1 include:_spf.protonmail.ch ~all\""
    }
    "apex-protonmail-verification" = {
      name    = "@"
      type    = "TXT"
      content = "\"protonmail-verification=86c90956a19d7921562055f52b9461609f65c262\""
    }
    "alias-spf" = {
      name    = "alias"
      type    = "TXT"
      content = "\"v=spf1 include:alias.proton.me ~all\""
    }
    "alias-pm-verification" = {
      name    = "alias"
      type    = "TXT"
      content = "\"pm-verification=fxyjmmkjersdjgfkfsqlwludougwae\""
    }
    "dmarc-apex" = {
      name    = "_dmarc"
      type    = "TXT"
      content = "\"v=DMARC1; p=quarantine; rua=mailto:83b80e81363a4f6e940912047ef25e65@dmarc-reports.cloudflare.net;\""
    }
    "dmarc-alias" = {
      name    = "_dmarc.alias"
      type    = "TXT"
      content = "\"v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s\""
    }
    "dmarc-mail" = {
      name    = "_dmarc.mail"
      type    = "TXT"
      content = "\"v=DMARC1; p=none\""
      comment = "Maddy Mailserver"
    }

    # maddy (send-only) at mail.lucawahlen.com
    "mail-spf" = {
      name    = "mail"
      type    = "TXT"
      content = "\"v=spf1 a:mail.lucawahlen.com ~all\""
      comment = "Maddy Mailserver"
    }
    "mail-dkim" = {
      name    = "default._domainkey.mail"
      type    = "TXT"
      content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwQER+8HvJH3fh8w886wtSjANLvKZiMSZ1I0kKytv01wFonvsz1GBpGD0fImLbOgD6Aw/uSqg77tuWjp0J3NCgMBlp+UzSnhUqhmmuUSH2bH2gJ9A1zD8YZtOqmtowvRrdJ5Eug6eGYdPpIm7PT/MqUkaD+MOaJSAUTzipAZEa+VxSc6f4Iw47jQ6RhJgSKCWZ\" \"HfmtxmlxlYfD1+oE13Gbkp0YA+1ke+wYewRKP7MYtQui/cC3oFiWVAt0LT4A8u27/urZZPNBRCTPYRniLZVd/Gd7xwJNk6ZNgOHicCJ01HqUDAwS8n1YlM0f8PiBnfbkydB4VlOUVsUi9lmokeKywIDAQAB\""
      comment = "Maddy Mailserver"
    }
  }
}

resource "cloudflare_dns_record" "records" {
  for_each = local.dns_records

  zone_id  = var.cloudflare_zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  ttl      = try(each.value.ttl, 1)
  proxied  = try(each.value.proxied, false)
  priority = try(each.value.priority, null)
  comment  = try(each.value.comment, null)
}
