#!/bin/bash

# PostgreSQL Sharding Setup using Citus for Banking DB (banking_db)

# Full Senior-Level Guide

# 1. Assumptions:

# - Ubuntu 22.04+, PostgreSQL 15+, Citus extension installed

# - Banking schema involves accounts, transactions, users, branches, etc.

# 2. Install PostgreSQL & Citus

curl https://install.citusdata.com/community/deb.sh | sudo bash
sudo apt-get -y install postgresql-15-citus-15

# 3. Initialize Cluster (optional if already running)

sudo systemctl start postgresql

# 4. Setup Coordinator and Worker Nodes

# Assume localhost testing: 1 coordinator, 2 workers

sudo -u postgres psql -c "CREATE ROLE citus WITH LOGIN PASSWORD 'citus' SUPERUSER;"

# Update pg_hba.conf and postgresql.conf accordingly for replication & citus communication

# Enable:

# shared_preload_libraries = 'citus'

# listen_addresses = '\*'

# wal_level = replica

# max_wal_senders = 10

# wal_keep_size = 512MB

# hot_standby = on

# Coordinator Setup

sudo -u postgres createdb banking_db
sudo -u postgres psql -d banking_db -c "CREATE EXTENSION citus;"

# Create schema

sudo -u postgres psql -d banking_db -f ./banking_schema.sql

# Add workers

sudo -u postgres psql -d banking_db -c "SELECT _ from master_add_node('localhost', 5433);"
sudo -u postgres psql -d banking_db -c "SELECT _ from master_add_node('localhost', 5434);"

# 5. Distribute Tables

# Choose sharding key carefully, typically account_id or customer_id

sudo -u postgres psql -d banking_db -c "SELECT create_distributed_table('accounts', 'account_id');"
sudo -u postgres psql -d banking_db -c "SELECT create_distributed_table('transactions', 'account_id');"
sudo -u postgres psql -d banking_db -c "SELECT create_reference_table('branches');"

# 6. Test Sharding

sudo -u postgres psql -d banking_db -c "\d+ accounts"
sudo -u postgres psql -d banking_db -c "SELECT \* FROM citus_shards;"

# 7. Replication (WAL Streaming + Hot Standby can be set per node)

# Example for each worker and coordinator replication setup:

# - Base backup using pg_basebackup

# - Configure recovery.conf or standby.signal (PostgreSQL >= 12)

# - Archive WALs with archive_command

# 8. Monitor and Maintain

# Citus provides catalog tables like pg_dist_node, pg_dist_shard, etc.

# Use citus_stat_activity to monitor queries

# 9. Optional: Citus MX for multi-tenant SaaS

# Enables tenant isolation with colocated tables
