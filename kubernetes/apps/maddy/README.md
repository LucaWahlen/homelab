# maddy

Self-hosted **send-only** maddy at `mail.lucawahlen.com`. It is an
authenticated submission server that DKIM-signs mail and relays it to remote
MX; it does not receive mail. It replaces Stalwart (and, eventually, Resend)
for Bedrock. The root domain stays on Proton; only the `mail.lucawahlen.com`
subdomain belongs to this server.

The whole server configuration is a single file (`maddy.conf` in the
`maddy-config` ConfigMap), so it is managed by Git and Flux. The only secrets
are the sender credentials, the DKIM private key and the Cloudflare token,
which live in the SOPS-encrypted `maddy-secrets` Secret. There is no mailbox
store, no IMAP and no inbound SMTP, so the workload is **stateless**: no PVC,
and the delivery queue lives in a memory-backed `emptyDir`.

## What is exposed

| Port | Purpose | Where |
|---|---|---|
| 465 | Submission, implicit TLS | public, via `maddy-mail` LoadBalancer |

Nothing else is exposed: there is deliberately **no port 25** (no receiving),
no 587 (no STARTTLS submission listener) and no IMAP. maddy listens on an
unprivileged port inside the container (8465) and the Service maps 465 onto it.
The official image runs as root and sets no `NET_BIND_SERVICE` file capability,
so a non-root container cannot bind 465 directly; this keeps the pod on a
locked-down securityContext (non-root, read-only root filesystem, all
capabilities dropped).

`maddy-mail` is a `LoadBalancer`, so k3s ServiceLB binds the submission port
on the node. Forward `465` from the FritzBox to the node's LAN address
(`192.168.178.234`).

## Prerequisites

- A real public IPv4 (not CGNAT/DS-Lite) and outbound TCP 25 open.
- FritzBox port forward: `465` → `192.168.178.234`. (The old port 25, 587 and
  993 forwards can be removed.)
- The ISP should set the PTR for that IP to `mail.lucawahlen.com`:

  ```bash
  WAN=$(curl -4 -fsS https://api.ipify.org)
  echo "$WAN"
  dig -x "$WAN" +short                      # must be mail.lucawahlen.com
  nc -4 -vz gmail-smtp-in.l.google.com 25   # -4 matters: the IPv6 path proves nothing
  ```

  Without a matching PTR, receiving is irrelevant here but **outbound delivery
  is unreliable**: consumer dynamic pools (the `dip0.t-ipconnect.de` pattern)
  are commonly on Spamhaus PBL and get rejected or spam-foldered. A static IP
  with a settable PTR (or a smarthost/relay) is required for dependable
  delivery to Gmail/Outlook.

## DNS records (Cloudflare)

Only the `mail` subdomain is involved. Leave the root `lucawahlen.com` MX
pointing at Proton. These records are created by hand for now; the `mail` A
record is kept current by the `cloudflare-ddns` deployment.

| Type | Name (Cloudflare field) | Content / target | Priority | TTL | Proxy |
|---|---|---|---|---|---|
| A | `mail` | current WAN IPv4 (set by `cloudflare-ddns`) | — | Auto (300) | **DNS only** |
| TXT | `mail` | `v=spf1 a:mail.lucawahlen.com ~all` | — | Auto | n/a |
| TXT | `_dmarc.mail` | `v=DMARC1; p=none` | — | Auto | n/a |
| TXT | `default._domainkey.mail` | see below | — | Auto | n/a |

**Remove the `MX` record for `mail`** (and any Resend MX/SPF/DKIM records on
`mail.lucawahlen.com`): this server does not receive, so a published MX only
causes bounces at senders. SPF uses `a:` rather than a literal IP so it follows
the dynamic A record.

The Cloudflare **Name** field is relative to the zone: enter `mail`, not
`mail.lucawahlen.com`. The DKIM public key is derived from the private key in
`maddy-secrets`; print the record value with:

```bash
sops -d kubernetes/apps/maddy/secret.enc.yaml \
  | yq -r '.stringData."dkim.key"' \
  | python3 -c 'import sys, base64; from cryptography.hazmat.primitives.serialization import load_pem_private_key, Encoding, PublicFormat as P; k=load_pem_private_key(sys.stdin.buffer.read(), None); print("v=DKIM1; k=rsa; p="+base64.b64encode(k.public_key().public_bytes(Encoding.DER, P.SubjectPublicKeyInfo)).decode())'
```

The value generated at migration time is:

```
v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwQER+8HvJH3fh8w886wtSjANLvKZiMSZ1I0kKytv01wFonvsz1GBpGD0fImLbOgD6Aw/uSqg77tuWjp0J3NCgMBlp+UzSnhUqhmmuUSH2bH2gJ9A1zD8YZtOqmtowvRrdJ5Eug6eGYdPpIm7PT/MqUkaD+MOaJSAUTzipAZEa+VxSc6f4Iw47jQ6RhJgSKCWZHfmtxmlxlYfD1+oE13Gbkp0YA+1ke+wYewRKP7MYtQui/cC3oFiWVAt0LT4A8u27/urZZPNBRCTPYRniLZVd/Gd7xwJNk6ZNgOHicCJ01HqUDAwS8n1YlM0f8PiBnfbkydB4VlOUVsUi9lmokeKywIDAQAB
```

Start with `~all` and `p=none` while testing; tighten to `-all` and
`p=quarantine` once SPF and DKIM pass. Add `rua=mailto:...` to the DMARC record
once a mailbox for reports exists.

## Sender accounts

Senders authenticate with the credentials file (`user:bcrypt:$2a$...`) mounted
from `maddy-secrets`. Only senders at `mail.lucawahlen.com` are allowed, and
the envelope/`From` must match the authenticated account. Two accounts exist:

- `bedrock@mail.lucawahlen.com`, using the password already in
  `kubernetes/apps/bedrock/secret.enc.yaml` (`SMTP_PASSWORD`).
- `luca@mail.lucawahlen.com`, with a generated password:

  ```bash
  sops -d kubernetes/apps/maddy/secret.enc.yaml | yq -r '.stringData."luca-password"'
  ```

Unlike the receive setup, there is no IMAP mailbox to provision — an account is
just a credential, so no initContainer and no restart-then-provision step.

### Adding or changing a sender

1. Generate a hash with maddy itself (run it inside the running pod):

   ```bash
   kubectl -n maddy exec -it deploy/maddy -- maddy hash --password 'NEWPASSWORD' --hash bcrypt
   ```

2. Add the line `<user>@mail.lucawahlen.com:bcrypt:$2a$...` under `credentials`
   in `kubernetes/apps/maddy/secret.enc.yaml` and re-encrypt:

   ```bash
   sops kubernetes/apps/maddy/secret.enc.yaml
   ```

The mounted credential file is picked up within ~15s; existing connections are
unaffected. No restart is required.

## TLS

`certificate.yaml` asks the existing `letsencrypt` ClusterIssuer (Cloudflare
DNS-01) for `mail.lucawahlen.com`; cert-manager writes it to the
`maddy-mail-tls` Secret, which is mounted read-only. maddy reloads the
certificate from disk on renewal, so no restart is needed. Because the
challenge is DNS-01, no inbound port 80 or ingress is involved.

For sending, TLS is also used outbound: `target.remote` uses DANE + MTA-STS and
requires encryption to the recipient (`local_policy { min_tls_level encrypted }`).

## Bedrock

The Bedrock ConfigMap points at `mail.lucawahlen.com:465` with implicit TLS
(`SMTP_SECURE=true`). The matching credential is the `bedrock@` account above;
restart the Bedrock deployment after the first rollout.

In-cluster clients resolve `mail.lucawahlen.com` to the node through blocky
(`kubernetes/apps/blocky/config.yaml`), so they use the public certificate and
the LoadBalancer path instead of the `*.svc.cluster.local` name.

## Operational notes

- **Stateless.** No PVC. The delivery queue, message buffers and MTA-STS cache
  live in a `medium: Memory` `emptyDir` (`/data`), so a pod restart drops any
  messages still queued. Set `replicas: 0` or scale up freely.
- **Retries but no bounces.** The queue retries temporary failures within the
  pod's lifetime. There is no `bounce` block, so permanent failures are logged
  and dropped rather than generating a DSN (there is no mailbox to receive
  one). To fail the SMTP transaction instead of queueing, change
  `deliver_to &remote_queue` to `deliver_to &outbound_delivery` in
  `maddy.conf` — the client then sees the delivery result immediately, with no
  retries.
- Configuration changes are an edit to the ConfigMap in Git; Flux applies them
  and maddy reloads.

## Migration from Stalwart

Stalwart (`kubernetes/apps/stalwart`, `kubernetes/root/stalwart.yaml`) has been
removed. The maddy StatefulSet and its `data-maddy-0` PVC from the earlier
receive-capable revision had `kustomize.toolkit.fluxcd.io/prune: disabled`, so
the PVC is **not** deleted automatically. Remove it by hand once the send-only
Deployment is healthy:

```bash
kubectl -n maddy delete pvc data-maddy-0
```
