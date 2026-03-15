#!/bin/bash
# ============================================================
# Waits for MSSQL to be ready then runs 01_init.sql
# Used as the entrypoint for the mssql-init one-shot container
# ============================================================

set -e

HOST="${MSSQL_HOST:-mssql-primary}"
SA_PASS="${SA_PASSWORD:-FeatureFlow_2024!}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

echo "Waiting for SQL Server at $HOST..."
for i in $(seq 1 30); do
    if $SQLCMD -S "$HOST" -U sa -P "$SA_PASS" -No -Q "SELECT 1" &>/dev/null; then
        echo "SQL Server is up (attempt $i)"
        break
    fi
    echo "  attempt $i/30 — sleeping 5s"
    sleep 5
done

echo "Running init script..."
$SQLCMD -S "$HOST" -U sa -P "$SA_PASS" -No -i /mssql-init/01_init.sql

echo "MSSQL init done"
