#!/bin/bash
# PostgreSQL Sharding Setup using Citus for banking_db (Docker Compose Based)
# Senior Engineering Level Deployment Script

# 1. Create docker-compose.yml for Coordinator and Worker Nodes
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  coordinator:
    image: citusdata/citus:11.3
    container_name: citus_coordinator
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=secret
      - POSTGRES_DB=banking_db
    networks:
      - citus_network

  worker1:
    image: citusdata/citus:11.3
    container_name: citus_worker1
    environment:
      - POSTGRES_PASSWORD=secret
    networks:
      - citus_network

  worker2:
    image: citusdata/citus:11.3
    container_name: citus_worker2
    environment:
      - POSTGRES_PASSWORD=secret
    networks:
      - citus_network

networks:
  citus_network:
    driver: bridge
EOF

# 2. Start the cluster
docker-compose up -d

# 3. Wait for startup (or verify manually)
sleep 20

# 4. Connect to Coordinator to set up Citus cluster
cat > init_citus_cluster.sql <<EOF
CREATE EXTENSION IF NOT EXISTS citus;
SELECT * from master_add_node('citus_worker1', 5432);
SELECT * from master_add_node('citus_worker2', 5432);
EOF

docker exec -i citus_coordinator psql -U postgres -d banking_db < init_citus_cluster.sql

# 5. Create Reference and Distributed Tables
cat > schema.sql <<EOF
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT
);
SELECT create_reference_table('branches');

CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    balance NUMERIC NOT NULL
);
SELECT create_distributed_table('accounts', 'customer_id');

CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL
);
SELECT create_distributed_table('transactions', 'account_id');
EOF

docker exec -i citus_coordinator psql -U postgres -d banking_db < schema.sql

# 6. Verification Queries
docker exec -i citus_coordinator psql -U postgres -d banking_db -c "SELECT * FROM pg_dist_node;"
docker exec -i citus_coordinator psql -U postgres -d banking_db -c "SELECT * FROM citus_shards;"

# 7. Done.
echo "✅ PostgreSQL Sharding via Docker Compose Complete for banking_db"
