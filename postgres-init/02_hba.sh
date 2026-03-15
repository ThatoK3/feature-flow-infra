#!/bin/bash
# Append replication entry to pg_hba.conf
echo "host replication ${POSTGRES_REPLICATION_USER} 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
# Allow Debezium logical replication from anywhere (lock down in prod)
echo "host all ${POSTGRES_USER} 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
