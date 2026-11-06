# PostgreSQL backups

Backups use the [Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/)
and go to an offsite S3-compatible bucket. WAL is archived continuously and a
base backup runs daily at 02:00 UTC; together they provide point-in-time
recovery. Base backups are kept for 30 days.

## One-time setup

The endpoint, bucket, and credentials are already set and were verified
(list, put, and delete) against `https://s3.homedrive.dev`:

- bucket: `luca-backups` (bucket root)
- access key: `luca-backups-key`
- secret key and region: in `credentials.enc.yaml` (SOPS-encrypted)

If the credentials change, edit them with:

```sh
sops kubernetes/apps/postgres/backup/credentials.enc.yaml
```

Then commit and push. Flux installs the plugin, starts WAL archiving, and takes
the first base backup immediately (`immediate: true`).

## Verify

```sh
kubectl -n postgres get objectstore,scheduledbackup,backup
kubectl cnpg status postgres -n postgres
```

WAL archiving is working when the cluster status shows a recent archived WAL
and the `Backup` object created by the schedule reaches `completed`.

## Notes

- `objectstore.yaml` forces path-style S3 URLs, which most self-hosted S3
  services need. Remove the `--addressing-style=path` arguments if the endpoint
  supports virtual-hosted-style URLs (`https://bucket.endpoint`).
- The `ObjectStore` retention policy deletes backups older than 30 days. The
  bucket can also have its own lifecycle rules, but keep them longer than the
  Barman retention window.
