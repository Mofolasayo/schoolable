# Hetzner VM Migration Plan (No Domain)

Goal: keep the current DigitalOcean flow for final fixes, then migrate all services to a Hetzner VM using IP + ports.

## Phase 0: Finish fixes on current droplet
- Deploy the latest backend with the current Kamal command.
- Smoke check: team lead appointment/removal, team creation, team-lead-only announcements, dashboards load.
- Snapshot `.kamal/secrets` and all runtime env vars used by backend and dashboards.

## Phase 1: Create the Hetzner VM
- Create a CX11 (Ubuntu 22.04) server via API key.
- Upload SSH public key during creation.
- Record public IP (used for all services).

## Phase 2: Base VM bootstrap
- Create `deploy` user and add SSH key.
- Install Docker + Compose plugin.
- Open firewall ports: 22, 8081, 3000, 3001.

## Phase 3: Backend (schoolable_backend)
- Update `config/deploy.yml` with the Hetzner IP and `deploy` user.
- Copy `.kamal/secrets` to the VM.
- Run `kamal setup`, then `kamal deploy --skip-push --version latest`.
- Confirm health: migrations, `/api/health` (or equivalent), key flows.

## Phase 4: Admin dashboard (schoolable_dashboard)
- Build and run on the VM.
- Env: `NEXT_PUBLIC_API_URL=http://<HETZNER_IP>:8081`
- Start on port 3000 (Docker or systemd).
- Verify `http://<HETZNER_IP>:3000`.

## Phase 5: Team lead dashboard (schoolable_team_lead)
- Build and run on the VM.
- Env: `NEXT_PUBLIC_API_URL=http://<HETZNER_IP>:8081`
- Start on port 3001 (Docker or systemd).
- Verify `http://<HETZNER_IP>:3001`.

## Phase 6: Mobile app (schoolable)
- Update API base URL to `http://<HETZNER_IP>:8081`.
- Rebuild/release after backend cutover.

## Phase 7: Cutover + validation
- Share IP links for internal testing.
- Validate: auth, tasks, attendance, announcements, HR flows, team scores.
- Decommission the DO droplet after stability is confirmed.

## Rollback plan
- Keep DO droplet running until Hetzner passes all checks.
- If needed, revert dashboards’ API URL and point users back to DO.

## Metafiz + Self-Reflection Checklist
- Metafiz (system mapping): identify dependencies (DB, Cloudinary, AI, auth), confirm they are reachable from Hetzner.
- Failure modes: test API timeouts, Cloudinary delivery, AI fallback, and dashboard error states.
- Guardrails: verify role checks, audit logs, and rate limits still fire.
- Self-reflection: after cutover, log what broke, why, and whether the plan missed any hidden dependency.
