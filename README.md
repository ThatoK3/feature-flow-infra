# FeatureFlow — Data Sources Stack

A self-contained local environment for five production-grade data sources used by FeatureFlow's feature engineering pipelines.

| Service | Image | Port | Purpose |
|---|---|---|---|
| SQL Server 2022 | `mssql/server:2022-latest` | 1433 | CDC via SQL Agent |
| MySQL 8 | `mysql:8.0` | 3306 | CDC via binlog (GTID) |
| MongoDB 6 | `mongo:6.0` | 27017 | CDC via replica set oplog |
| PostgreSQL 15 | `postgres:15` | 5432 | CDC via logical replication |
| MinIO | `minio/minio:latest` | 9000 / 9001 | S3-compatible offline store |

---

## Prerequisites

- **Docker** ≥ 24 and **Docker Compose** ≥ v2.20
- **make**
- ~6 GB free disk space (images + volumes)
- Ports 1433, 3306, 5432, 27017, 9000, 9001 available locally

---

## Quick Start

```bash
# 1. Clone / copy files into a directory
#    docker-compose.yml  Makefile  .env.example  → same folder

# 2. Create and edit your .env
cp .env.example .env
$EDITOR .env          # change all ChangeMe passwords

# 3. First-time setup: pulls images, starts everything, waits for inits
make setup

# 4. Verify all five sources came up cleanly
make verify

# 5. Print connection strings
make connections
```

`make setup` is idempotent — safe to re-run.

---

## Credentials & `.env`

All passwords live in `.env` (gitignored). Copy `.env.example` to `.env` and edit before first use.

| Variable | Used by | Notes |
|---|---|---|
| `SA_PASSWORD` | SQL Server | Must satisfy complexity: ≥8 chars, upper+lower+digit+symbol |
| `MYSQL_ROOT_PASSWORD` | MySQL root | Full admin access |
| `MYSQL_PASSWORD` | MySQL `featureflow` app user | Limited to app databases |
| `MONGO_ROOT_PASSWORD` | MongoDB root | Full admin access |
| `POSTGRES_PASSWORD` | PostgreSQL `postgres` superuser | |
| `CDC_PASSWORD` | Shared `cdc_user` | Read-only + replication grants across MySQL, MongoDB, PostgreSQL |
| `MINIO_USER` | MinIO root user | Default: `featureflow` |
| `MINIO_PASSWORD` | MinIO root password | |

> **Never commit `.env`** — add it to `.gitignore`.

---

## Databases & Buckets Created

### SQL Server — CDC enabled on all databases
```
RiskDataMart  ClinicalDB  SupplyChainDB  PolicyDB  BillingDB
```

### MySQL — binlog ROW format, GTID mode ON
```
credit_data  patient_admin  procurement  claims_db  network_ops
```

### MongoDB — single-node replica set `rs0`
```
loan_documents  clinical_notes  sensor_data  risk_assessments  interactions
```
Collections: `applications`, `notes`, `readings`, `surveys`, `events`

### PostgreSQL — `wal_level=logical`, 10 replication slots
```
ratings  registry  demand  tables_db  catalog_db
```

### MinIO — S3-compatible buckets
```
credit-risk-ml-archive  hospital-imaging-ml  supply-chain-lake
cat-risk-lake           telecom-cdr-lake     feast-offline-store
```

---

## CDC Users

A shared `cdc_user` (password: `CDC_PASSWORD`) is provisioned on all three CDC-capable databases:

**MySQL** — granted `SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT`

**MongoDB** — granted `read` on each database, `clusterMonitor` on admin, `read` on local

**PostgreSQL** — granted `CONNECT` on each database plus `REPLICATION LOGIN`

---

## Make Targets

```
make setup          First-time: copy .env.example, start all, wait for inits
make up             Start services (requires .env to exist)
make down           Stop services, keep volumes
make restart        down + up
make status         Print container health table
make verify         Smoke-test all five data sources
make connections    Print connection strings (reads passwords from .env)
make logs           Tail all logs
make logs s=mysql   Tail logs for one service
make ps             docker compose ps
make clean          Stop + remove containers (volumes kept)
make clean-volumes  ⚠️  Stop + remove containers AND volumes (data lost)
```

---

## Architecture Notes

### Why `--auth` is removed from MongoDB
The official `mongo:6.0` image bootstraps the root user via `MONGO_INITDB_ROOT_*` environment variables only when the data directory is empty. Adding `--auth` to the `command` at first boot creates a race: `mongod` starts with auth enforced before `MONGO_INITDB` scripts run, causing auth failures and crash-loops. The replica set is initiated without auth; `cdc_user` is added by `mongodb-init`. For production, add a keyfile and `--auth` after the first successful `rs.initiate()`.

### Why init containers are `restart: "no"`
Init containers (`*-init`) perform one-time idempotent setup and exit cleanly. They depend on `service_healthy` conditions so they only run after the database is ready. Re-running `make up` after a partial failure is safe — all init scripts check for existence before creating.

### SQL Server CDC requires SQL Agent
`MSSQL_AGENT_ENABLED=true` is set so that the CDC capture jobs can run. Without the agent, `sp_cdc_enable_db` succeeds but no change data is captured.

### PostgreSQL WAL settings
`wal_level=logical` and `max_replication_slots=10` are set via the `command` block (not `postgresql.conf`) so they apply from the very first boot, before any init scripts run.

---

## Troubleshooting

**A service is stuck in `Created` and never starts**
This means a dependency's healthcheck hasn't passed yet. Check with `make logs s=<dependency>`.

**`mysql-init` exits with code 1**
Usually a password mismatch between `MYSQL_ROOT_PASSWORD` in `.env` and what MySQL initialized with. Run `make clean-volumes` and `make setup` for a fresh start.

**`postgres-init` exits with code 2**
Check `make logs s=postgres-init`. Exit 2 from bash means a command failed. Common cause: `PGPASSWORD` not matching `POSTGRES_PASSWORD`.

**MongoDB keeps restarting**
Run `make logs s=mongodb`. If you see `auth failed` errors, the data directory may have been initialized with different credentials. Run `make clean-volumes` to wipe the volume and start clean.

**Port already in use**
Stop any local instances of the conflicting service, or edit the `ports` mapping in `docker-compose.yml` to use a different host port.

**`make verify` shows fewer databases than expected**
Run `make logs s=<service>-init` to see what the init container printed. Most init scripts are idempotent — you can `docker compose restart <service>-init` to re-run them manually if needed... but note Docker Compose won't restart a `restart: "no"` container automatically. Instead:
```bash
docker compose rm -f <service>-init
docker compose up -d <service>-init
```
