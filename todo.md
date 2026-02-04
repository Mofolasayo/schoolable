# TODO

- [x] Migrate Render Postgres to droplet and verify key table counts.
- [ ] Push `sslip.io` host/CORS config and deploy to enable HTTPS.
- [ ] Verify HTTPS health check at `https://165-227-1-93.sslip.io/up`.
- [ ] Update dashboard and mobile base URLs + CORS allowlist to `https://165-227-1-93.sslip.io`.
- [ ] Add GitHub Actions deploy secrets for auto-deploy (DROPLET_HOST/USER/SSH_KEY) and confirm deploy job runs.
- [ ] Fix GitHub Actions deploy failure (ssh.ParsePrivateKey: no key found) and rerun deploy job.
- [ ] Set up basic log access shortcuts (app + proxy) on the droplet.
- [ ] Scale down/stop Render after cutover is verified.
- [ ] Add notification for probation due/overdue confirmations (HR policy).
