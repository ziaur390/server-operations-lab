# Troubleshooting Record

Real failures hit while building this lab, documented in the
Symptom → Checks → Cause → Fix → Verification format. None were
invented for this document — each happened during the build.

---

## 1. Git: push rejected (non-fast-forward)

- **Symptom:** `git push` → `Updates were rejected because the remote contains work that you do not have locally.`
- **Checks:** `git log --oneline --all` on the remote — an auto-generated "Initial commit" existed from repo creation.
- **Cause:** Local and remote histories were unrelated; the push was not a fast-forward.
- **Fix:** `git pull origin main --rebase --allow-unrelated-histories`, then push.
- **Verification:** `git log --oneline` shows one linear history: Initial commit → Mod 0 → …

## 2. App: `relation "items" does not exist` on first POST

- **Symptom:** `POST /items` → `psycopg.errors.UndefinedTable`.
- **Checks:** `/ready` returned 200, so connectivity was fine; the table check was next.
- **Cause:** Test harness (`TestClient`) without a context manager never runs the app's lifespan, so `init_db()` (CREATE TABLE) never executed. Not an application bug.
- **Fix:** Use `with TestClient(app)`.
- **Verification:** POST then GET returns the row.

## 3. Docker: `COPY app/...: "/app": not found`

- **Symptom:** `docker compose build` failed at COPY.
- **Checks:** Compared Dockerfile paths against the build context in `compose.yaml`.
- **Cause:** Build context was `./app`, but the Dockerfile referenced `app/...` — paths inside a Dockerfile are relative to the context.
- **Fix:** Rewrote COPY paths for the `./app` context.
- **Verification:** `docker compose up -d --build` → containers healthy.

## 4. Reverse proxy: HTTP 504 with API stopped

- **Symptom:** `curl :80/health` returned 504 while the API container was stopped.
- **Checks:** `docker compose ps` — nginx up, api stopped, db healthy.
- **Cause:** Nginx healthy but its upstream was down. Classic 3-layer diagnosis: proxy ≠ app ≠ database.
- **Fix:** `docker compose start api`.
- **Verification:** `/health` returned 200 with no Nginx changes.
- **Note:** During this module, `/health` sometimes returned HTTP 000 instead of 504: Nginx holds the connection for its own upstream timeout (default 60 s) while `curl --max-time 5` gives up first.

## 5. Ansible: playbook hung at "Gathering Facts"

- **Symptom:** Playbook stalled indefinitely on the first task.
- **Checks:** Ran `ssh -p 2222 host` manually from the controller — password prompt appeared.
- **Cause:** The SSH private key existed only on the Windows host; the controller (WSL Ubuntu) had no private key, so key-based auth failed silently into an interactive prompt.
- **Fix:** Copied the private key to `~/.ssh` on the controller, `chmod 600`.
- **Verification:** `ssh -o BatchMode=yes` succeeded without prompting.

## 6. Ansible: `Missing sudo password`

- **Symptom:** `fatal: [lab-vm]: FAILED! => {"msg": "Missing sudo password"}`.
- **Checks:** Tried `sudo -n true` as the admin user.
- **Cause:** Playbook uses `become: true`; the admin user had no passwordless sudo.
- **Fix:** `/etc/sudoers.d/lab-vm` NOPASSWD rule (lab server policy).
- **Verification:** `sudo -n true` → 0; playbook progressed.

## 7. Deploy: `address already in use` on port 8000

- **Symptom:** `failed to bind host port 0.0.0.0:8000/tcp: address already in use`.
- **Checks:** `docker ps` on both the Windows host and the target.
- **Cause:** Two deployments (Docker Desktop stack and the lab-vm stack) both publishing 8000.
- **Fix:** `docker compose down` on the Windows side — one server, one deployment.
- **Verification:** Playbook deploy succeeded; app live on lab-vm port 80.

## 8. Docker: container stuck "Restarting" — `host not found in upstream "api"`

- **Symptom:** api and nginx containers restart-looped; logs showed `nginx: [emerg] host not found in upstream "api"` and `failed to resolve host 'db'`.
- **Checks:** `docker inspect <container> --format '{{json .NetworkSettings.Networks}}'` → `{}` for api (the db was attached correctly).
- **Cause:** The api container was created during a failed deploy run and had no network attached; container restart does not re-attach networks.
- **Fix:** `docker compose down && docker compose up -d` in the project dir — fresh containers, correct network attachment.
- **Verification:** `curl :80/health` → 200.

## 9. Ansible: `changed=1` on a re-run with nothing to change

- **Symptom:** Second playbook run reported `changed=1` — idempotency not provable.
- **Checks:** Ran the playbook repeatedly; the only changed task was the Compose "build and start" task.
- **Cause:** The `community.docker.docker_compose_v2` module reports changed on re-run.
- **Fix:** Replaced it with an explicit `command: docker compose up -d --build` plus `changed_when` matching "Started/Recreated/Built" in output — idempotency made explicit.
- **Verification:** Re-run → `ok=10 changed=0 failed=0`.

## 10. Monitoring: `Permission denied` writing the health log

- **Symptom:** Health check run as the admin user could not write `logs/health.log`.
- **Checks:** `ls -ld /opt/server-operations-lab/logs`.
- **Cause:** Directory created by the playbook under `become` (root), not writable by the admin user.
- **Fix:** Playbook now creates the log dir owned by the admin user; the cron job runs as root.
- **Verification:** Health check runs cleanly and writes timestamped entries.

## 11. Tooling: `wsl.exe` silently strips shell quoting

- **Symptom:** Exit-code checks for the health script reported 0 even when the script exited 1.
- **Checks:** `bash -x` trace showed the script ran `exit 1`; a minimal `FAIL=1; exit $FAIL` through the same wrapper returned 0.
- **Cause:** `wsl.exe -- cmd` joins arguments and executes through the default shell, losing quoting — the test harness was broken, not the script.
- **Fix:** Used `wsl -e bash -c` (direct exec, no shell joining).
- **Verification:** Fail run → 1, recovery run → 0, consistently.

## 12. Virtualization: VirtualBox would not install

- **Symptom:** Repeated installation failures on the Windows host.
- **Checks:** Windows features, prerequisites; WSL2 already present with Ubuntu 24.04 + systemd.
- **Cause:** Hyper-V/virtualization conflict on this machine.
- **Fix:** Pivoted the target server to WSL2 Ubuntu with SSH on port 2222; the Ansible playbook is unchanged against a cloud VM — only the inventory would change.
- **Verification:** `ssh lab-vm` works; full stack deployed and verified there.
