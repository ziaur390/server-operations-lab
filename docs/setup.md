# Setup Guide

## Prerequisites

- Docker Desktop (Windows)
- Python 3.11+
- Git
- (Modules 5–6) Ubuntu VM reachable over SSH

## Module 1 — FastAPI app locally

```bash
python -m venv .venv
.venv/Scripts/activate          # Windows; Linux/macOS: source .venv/bin/activate
pip install -r app/requirements.txt
uvicorn app.main:app --reload
```

Verify:

- `curl http://127.0.0.1:8000/health` → `{"status":"ok"}`
- Swagger UI: http://127.0.0.1:8000/docs

## Module 3 — Docker Compose

```bash
cp .env.example .env            # then edit values
docker compose up -d --build
docker compose ps
curl http://127.0.0.1:8000/ready
```

## Module 4 — Nginx

```bash
docker compose up -d --build
curl http://127.0.0.1/health    # via Nginx, port 80
```

## Modules 5–6 — Ubuntu VM + Ansible

1. Create an Ubuntu VM (VirtualBox/Hyper-V), enable SSH, note its IP.
2. Add the IP to `ansible/inventory.ini`.
3. Run:

```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml
```

The playbook installs Docker, creates `/opt/server-operations-lab`,
copies the Compose and Nginx config, and starts the services.

## Module 7 — Health checks

```bash
./scripts/health_check.sh
tail -5 logs/health.log
```

## Module 8 — Backup & restore test

```bash
./scripts/backup_db.sh
./scripts/restore_db.sh backups/<file>.sql restore_test
```

The script compares record counts between the original and restored database.
