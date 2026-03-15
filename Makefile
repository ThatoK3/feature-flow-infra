# FeatureFlow — Data Sources Test Stack
# Usage: make <target>

COMPOSE = docker compose
PROJECT = featureflow

.PHONY: help up down restart logs ps \
        initial-setup status connectors topics \
        clean clean-volumes

# ── Default ──────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  FeatureFlow Data Sources — Available targets"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make up               Start all services (detached)"
	@echo "  make initial-setup    up + wait + show connection strings"
	@echo "  make down             Stop all services (keep volumes)"
	@echo "  make restart          down + up"
	@echo "  make clean            down + remove containers"
	@echo "  make clean-volumes    clean + remove all data volumes  ⚠️"
	@echo ""
	@echo "  make logs             Tail all logs"
	@echo "  make logs s=<name>    Tail logs for one service (e.g. s=mysql)"
	@echo "  make ps               Show running containers + health"
	@echo "  make status           Show Debezium connector status"
	@echo "  make connectors       List registered Debezium connectors"
	@echo "  make topics           List Kafka topics"
	@echo ""

# ── Lifecycle ─────────────────────────────────────────────────────────────────
up:
	$(COMPOSE) up -d --remove-orphans

initial-setup: up
	@echo ""
	@echo "⏳  Waiting for all services to be healthy..."
	@$(COMPOSE) wait sqlserver-init mysql-init mongodb-init postgres-init minio-init 2>/dev/null || true
	@echo "⏳  Waiting for Debezium Connect to be ready (up to 90s)..."
	@for i in $$(seq 1 18); do \
		curl -sf http://localhost:8083/connectors >/dev/null 2>&1 && break; \
		echo "   ...$$((i*5))s"; sleep 5; \
	done
	@$(COMPOSE) wait debezium-init 2>/dev/null || true
	@echo ""
	@echo "✅  FeatureFlow data sources ready!"
	@echo ""
	@echo "  ┌─ Connection Strings ───────────────────────────────────────────┐"
	@echo "  │  SQL Server  jdbc:sqlserver://localhost:1433                   │"
	@echo "  │              user: sa  /  pass: FeatureFlow@2024!             │"
	@echo "  │              DBs: RiskDataMart, ClinicalDB, SupplyChainDB,    │"
	@echo "  │                   PolicyDB, BillingDB                         │"
	@echo "  │                                                                │"
	@echo "  │  MySQL       jdbc:mysql://localhost:3306                      │"
	@echo "  │              user: root  /  pass: FeatureFlow@2024!           │"
	@echo "  │              DBs: credit_data, patient_admin, procurement,    │"
	@echo "  │                   claims_db, network_ops                      │"
	@echo "  │                                                                │"
	@echo "  │  MongoDB     mongodb://root:FeatureFlow@2024!@localhost:27017 │"
	@echo "  │              replicaSet=rs0                                    │"
	@echo "  │              DBs: loan_documents, clinical_notes, sensor_data,│"
	@echo "  │                   risk_assessments, interactions               │"
	@echo "  │                                                                │"
	@echo "  │  PostgreSQL  postgresql://postgres:FeatureFlow@2024!          │"
	@echo "  │              @localhost:5432                                   │"
	@echo "  │              DBs: ratings, registry, demand, tables_db,       │"
	@echo "  │                   catalog_db                                  │"
	@echo "  │                                                                │"
	@echo "  │  MinIO S3    http://localhost:9000                            │"
	@echo "  │              user: featureflow  /  pass: FeatureFlow@2024!    │"
	@echo "  │              Console: http://localhost:9001                   │"
	@echo "  │                                                                │"
	@echo "  │  Kafka       localhost:9092                                   │"
	@echo "  │  Kafka UI    http://localhost:8080                            │"
	@echo "  │  Debezium    http://localhost:8083                            │"
	@echo "  └────────────────────────────────────────────────────────────────┘"
	@echo ""

down:
	$(COMPOSE) down

restart: down up

clean:
	$(COMPOSE) down --remove-orphans

clean-volumes:
	@echo "⚠️  This will delete ALL data volumes. Press Ctrl+C to cancel."
	@sleep 3
	$(COMPOSE) down -v --remove-orphans

# ── Observability ─────────────────────────────────────────────────────────────
logs:
ifdef s
	$(COMPOSE) logs -f $(s)
else
	$(COMPOSE) logs -f
endif

ps:
	$(COMPOSE) ps

status:
	@echo "\n── Debezium Connector Status ──────────────────────────────────"
	@curl -sf 'http://localhost:8083/connectors?expand=status' | \
		python3 -c "\
	import json,sys; data=json.load(sys.stdin); [print(f'  {n:<35} {i.get(\"status\",{}).get(\"connector\",{}).get(\"state\",\"?\")}'  ) for n,i in data.items()] \
	" 2>/dev/null || echo "  Debezium not reachable at localhost:8083" 
	@echo ""

connectors:
	@echo "\n── Registered Connectors ──────────────────────────────────────"
	@curl -sf http://localhost:8083/connectors | python3 -c \
		"import json,sys; [print(\"  \"+c) for c in json.load(sys.stdin)]" \
		2>/dev/null || echo "  Debezium not reachable"
	@echo ""

topics:
	@echo "\n── Kafka Topics ───────────────────────────────────────────────"
	@docker exec ff_kafka kafka-topics \
		--bootstrap-server localhost:9092 --list 2>/dev/null | \
		grep -v '^__' | sed 's/^/  /' || echo "  Kafka not reachable"
	@echo ""
