# maddy

Self-hosted maddy at `mail.lucawahlen.com` for **sending and receiving**.
It replaces Stalwart (for Bedrock) and, eventually, Resend. The root domain
stays on Proton; only the `mail.lucawahlen.com` subdomain belongs to this
server.

The whole server configuration is a single file (`maddy.conf` in the
`maddy-config` ConfigMap), so it is managed by Git and Flux. The few pieces
that are not plain config — credentials, the DKIM private key and the
Cloudflare token — live in the SOPS-encrypted `maddy-secrets` Secret. maddy has
no web UI; manage mail with any IMAP/SMTP client.

## What is exposed

| Port | Purpose | Where |
|---|---|---|
| 25 | MX / server-to-server | public, via `maddy-mail` LoadBalancer |
| 465 | Submission, implicit TLS | public |
| 587 | Submission, STARTTLS | public |
| 993 | IMAPS | public |
| 143 | IMAP cleartext | cluster only, unused |

maddy listens on **unprivileged** ports inside the container
(8025 / 8465 / 8587 / 8993) and the Services map the real ports onto those
targetPorts. The official image runs as root and sets no `NET_BIND_SERVICE`
file capability, so a non-root container cannot bind 25/465/587/993 directly;
this keeps the pod on a locked-down securityContext (non-root, read-only root
filesystem, all capabilities dropped).

`maddy-mail` is a `LoadBalancer`, so k3s ServiceLB binds the mail ports on the
node. Forward them from the FritzBox to the node's LAN address
(`192.168.178.234`).

## Prerequisites

- A real public IPv4 (not CGNAT/DS-Lite) and outbound TCP 25 open.
- FritzBox port forwards: `25`, `465`, `587`, `993` → `192.168.178.234`.
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
  a **proxied** Cloudflare tunnel CNAME, so until the explicit, DNS-only `mail`
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

## DNS records (Cloudflare)

Only the `mail` subdomain changes. Leave the root `lucawahlen.com` MX pointing
at Proton. These records are created by hand for now; the `mail` A record is
kept current by the `cloudflare-ddns` deployment.

| Type | Name (Cloudflare field) | Content / target | Priority | TTL | Proxy |
|---|---|---|---|---|---|
| A | `mail` | current WAN IPv4 (set by `cloudflare-ddns`) | — | Auto (300) | **DNS only** |
| MX | `mail` | `mail.lucawahlen.com` | `10` | Auto (300) | n/a |
| TXT | `mail` | `v=spf1 a:mail.lucawahlen.com ~all` | — | Auto | n/a |
| TXT | `_dmarc.mail` | `v=DMARC1; p=none` | — | Auto | n/a |
| TXT | `default._domainkey.mail` | see below | — | Auto | n/a |

The Cloudflare **Name** field is relative to the zone: enter `mail`, not
`mail.lucawahlen.com`, otherwise you create `mail.lucawahlen.com.lucawahlen.com`.
The MX target is the hostname `mail.lucawahlen.com`, never the IP. Only A/AAAA/
CNAME records have a Proxy toggle; MX and TXT do not. Mail records must be
**DNS-only**; Cloudflare's proxy cannot carry SMTP/IMAP.

Start with `~all` and `p=none` while testing; tighten to `-all` and
`p=quarantine` once SPF, DKIM and DMARC pass.

The DKIM public key is derived from the private key in `maddy-secrets`. Print
the record value with:

```bash
sops -d kubernetes/apps/maddy/secret.enc.yaml \
  | yq -r '.stringData."dkim.key"' \
  | python3 -c 'import sys, base64; from cryptography.hazmat.primitives.serialization import load_pem_private_key, Encoding, PublicFormat as P; k=load_pem_private_key(sys.stdin.buffer.read(), None); print("v=DKIM1; k=rsa; p="+base64.b64encode(k.public_key().public_bytes(Encoding.DER, P.SubjectPublicKeyInfo)).decode())'
```

The value generated at migration time is:

```
v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwQER+8HvJH3fh8w886wtSjANLvKZiMSZ1I0kKytv01wFonvsz1GBpGD0fImLbOgD6Aw/uSqg77tuWjp0J3NCgMBlp+UzSnhUqhmmuUSH2bH2gJ9A1zD8YZtOqmtowvRrdJ5Eug6eGYdPpIm7PT/MqUkaD+MOaJSAUTzipAZEa+VxSc6f4Iw47jQ6RhJgSKCWZHfmtxmlxlYfD1+oE13Gbkp0YA+1ke+wYewRKP7MYtQui/cC3oFiWVAt0LT4A8u27/urZZPNBRCTPYRniLZVd/Gd7xwJNk6ZNgOHicCJ01HqUDAwS8n1YlM0f8PiBnfbkydB4VlOUVsUi9lmokeKywIDAQAB
```

Add `rua=mailto:...` to the DMARC record once a mailbox for reports exists.

## Accounts (credentials + mailboxes)

maddy keeps login credentials and IMAP storage accounts separate. Both are
driven from Git:

- **Credentials** are hashes (`user:bcrypt:$2a$...`) in the `credentials` key
  of `maddy-secrets`, read by the `auth.pass_table` file table.
- **Mailboxes** are provisioned by the `ensure-accounts` initContainer, which
  reads the usernames from that same file and runs `maddy imap-acct create`
  for any that are missing. The credential file is therefore the single
  source of truth for which accounts exist.

Two accounts are created at migration time:

- `bedrock@mail.lucawahlen.com`, using the password already in
  `kubernetes/apps/bedrock/secret.enc.yaml` (`SMTP_PASSWORD`).
- `redacted@example.com`, with a generated password:

  ```bash
  sops -d kubernetes/apps/maddy/secret.enc.yaml | yq -r '.stringData."luca-password"'
  ```

### Adding or changing a mailbox

1. Generate a hash with maddy itself (run it inside the running pod):

   ```bash
   kubectl -n maddy exec -it maddy-0 -- maddy hash --password 'NEWPASSWORD' --hash bcrypt
   ```

2. Add the line `<user>@mail.lucawahlen.com:bcrypt:$2a$...` under `credentials`
   in `kubernetes/apps/maddy/secret.enc.yaml`. Re-encrypt by editing in place:

   ```bash
   sops kubernetes/apps/maddy/secret.enc.yaml
   ```

3. Restart the StatefulSet so the initContainer creates the new mailbox:

   ```bash
   kubectl -n maddy rollout restart statefulset/maddy
   ```

Changing a password needs no restart — the mounted credential file is picked
up within ~15s. Only *creating* a new mailbox needs the restart.

## TLS

`certificate.yaml` asks the existing `letsencrypt` ClusterIssuer (Cloudflare
DNS-01) for `mail.lucawahlen.com`; cert-manager writes it to the
`maddy-mail-tls` Secret, which is mounted read-only. maddy reloads the
certificate from disk on renewal, so no restart is needed. Because the
challenge is DNS-01, no inbound port 80 or ingress is involved.

## Bedrock

The Bedrock ConfigMap points at `mail.lucawahlen.com:465` with implicit TLS
(`SMTP_SECURE=true`). The matching account and password are the ones above;
restart the Bedrock deployment after the first maddy rollout.

In-cluster clients resolve `mail.lucawahlen.com` to the node through blocky
(`kubernetes/apps/blocky/config.yaml`), so they use the public certificate and
the LoadBalancer path instead of the `*.svc.cluster.local` name.

## Operational notes

- Runtime state (mailboxes, queue, DKIM material, MTA-STS cache) lives on the
  `data` volume under `/data`. That PVC is what to back up — everything else is
  reproducible from Git.
- One replica only, with the local SQLite store.
- Configuration changes are just an edit to the ConfigMap in Git; Flux applies
  them and maddy reloads.
- Back up or migrate the SQLite files before upgrading maddy: a new version may
  convert the databases so an older version can no longer read them.

## Migration from Stalwart

Stalwart (`kubernetes/apps/stalwart`, `kubernetes/root/stalwart.yaml`) has been
removed. Its namespace and `data` PVC had
`kustomize.toolkit.fluxcd.io/prune: disabled`, so neither is deleted
automatically — remove them by hand once maddy is confirmed working:

```bash
kubectl delete namespace stalwart
# and the leftover PVC, if it is not in that namespace's StatefulSet anymore
```
