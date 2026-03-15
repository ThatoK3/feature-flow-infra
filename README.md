# FeatureFlow — Data Infrastructure

## Quick Start

### 1. Prerequisites

```bash
docker --version       # 24+
docker compose version # 2.20+
openssl version        # for mongo keyfile
```

### 2. Generate MongoDB keyfile (required for replica set auth)

```bash
openssl rand -base64 756 > ./mongo-keyfile
chmod 400 ./mongo-keyfile
```

### 3. Configure environment

```bash
cp .env.example .env
# Edit .env — change all passwords before starting
```

### 4. Start infrastructure

```bash
# First run (builds volumes, runs all init scripts)
docker compose up -d

# Watch logs during init (~2-3 min for all services)
docker compose logs -f
```

### 5. Verify services

| Service           | Port  | Check                                      |
|-------------------|-------|--------------------------------------------|
| MongoDB Primary   | 27017 | `mongosh --port 27017 -u admin -p <pass>` |
| PostgreSQL        | 5432  | `psql -h localhost -U featureflow`         |
| MS SQL Server     | 1433  | `sqlcmd -S localhost -U sa -P <pass>`      |
| MySQL Primary     | 3306  | `mysql -h localhost -u featureflow -p`     |
| MinIO Console     | 9001  | http://localhost:9001                      |
| Redis             | 6379  | `redis-cli -a <pass> ping`                 |

### 6. Check replica set status

```bash
# MongoDB rs0
docker exec featureflow-mongo-primary mongosh -u admin -p <pass> \
    --eval "rs.status()"

# PostgreSQL replica
docker exec featureflow-postgres-replica psql -U featureflow \
    -c "SELECT * FROM pg_stat_replication;"

# MySQL replica
docker exec featureflow-mysql-replica mysql -u root -p<pass> \
    -e "SHOW REPLICA STATUS\G"
```

---

## Data Loading (Spark — later)

Each repo has a generator script and a corresponding data source:

| Repo | Generator                     | Primary Source     | Database(s)                    |
|------|-------------------------------|--------------------|--------------------------------|
| 1    | generate_repo1_credit.py      | MS SQL + MySQL     | repo1_credit / repo1_bureau    |
| 2    | generate_repo2_healthcare.py  | MS SQL + MySQL     | repo2_healthcare / repo2_eps   |
| 3    | generate_repo3_supplychain.py | MS SQL + MySQL     | repo3_supplychain / repo3_nodes|
| 4    | generate_repo4_insurance.py   | MS SQL + MySQL     | repo4_insurance / repo4_claims |
| 5    | generate_repo5_telecom.py     | MS SQL + MySQL     | repo5_telecom / repo5_billing  |

MongoDB and PostgreSQL are loaded via Spark after the relational tables are populated.

---

## Volumes

All data is persisted in named Docker volumes:

```
mongo_primary_data      mongo_secondary1_data   mongo_secondary2_data
postgres_primary_data   postgres_replica_data   postgres_archive
mssql_primary_data      mssql_replica_data
mysql_primary_data      mysql_replica_data
minio_data              redis_data
```

To reset everything:
```bash
docker compose down -v   # WARNING: deletes all data
```

---

## Debezium Connectors (deploy separately with Kafka)

Connector configs live in `./debezium-connectors/` (not in this compose file).
Each connector points at the primary node with:
- MongoDB:    `mongo-primary:27017`
- PostgreSQL: `postgres-primary:5432`  slot `debezium_slot`
- MSSQL:      `mssql-primary:1433`
- MySQL:      `mysql-primary:3306`
