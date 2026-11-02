# Stalwart

Self-hosted Stalwart at `mail.lucawahlen.com` for **sending and receiving**.
It replaces Resend for Bedrock. The root domain stays on Proton; only the
`mail.lucawahlen.com` subdomain belongs to this server.

## What is exposed

| Port | Purpose | Where |
|---|---|---|
| 25 | MX / server-to-server | public, via `stalwart-mail` LoadBalancer |
| 465 | Submission, implicit TLS | public |
| 587 | Submission, STARTTLS | optional; no listener by default |
| 993 | IMAPS | public |
| 80 | WebUI over HTTP + ACME HTTP-01 | public, Traefik → `stalwart` service |
| 443 | WebUI over HTTPS | LAN via Traefik; `https://mail.lucawahlen.com/admin` |
| 8080 | WebUI / management | cluster only (backend for the Ingress) |

`stalwart-mail` is a `LoadBalancer`, so k3s ServiceLB binds the mail ports on
the node. Forward them from the FritzBox to the node's LAN address
(`192.168.178.234`). Port 8080 is deliberately not in that Service.

## Prerequisites

- A real public IPv4 (not CGNAT/DS-Lite) and outbound TCP 25 open.
- FritzBox port forwards: `25`, `80`, `465`, `587`, `993` → `192.168.178.234`.
- The ISP must set the PTR for that IP to `mail.lucawahlen.com`:

  ```bash
  WAN=$(curl -4 -fsS https://api.ipify.org)
  echo "$WAN"
  # Query a public resolver: once the blocky split-horizon mapping is applied,
  # the LAN resolver intentionally returns 192.168.178.234 instead.
  dig +short @1.1.1.1 mail.lucawahlen.com   # must be $WAN, not 104.21.x/172.67.x
  dig -x "$WAN" +short                      # must be mail.lucawahlen.com
  nc -4 -vz gmail-smtp-in.l.google.com 25   # -4 matters: the IPv6 path proves nothing
  ```

  The `dig` result must be the WAN address. The `*.lucawahlen.com` wildcard is
  a **proxied** Cloudflare tunnel CNAME, so until an explicit, DNS-only `mail`
  A record exists, `mail` resolves to Cloudflare proxy IPs and SMTP/IMAP never
  reach the cluster.

  If the FritzBox WAN address is in `100.64.0.0/10`, you are behind CGNAT and
  inbound IPv4 is impossible. A PTR such as
  `p5b2e8c29.dip0.t-ipconnect.de` is Telekom's dynamic consumer pool: it will
  not match `mail.lucawahlen.com`, and those ranges are commonly on Spamhaus
  PBL. Receiving still works; outbound delivery will be unreliable until you
  have a static IP with a PTR you can set (or a relay).

- **FritzBox DNS rebind protection**: blocky answers `mail.lucawahlen.com`
  with the node's private address (`192.168.178.234`) for split-horizon.
  FRITZ!OS suppresses private answers for public names by default, which
  shows up in the browser as `ERR_NAME_NOT_RESOLVED`. Add
  `mail.lucawahlen.com` under **Heimnetz → Netzwerk → Netzwerkeinstellungen →
  DNS-Rebind-Schutz → Ausnahme hinzufügen**.

## First boot

The WebUI is served at <https://mail.lucawahlen.com/admin>. On the LAN, blocky
resolves `mail` to the node, and the `mail` Ingress presents a cert-manager
certificate for that hostname. The server's `STALWART_PUBLIC_URL` is set to
the same URL, which is what makes the OAuth sign-in work.

Sign in as `admin` with the password from:

```bash
sops -d kubernetes/apps/stalwart/secret.enc.yaml | grep STALWART_RECOVERY_ADMIN
```

Create a permanent administrator account, then remove
`STALWART_RECOVERY_ADMIN` from `secret.enc.yaml` and let Flux reconcile. Keep
the key only for lockout recovery.

## Minimal Stalwart configuration

All of this is stored in the RocksDB database on the PVC, not in Git.

1. **System settings** → hostname `mail.lucawahlen.com`. Do this before
   sending: the default SMTP banner is the pod name (`stalwart-0`).
2. **Domains** → add `mail.lucawahlen.com`.
3. **Accounts**:
   - `bedrock@mail.lucawahlen.com`, with the password from the Bedrock secret:
     ```bash
     sops -d kubernetes/apps/bedrock/secret.enc.yaml | grep SMTP_PASSWORD
     ```
   - your own mailbox, for example `redacted@example.com`.
4. **Listeners**: 25, 465 and 993 already exist. Bedrock uses **465 with
   implicit TLS**; no 587 listener is needed. If you created one, delete it —
   especially do not leave a second listener on 465 next to the default
   `submissions` one.
5. **TLS**: create an ACME provider (Let's Encrypt, `Http01`, your contact
   email), then set the domain's certificate management to Automatic with that
   provider. The `mail` Ingress serves the WebUI and passes
   `/.well-known/acme-challenge` to Stalwart, so no port 80 listener is needed
   inside Stalwart. Stalwart renews the mail certificate itself; the WebUI's
   separate certificate (`stalwart-web-tls`) is managed by cert-manager.
6. **DKIM**: create a key for the domain and publish the TXT record it shows.
7. **Outbound**: no relay/smarthost. On the default `mx` route, set the IP
   lookup strategy to IPv4-only so the sending IP, SPF and PTR stay
   consistent. The server hostname is the EHLO name.
8. **Spam filtering**: keep the default SPF/DKIM/DMARC and DNSBL checks.

## DNS records (Cloudflare)

Only the `mail` subdomain changes. Leave the root `lucawahlen.com` MX pointing
at Proton.

| Type | Name (Cloudflare field) | Content / target | Priority | TTL | Proxy |
|---|---|---|---|---|---|
| A | `mail` | `91.46.140.41` (your WAN IPv4) | — | Auto (300) | **DNS only** |
| MX | `mail` | `mail.lucawahlen.com` | `10` | Auto (300) | n/a |
| TXT | `mail` | `v=spf1 a:mail.lucawahlen.com ~all` | — | Auto | n/a |
| TXT | `_dmarc.mail` | `v=DMARC1; p=none` | — | Auto | n/a |
| TXT | `<selector>._domainkey.mail` | `v=DKIM1; k=...; p=...` from Stalwart | — | Auto | n/a |

The Cloudflare **Name** field is relative to the zone: enter `mail`, not
`mail.lucawahlen.com`, otherwise you create `mail.lucawahlen.com.lucawahlen.com`.
The MX target is the hostname `mail.lucawahlen.com`, never the IP. Only A/AAAA/
CNAME records have a Proxy toggle; MX and TXT do not.

Start with `~all` and `p=none` while testing; tighten to `-all` and
`p=quarantine` once SPF, DKIM and DMARC pass.

Notes:

- The existing `*.lucawahlen.com` wildcard is a proxied tunnel CNAME. The
  explicit `mail` A record overrides it for this name. Mail records must be
  **DNS-only**; Cloudflare's proxy cannot carry SMTP/IMAP.
- Remove Resend's MX/SPF/DKIM records **on `mail.lucawahlen.com` only** once
  Stalwart is ready. Leave `send.mail.lucawahlen.com` or other Resend helper
  names alone if anything still uses them.
- SPF uses `a:` rather than a literal IP so it follows the dynamic A record.
- Add `rua=mailto:...` to the DMARC record once a mailbox for reports exists.

## DDNS

`ddns.yaml` is not enabled by default. Create a Cloudflare API token with
**Zone → DNS → Edit** on `lucawahlen.com`, store it as
`CLOUDFLARE_API_TOKEN` in `secret.enc.yaml`, then uncomment `- ddns.yaml` in
`kustomization.yaml`. It keeps the `mail` A record pointed at the current WAN
address, `proxied=false`, IPv4 only.

The FritzBox's built-in DDNS cannot update a Cloudflare record: it speaks
simple URL-based update protocols, not the Cloudflare API's bearer-token/JSON
calls. Use the Deployment above, or create/update the A record by hand.

For a static IP, skip the updater and create the A record by hand.

## Bedrock

The ConfigMap now points at `mail.lucawahlen.com:465` with implicit TLS. The
secret contains `SMTP_USER=bedrock@mail.lucawahlen.com` and a generated
password. Create that same account in Stalwart, then restart the Bedrock
deployment.

In-cluster clients resolve `mail.lucawahlen.com` to the node through blocky
(`kubernetes/apps/blocky/config.yaml`), so they use the public certificate
and the LoadBalancer path instead of the `*.svc.cluster.local` name.

## Operational notes

- Configuration is in RocksDB, so `/var/lib/stalwart` is the thing to back up.
  It is not reproducible from Git.
- One replica only with the local RocksDB store.
- Stalwart's built-in ACME renews in place; there is no cert-manager
  certificate to reload.
- Don't remove Resend until a test message from Stalwart reaches Gmail/Outlook
  without landing in spam.
- Public port 25 only works if the node is reachable from the internet. If the
  WAN address changes, DDNS fixes inbound DNS but existing connections are
  still interrupted.