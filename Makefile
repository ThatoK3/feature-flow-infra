.PHONY: help up down clean logs status diag init-mongo-key

help:
	@echo "Available commands:"
	@echo "  make up              - Start all services in detached mode"
	@echo "  make down            - Stop all services"
	@echo "  make clean           - Stop and remove all containers, networks, and volumes (WARNING: deletes data)"
	@echo "  make logs            - Tail logs of all services"
	@echo "  make status          - Show container status"
	@echo "  make diag            - Run diagnostics script to verify health and CDC"
	@echo "  make init-mongo-key  - Generate MongoDB keyfile (required before first up)"

init-mongo-key:
	@if [ ! -f mongo-keyfile ]; then \
		openssl rand -base64 756 > mongo-keyfile; \
		chmod 400 mongo-keyfile; \
		echo "Generated mongo-keyfile"; \
	else \
		echo "mongo-keyfile already exists"; \
	fi

up: init-mongo-key
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v
	rm -f mongo-keyfile

logs:
	docker compose logs -f

status:
	docker compose ps

diag:
	@./diagnostics.sh
