#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f .env ]; then
    echo -e "${RED}ERROR: .env file not found. Please create it from .env.example${NC}"
    exit 1
fi
export $(grep -v '^#' .env | xargs)

check_cmd() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}ERROR: $1 is not installed. Please install it.${NC}"
        exit 1
    fi
}
check_cmd docker
check_cmd docker compose
check_cmd curl
check_cmd jq

echo -e "${YELLOW}=== Healthcare Platform Diagnostics (with MySQL) ===${NC}\n"

# 1. Container status
echo -e "${YELLOW}Checking container status...${NC}"
services="zookeeper kafka akhq mongodb postgres mssql mysql connect minio redis"
all_running=true
for svc in $services; do
    if docker compose ps --status running | grep -q "healthcare-$svc"; then
        echo -e "${GREEN}✓ $svc is running${NC}"
    else
        echo -e "${RED}✗ $svc is NOT running${NC}"
        all_running=false
    fi
done
echo ""

if [ "$all_running" = false ]; then
    echo -e "${RED}Some services are not running. Run 'docker compose ps' for details.${NC}"
    exit 1
fi

# 2. MongoDB replica set
echo -e "${YELLOW}Checking MongoDB replica set...${NC}"
mongo_rs=$(docker exec healthcare-mongodb mongosh -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --quiet --eval "rs.status().ok")
if [ "$mongo_rs" -eq 1 ]; then
    echo -e "${GREEN}✓ MongoDB replica set is healthy${NC}"
else
    echo -e "${RED}✗ MongoDB replica set not initialised${NC}"
fi

# 3. PostgreSQL logical replication
echo -e "${YELLOW}Checking PostgreSQL...${NC}"
if docker exec healthcare-postgres psql -U "$POSTGRES_USER" -d healthcare -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PostgreSQL accessible${NC}"
else
    echo -e "${RED}✗ PostgreSQL not accessible${NC}"
fi

# 4. MSSQL CDC enabled?
echo -e "${YELLOW}Checking MSSQL CDC...${NC}"
if docker exec healthcare-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT name, is_cdc_enabled FROM sys.databases WHERE name='healthcare'" | grep -q "1"; then
    echo -e "${GREEN}✓ CDC is enabled on healthcare database${NC}"
else
    echo -e "${YELLOW}⚠ CDC not enabled (you may need to run enable_cdc.sql manually)${NC}"
fi

# 5. MySQL binlog + GTID
echo -e "${YELLOW}Checking MySQL binlog configuration...${NC}"
binlog_format=$(docker exec healthcare-mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -sN -e "SHOW VARIABLES LIKE 'binlog_format'" 2>/dev/null | awk '{print $2}')
gtid_mode=$(docker exec healthcare-mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -sN -e "SHOW VARIABLES LIKE 'gtid_mode'" 2>/dev/null | awk '{print $2}')
if [ "$binlog_format" = "ROW" ] && [ "$gtid_mode" = "ON" ]; then
    echo -e "${GREEN}✓ MySQL binlog_format=ROW, gtid_mode=ON${NC}"
else
    echo -e "${RED}✗ MySQL not properly configured for CDC (binlog_format=$binlog_format, gtid_mode=$gtid_mode)${NC}"
fi

# 6. Kafka availability
echo -e "${YELLOW}Checking Kafka...${NC}"
if docker exec healthcare-kafka kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Kafka is reachable${NC}"
else
    echo -e "${RED}✗ Kafka not responding${NC}"
fi

# 7. Debezium Connect
echo -e "${YELLOW}Checking Debezium Connect...${NC}"
connectors=$(curl -s http://localhost:8083/connectors)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Connect API available${NC}"
    count=$(echo "$connectors" | jq length)
    echo -e "   Registered connectors: $count"
else
    echo -e "${RED}✗ Connect not responding${NC}"
fi

# 8. MinIO
echo -e "${YELLOW}Checking MinIO...${NC}"
if curl -s http://localhost:9000/minio/health/live > /dev/null; then
    echo -e "${GREEN}✓ MinIO healthy${NC}"
else
    echo -e "${RED}✗ MinIO not healthy${NC}"
fi

# 9. Redis
echo -e "${YELLOW}Checking Redis...${NC}"
if docker exec healthcare-redis redis-cli -a "$REDIS_PASSWORD" ping | grep -q PONG; then
    echo -e "${GREEN}✓ Redis responding${NC}"
else
    echo -e "${RED}✗ Redis not responding${NC}"
fi

echo -e "\n${GREEN}Diagnostics completed.${NC}"
