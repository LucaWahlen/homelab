# One-shot import blocks used to adopt the pre-existing Cloudflare resources
# into state. They are no-ops once imported; kept as a record of the original
# IDs. Remove them once everything is managed.

locals {
  zone_id = var.cloudflare_zone_id
}

import {
  to = cloudflare_dns_record.records["alias-mx-secondary"]
  id = "${local.zone_id}/b0e8b5cddd325faba8cf9dd78d598289"
}

import {
  to = cloudflare_dns_record.records["dkim03._domainkey.alias"]
  id = "${local.zone_id}/bfc8450cc19bb3e1d9a9524edd418993"
}

import {
  to = cloudflare_dns_record.records["dmarc-alias"]
  id = "${local.zone_id}/4c20780d99f2edd6349a9acf8fd32336"
}

import {
  to = cloudflare_dns_record.records["apex-mx-secondary"]
  id = "${local.zone_id}/1b552055ef1867f7802542bad8b9973f"
}

import {
  to = cloudflare_dns_record.records["apex-mx-primary"]
  id = "${local.zone_id}/c5854f1066fd09148642d007277f6569"
}

import {
  to = cloudflare_dns_record.records["protonmail._domainkey"]
  id = "${local.zone_id}/baf44f5ccea254823b5925553de14d9d"
}

import {
  to = cloudflare_dns_record.records["alias-spf"]
  id = "${local.zone_id}/56d25c63ab3e957e8e7c672f128be4c2"
}

import {
  to = cloudflare_dns_record.records["apex-spf"]
  id = "${local.zone_id}/7c33392edffb0b18a11732d47448c783"
}

import {
  to = cloudflare_dns_record.records["alias-mx-primary"]
  id = "${local.zone_id}/867934c9e7dc71ec8d8b5c5c37e1d4fc"
}

import {
  to = cloudflare_dns_record.records["apex-protonmail-verification"]
  id = "${local.zone_id}/07d97ea51a93b49638790286aabe4290"
}

import {
  to = cloudflare_dns_record.records["mail-dkim"]
  id = "${local.zone_id}/2e017141c1642cb0482231e0fdcd9337"
}

import {
  to = cloudflare_dns_record.records["dkim02._domainkey.alias"]
  id = "${local.zone_id}/3c3a5bb57753ddfd3e231fc94b089f1d"
}

import {
  to = cloudflare_dns_record.records["protonmail2._domainkey"]
  id = "${local.zone_id}/20c5d627351b8f269b7d2957a294384b"
}

import {
  to = cloudflare_dns_record.records["dmarc-mail"]
  id = "${local.zone_id}/97120c4ae57bf64d9bf069027fb36063"
}

import {
  to = cloudflare_dns_record.records["dkim._domainkey.alias"]
  id = "${local.zone_id}/7276912b896a8a1ec7e1667b94bfccfd"
}

import {
  to = cloudflare_dns_record.records["mail-spf"]
  id = "${local.zone_id}/191d9b79cb6a07acbf13540dcfc5cc21"
}

import {
  to = cloudflare_dns_record.records["alias-pm-verification"]
  id = "${local.zone_id}/fdfc74bdddf754d99931468f80df65c5"
}

import {
  to = cloudflare_dns_record.records["dmarc-apex"]
  id = "${local.zone_id}/00f39c7ed9a480f374e602a9ce0b0bd6"
}

import {
  to = cloudflare_dns_record.records["protonmail3._domainkey"]
  id = "${local.zone_id}/c258eb1a2a5d912faaa368a105ef028b"
}

import {
  to = cloudflare_ruleset.cache
  id = "zones/${local.zone_id}/f1800951cd964cc0898a5ab6e42c9f0c"
}

import {
  to = cloudflare_ruleset.config
  id = "zones/${local.zone_id}/63a52e019e2f4f82ac0ae77cd577455c"
}

import {
  to = cloudflare_ruleset.ratelimit
  id = "zones/${local.zone_id}/ec9e9aba45f546e9ad75e5ff94d4c4e1"
}
