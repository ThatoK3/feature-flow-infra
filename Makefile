COMPOSE  = docker compose
PROJECT  = featureflow
ENV_FILE = .env

.PHONY: help setup up down restart clean clean-volumes \
        status verify logs ps

# ── Default ───────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  FeatureFlow Data Sources"
	@echo "  ─────────────────────────────────────────────────────────────────"
	@echo "  First-time setup:"
	@echo "    make setup          Copy .env.example → .env, then bring everything up"
	@echo ""
	@echo "  Daily use:"
	@echo "    make up             Start all services (detached)"
	@echo "    make down           Stop services (volumes kept)"
	@echo "    make restart        down + up"
	@echo "    make status         Print per-service health"
	@echo "    make verify         Smoke-test every data source"
	@echo ""
	@echo "  Logs:"
	@echo "    make logs           Tail all logs"
	@echo "    make logs s=mysql   Tail logs for one service"
	@echo ""
	@echo "  Cleanup:"
	@echo "    make clean          Stop + remove containers (volumes kept)"
	@echo "    make clean-volumes  ⚠️  Also delete ALL data volumes"
	@echo ""

# ── Pre-flight: .env must exist ───────────────────────────────────────────────
$(ENV_FILE):
	@echo "❌  .env not found. Run:  make setup"
	@exit 1

check-env: $(ENV_FILE)
	@echo "✅  .env found"

# ── Setup (first-time) ────────────────────────────────────────────────────────
setup:
	@if [ ! -f $(ENV_FILE) ]; then \
		cp .env.example $(ENV_FILE); \
		echo ""; \
		echo "📄  Created .env from .env.example"; \
		echo "    Edit it now to set your passwords, then re-run: make setup"; \
		echo ""; \
	else \
		echo "✅  .env already exists, skipping copy"; \
	fi
	@$(MAKE) _up
	@$(MAKE) _wait-init
	@$(MAKE) _print-connections

# ── Lifecycle ─────────────────────────────────────────────────────────────────
up: check-env
	@$(MAKE) _up
	@echo ""
	@echo "Run  make status   to check health"
	@echo "Run  make verify   to smoke-test connections"
	@echo ""

_up:
	$(COMPOSE) up -d --remove-orphans

down:
	$(COMPOSE) down

restart: down _up

clean:
	$(COMPOSE) down --remove-orphans

clean-volumes:
	@echo ""
	@echo "⚠️   This will DELETE all data volumes (sqlserver, mysql, mongo, postgres, minio)."
	@echo "    Press Ctrl+C within 5 seconds to abort..."
	@sleep 5
	$(COMPOSE) down -v --remove-orphans
	@echo "🗑️   Volumes removed."

# ── Wait for init containers ──────────────────────────────────────────────────
_wait-init:
	@echo ""
	@echo "⏳  Waiting for init containers to finish..."
	@$(COMPOSE) wait \
		sqlserver-init \
		mysql-init \
		mongodb-init \
		postgres-init \
		minio-init 2>/dev/null || true
	@echo "✅  All init containers done."

# ── Observability ─────────────────────────────────────────────────────────────
ps:
	$(COMPOSE) ps

status:
	@echo ""
	@echo "── Service Health ────────────────────────────────────────────────────"
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""

logs:
ifdef s
	$(COMPOSE) logs -f $(s)
else
	$(COMPOSE) logs -f
endif

# ── Smoke tests ───────────────────────────────────────────────────────────────
verify: check-env
	@echo ""
	@echo "── Smoke Tests ───────────────────────────────────────────────────────"
	@. ./$(ENV_FILE) && \
	echo -n "  SQL Server  ... " && \
	docker exec ff_sqlserver \
		/opt/mssql-tools18/bin/sqlcmd \
		-S localhost -U sa -P "$${SA_PASSWORD}" \
		-Q "SELECT name FROM sys.databases WHERE name IN \
		    ('RiskDataMart','ClinicalDB','SupplyChainDB','PolicyDB','BillingDB')" \
		-C -h -1 -W 2>/dev/null \
		| grep -c "DataMart\|ClinicalDB\|SupplyChain\|PolicyDB\|BillingDB" \
		| xargs -I{} bash -c '[ "{}" -ge 5 ] && echo "✅  5/5 databases" || echo "⚠️  only {} databases"'
	@. ./$(ENV_FILE) && \
	echo -n "  MySQL       ... " && \
	docker exec ff_mysql \
		mysql -u root -p"$${MYSQL_ROOT_PASSWORD}" \
		-e "SHOW DATABASES LIKE '%'" 2>/dev/null \
		| grep -cE "credit_data|patient_admin|procurement|claims_db|network_ops" \
		| xargs -I{} bash -c '[ "{}" -ge 5 ] && echo "✅  5/5 databases" || echo "⚠️  only {} databases"'
	@echo -n "  MongoDB     ... " && \
	docker exec ff_mongodb \
		mongosh --quiet --eval \
		"db.adminCommand({listDatabases:1}).databases.map(d=>d.name)" \
		2>/dev/null | grep -o "loan_documents\|clinical_notes\|sensor_data\|risk_assessments\|interactions" \
		| wc -l | xargs -I{} bash -c 'n=$$(echo "{}" | tr -d " "); [ "$$n" -ge 5 ] && echo "✅  5/5 databases" || echo "⚠️  only $$n databases"'
	@. ./$(ENV_FILE) && \
	echo -n "  PostgreSQL  ... " && \
	docker exec -e PGPASSWORD="$${POSTGRES_PASSWORD}" ff_postgres \
		psql -U postgres -tc \
		"SELECT count(*) FROM pg_database \
		 WHERE datname IN ('ratings','registry','demand','tables_db','catalog_db')" \
		2>/dev/null | tr -d ' \n' \
		| xargs -I{} bash -c '[ "{}" -ge 5 ] && echo "✅  5/5 databases" || echo "⚠️  only {} databases"'
	@. ./$(ENV_FILE) && \
	echo -n "  MinIO       ... " && \
	docker exec ff_minio \
		mc alias set ff http://localhost:9000 "$${MINIO_USER}" "$${MINIO_PASSWORD}" > /dev/null 2>&1 ; \
	docker exec ff_minio \
		mc ls ff 2>/dev/null \
		| grep -c "credit-risk\|hospital\|supply-chain\|cat-risk\|telecom\|feast" \
		| xargs -I{} bash -c '[ "{}" -ge 6 ] && echo "✅  6/6 buckets" || echo "⚠️  only {} buckets"'
	@echo ""

# ── Connection string helper ──────────────────────────────────────────────────
connections: check-env
	@$(MAKE) _print-connections

_print-connections:
	@. ./$(ENV_FILE) && echo "" && \
	echo "  ┌─ Connection Strings ──────────────────────────────────────────────┐" && \
	echo "  │  SQL Server   jdbc:sqlserver://localhost:1433                     │" && \
	echo "  │               user: sa  /  pass: $${SA_PASSWORD}                 │" && \
	echo "  │               DBs: RiskDataMart, ClinicalDB, SupplyChainDB,      │" && \
	echo "  │                    PolicyDB, BillingDB                           │" && \
	echo "  │                                                                   │" && \
	echo "  │  MySQL        jdbc:mysql://localhost:3306                        │" && \
	echo "  │               user: root  /  pass: $${MYSQL_ROOT_PASSWORD}       │" && \
	echo "  │               DBs: credit_data, patient_admin, procurement,      │" && \
	echo "  │                    claims_db, network_ops                        │" && \
	echo "  │                                                                   │" && \
	echo "  │  MongoDB      mongodb://root:<pass>@localhost:27017              │" && \
	echo "  │               replicaSet=rs0                                     │" && \
	echo "  │               DBs: loan_documents, clinical_notes, sensor_data,  │" && \
	echo "  │                    risk_assessments, interactions                │" && \
	echo "  │                                                                   │" && \
	echo "  │  PostgreSQL   postgresql://postgres:<pass>@localhost:5432        │" && \
	echo "  │               DBs: ratings, registry, demand, tables_db,        │" && \
	echo "  │                    catalog_db                                    │" && \
	echo "  │                                                                   │" && \
	echo "  │  MinIO S3     http://localhost:9000  (console: :9001)           │" && \
	echo "  │               user: $${MINIO_USER}  /  pass: $${MINIO_PASSWORD} │" && \
	echo "  └───────────────────────────────────────────────────────────────────┘" && \
	echo ""
