# PostgreSQL Replication and High Availability Guide

This guide provides comprehensive instructions for setting up and managing PostgreSQL replication and high availability solutions at a senior engineering level.

## Table of Contents

1. [Streaming Replication Setup](#streaming-replication-setup)
2. [Logical Replication Setup](#logical-replication-setup)
3. [High Availability with Patroni](#high-availability-with-patroni)
4. [Connection Pooling with pgBouncer](#connection-pooling-with-pgbouncer)
5. [Load Balancing with pgpool-II](#load-balancing-with-pgpool-ii)
6. [Monitoring and Management](#monitoring-and-management)
7. [Failover and Recovery Procedures](#failover-and-recovery-procedures)
8. [Advanced Configuration](#advanced-configuration)

## Streaming Replication Setup

### Prerequisites

- PostgreSQL 12+ installed on all servers
- Network connectivity between servers
- Sufficient disk space on replica servers
- Same PostgreSQL version on all servers

### Step 1: Configure Primary Server

Edit the `postgresql.conf` file on the primary server:

```
# Required settings
listen_addresses = '*'                  # Listen on all available addresses
wal_level = replica                     # Minimum for streaming replication
max_wal_senders = 10                    # Max number of walsender processes
max_replication_slots = 10              # Max number of replication slots
wal_keep_size = 1GB                     # Keep WAL segments for replica catchup
hot_standby = on                        # Allows read-only queries on standby

# Optional but recommended
archive_mode = on                       # WAL archiving mode
archive_command = 'cp %p /path/to/archive/%f'  # Command to archive WAL segments
full_page_writes = on                   # Protect against partial page writes
wal_compression = on                    # Compress WAL segments
wal_log_hints = on                      # Required for pg_rewind
```

Edit the `pg_hba.conf` file to allow replica connections:

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Allow replication connections from specific hosts
host    replication     replicator      10.0.0.0/24             md5
```

### Step 2: Create Replication User

On the primary server:

```sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'secure_password';
```

### Step 3: Create Replication Slot (Optional but Recommended)

On the primary server:

```sql
SELECT pg_create_physical_replication_slot('standby1_slot');
```

### Step 4: Take Base Backup

On the replica server:

```bash
# Stop PostgreSQL on replica if running
sudo systemctl stop postgresql

# Clear data directory (if exists)
rm -rf /var/lib/postgresql/14/main/*

# Take base backup
pg_basebackup -h primary.example.com -D /var/lib/postgresql/14/main -U replicator -P -v -X stream -S standby1_slot
```

### Step 5: Configure Replica Server

Create a `standby.signal` file in the data directory:

```
# This file tells PostgreSQL this is a standby server
```

Create or modify `postgresql.conf` on the replica:

```
# Replication settings
primary_conninfo = 'host=primary.example.com port=5432 user=replicator password=secure_password application_name=standby1'
primary_slot_name = 'standby1_slot'  # If using replication slots
hot_standby = on
```

### Step 6: Start Replica Server

```bash
sudo systemctl start postgresql
```

### Step 7: Verify Replication Status

On the primary server:

```sql
-- Check replication connections
SELECT pid, application_name, client_addr, state, sync_state
FROM pg_stat_replication;

-- Check replication slots
SELECT slot_name, slot_type, active
FROM pg_replication_slots;
```

On the replica server:

```sql
-- Check replication status
SELECT pg_is_in_recovery();  -- Should return true for replica

-- Check replication lag
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;
```

## Logical Replication Setup

### Step 1: Configure Primary (Publisher) Server

Edit the `postgresql.conf` file:

```
# Required settings
listen_addresses = '*'
wal_level = logical                     # Required for logical replication
max_replication_slots = 10              # Should be >= number of subscriptions
max_wal_senders = 10                    # Should be >= number of subscriptions
```

Edit the `pg_hba.conf` file:

```
# Allow replication connections
host    all             replicator      10.0.0.0/24             md5
```

Restart PostgreSQL:

```bash
sudo systemctl restart postgresql
```

### Step 2: Create Replication User

On both primary and replica servers:

```sql
CREATE ROLE replicator WITH LOGIN REPLICATION PASSWORD 'secure_password';
```

### Step 3: Create Publication on Primary

```sql
-- For specific tables
CREATE PUBLICATION pub_name FOR TABLE customers, bank_accounts;

-- Or for all tables
CREATE PUBLICATION pub_all FOR ALL TABLES;

-- Add options if needed
ALTER PUBLICATION pub_name SET (publish = 'insert, update, delete');
```

### Step 4: Create Subscription on Replica

Ensure the tables exist on the replica with compatible schema:

```sql
-- Create matching tables (can use pg_dump -s for schema only)
-- Then create subscription
CREATE SUBSCRIPTION sub_name
CONNECTION 'host=primary.example.com port=5432 dbname=dbname user=replicator password=secure_password'
PUBLICATION pub_name;
```

### Step 5: Verify Logical Replication Status

On the primary:

```sql
-- Check publications
SELECT * FROM pg_publication;

-- Check publication tables
SELECT * FROM pg_publication_tables;
```

On the replica:

```sql
-- Check subscriptions
SELECT * FROM pg_subscription;

-- Check subscription status
SELECT * FROM pg_stat_subscription;
```

## High Availability with Patroni

### Step 1: Install Prerequisites

On all servers:

```bash
# Install Python and required packages
sudo apt update
sudo apt install -y python3 python3-pip python3-dev libpq-dev

# Install etcd (distributed configuration store)
sudo apt install -y etcd
```

### Step 2: Install Patroni

```bash
sudo pip3 install patroni[etcd] psycopg2-binary
```

### Step 3: Configure etcd

Edit `/etc/default/etcd` on the etcd server(s):

```
ETCD_NAME="etcd1"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://etcd1.example.com:2379"
```

For a cluster setup, add additional configuration for clustering.

Start etcd:

```bash
sudo systemctl start etcd
sudo systemctl enable etcd
```

### Step 4: Create Patroni Configuration

Create `/etc/patroni/patroni.yml` on each PostgreSQL server:

```yaml
scope: postgres-cluster
namespace: /service/
name: postgresql1

restapi:
  listen: 0.0.0.0:8008
  connect_address: postgresql1.example.com:8008

etcd:
  hosts: etcd1.example.com:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        wal_keep_size: 1GB
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"
        
  initdb:
    - encoding: UTF8
    - data-checksums

postgresql:
  listen: 0.0.0.0:5432
  connect_address: postgresql1.example.com:5432
  data_dir: /var/lib/postgresql/14/main
  bin_dir: /usr/lib/postgresql/14/bin
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: secure_password
    superuser:
      username: postgres
      password: secure_postgres_password
  parameters:
    unix_socket_directories: '/var/run/postgresql'

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```

Customize the configuration for each server (change name, connect_address, etc).

### Step 5: Create Patroni Service

Create `/etc/systemd/system/patroni.service`:

```
[Unit]
Description=Patroni Postgresql Cluster Service
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
KillMode=process
TimeoutSec=30
Restart=always

[Install]
WantedBy=multi-user.target
```

### Step 6: Start Patroni Service

```bash
sudo systemctl start patroni
sudo systemctl enable patroni
```

### Step 7: Verify Patroni Cluster

```bash
# Check cluster status
patronictl -c /etc/patroni/patroni.yml list

# View cluster information in etcd
etcdctl get --prefix /service/postgres-cluster

# Check replication status in PostgreSQL
sudo -u postgres psql -c "SELECT pid, application_name, client_addr, state, sync_state FROM pg_stat_replication;"
```

## Connection Pooling with pgBouncer

### Step 1: Install pgBouncer

```bash
sudo apt install -y pgbouncer
```

### Step 2: Configure pgBouncer

Edit `/etc/pgbouncer/pgbouncer.ini`:

```ini
[databases]
* = host=localhost port=5432 dbname=postgres

[pgbouncer]
listen_addr = *
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
admin_users = postgres
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 100
reserve_pool_size = 20
reserve_pool_timeout = 5
max_db_connections = 100
server_reset_query = DISCARD ALL
server_check_delay = 30
server_check_query = SELECT 1
```

Create `/etc/pgbouncer/userlist.txt`:

```
"postgres" "md5password"
```

To generate md5 passwords:

```bash
echo -n "passwordusername" | md5sum | awk '{print "md5"$1}'
```

### Step 3: Start pgBouncer

```bash
sudo systemctl start pgbouncer
sudo systemctl enable pgbouncer
```

### Step 4: Verify pgBouncer

```bash
# Connect to pgbouncer admin console
psql -p 6432 -U postgres pgbouncer -c "SHOW POOLS;"

# Test regular connection through pgbouncer
psql -h localhost -p 6432 -U postgres -d postgres
```

## Load Balancing with pgpool-II

### Step 1: Install pgpool-II

```bash
sudo apt install -y pgpool2
```

### Step 2: Configure pgpool-II

Edit `/etc/pgpool2/pgpool.conf`:

```
# Connection Settings
listen_addresses = '*'
port = 5433
socket_dir = '/var/run/postgresql'
backend_hostname0 = 'primary.example.com'
backend_port0 = 5432
backend_weight0 = 1
backend_flag0 = 'ALLOW_TO_FAILOVER'
backend_hostname1 = 'replica1.example.com'
backend_port1 = 5432
backend_weight1 = 1
backend_flag1 = 'ALLOW_TO_FAILOVER'

# Authentication
enable_pool_hba = on
pool_passwd = 'pool_passwd'
authentication_timeout = 1min

# Connection Pooling
num_init_children = 100
max_pool = 4
child_life_time = 5min
child_max_connections = 0
connection_life_time = 0
client_idle_limit = 0

# Load Balancing
load_balance_mode = on
ignore_leading_white_space = on
white_function_list = ''
black_function_list = 'nextval,setval'

# Replication Mode
replication_mode = off
replicate_select = off

# Health Check
health_check_period = 10
health_check_timeout = 20
health_check_user = 'postgres'
health_check_password = 'postgres_password'
health_check_database = 'postgres'

# Failover
failover_command = '/etc/pgpool2/failover.sh %d %h %p %D %m %H %M %P %r %R'
failback_command = ''
fail_over_on_backend_error = on
search_primary_node_timeout = 10

# Streaming Replication
sr_check_period = 10
sr_check_user = 'postgres'
sr_check_password = 'postgres_password'
sr_check_database = 'postgres'
delay_threshold = 10000000
```

Create `/etc/pgpool2/pool_hba.conf`:

```
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
host    all         all         0.0.0.0/0             md5
```

Create `/etc/pgpool2/pool_passwd`:

```bash
pg_md5 -m -u postgres postgres_password
```

### Step 3: Create Failover Script

Create `/etc/pgpool2/failover.sh`:

```bash
#!/bin/bash

# Parameters passed by pgpool
FAILED_NODE_ID="$1"
FAILED_HOST="$2"
FAILED_PORT="$3"
FAILED_DB="$4"
NEW_MASTER_ID="$5"
NEW_MASTER_HOST="$6"
NEW_MASTER_PORT="$7"
NEW_MASTER_DB="$8"
OLD_MASTER_ID="$9"
OLD_PRIMARY_ID="${10}"

# Log the event
logger -t pgpool-failover "Failover triggered: Failed node ID=$FAILED_NODE_ID, New master ID=$NEW_MASTER_ID"

exit 0
```

Make the script executable:

```bash
chmod +x /etc/pgpool2/failover.sh
```

### Step 4: Start pgpool-II

```bash
sudo systemctl start pgpool2
sudo systemctl enable pgpool2
```

### Step 5: Verify pgpool-II

```bash
# Show pool status
PGPASSWORD=postgres_password psql -h localhost -p 5433 -U postgres -d postgres -c "SHOW POOL_NODES;"

# Test connection through pgpool
PGPASSWORD=postgres_password psql -h localhost -p 5433 -U postgres -d postgres
```

## Monitoring and Management

### Replication Monitoring

#### 1. Check Replication Status

On primary:

```sql
-- Check streaming replication status
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, 
       (pg_wal_lsn_diff(sent_lsn, replay_lsn) / 1024 / 1024) AS lag_mb
FROM pg_stat_replication;

-- Check replication slots
SELECT slot_name, slot_type, database, active, restart_lsn, confirmed_flush_lsn
FROM pg_replication_slots;

-- For logical replication
SELECT * FROM pg_stat_publication;
```

On replica:

```sql
-- Check streaming replication status
SELECT pg_is_in_recovery() AS is_replica;
SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(),
       pg_last_xact_replay_timestamp(),
       extract(epoch FROM now() - pg_last_xact_replay_timestamp()) AS lag_seconds;

-- For logical replication
SELECT * FROM pg_stat_subscription;
```

#### 2. Monitoring Metrics to Track

- Replication lag (bytes and time)
- WAL generation rate
- Network transfer rate between servers
- Disk usage and free space on WAL volumes
- CPU/Memory usage on both primary and replicas
- Number of active WAL senders/receivers

### Automated Monitoring Solutions

#### Prometheus + Grafana Setup

1. Install Prometheus PostgreSQL Exporter:

```bash
sudo apt install prometheus-postgres-exporter
```

2. Configure the exporter (`/etc/default/prometheus-postgres-exporter`):

```
DATA_SOURCE_NAME="user=postgres host=/var/run/postgresql/ sslmode=disable"
```

3. Install Prometheus and Grafana:

```bash
sudo apt install prometheus grafana
```

4. Configure Prometheus (`/etc/prometheus/prometheus.yml`):

```yaml
scrape_configs:
  - job_name: 'postgresql'
    static_configs:
      - targets: ['localhost:9187']
```

5. Import PostgreSQL dashboards in Grafana (ID 9628, 12485, or similar)

## Failover and Recovery Procedures

### Manual Failover Process

1. Promote a replica to primary:

```bash
# Option 1: Using pg_ctl
sudo -u postgres pg_ctl promote -D /var/lib/postgresql/14/main

# Option 2: Using touch file
sudo -u postgres touch /var/lib/postgresql/14/main/failover.signal
```

2. Update application configuration to point to new primary

3. Reconfigure old primary as replica (if still available):

```bash
# Stop PostgreSQL
sudo systemctl stop postgresql

# Create standby.signal file
sudo -u postgres touch /var/lib/postgresql/14/main/standby.signal

# Update postgresql.conf with new primary connection info
sudo -u postgres nano /var/lib/postgresql/14/main/postgresql.conf
# Add/modify: primary_conninfo = 'host=new_primary port=5432 user=replicator password=secure_password'

# Start PostgreSQL
sudo systemctl start postgresql
```

### Automated Failover

With Patroni:

```bash
# Manual switchover (planned)
patronictl -c /etc/patroni/patroni.yml switchover

# Check cluster status
patronictl -c /etc/patroni/patroni.yml list
```

With pgpool-II:

```bash
# Attach/detach nodes
pcp_attach_node -h localhost -p 9898 -U postgres -w -n 1

# Switch primary (planned failover)
pcp_promote_node -h localhost -p 9898 -U postgres -w -n 1
```

### Recovery from Split-Brain Scenario

1. Identify the current true primary
2. Stop PostgreSQL on all conflicting nodes
3. Use pg_rewind to resynchronize:

```bash
pg_rewind --target-pgdata=/var/lib/postgresql/14/main \
          --source-server="host=true_primary port=5432 user=postgres password=postgres_password" \
          --progress
```

4. Create standby.signal file and reconfigure as replica
5. Start PostgreSQL

## Advanced Configuration

### Synchronous Replication

On primary server, edit `postgresql.conf`:

```
# For one synchronous standby
synchronous_standby_names = 'FIRST 1 (standby1, standby2)'

# For multiple synchronous standbys (any 2 of 3)
synchronous_standby_names = 'ANY 2 (standby1, standby2, standby3)'
```

Check synchronous replication status:

```sql
SELECT application_name, sync_state FROM pg_stat_replication;
```

### Cascading Replication

Configure tertiary replica to connect to secondary instead of primary:

```
primary_conninfo = 'host=secondary.example.com port=5432 user=replicator password=secure_password'
```

Enable hot_standby on the secondary:

```
hot_standby = on
```

### WAL Archiving and PITR

Configure WAL archiving on primary (`postgresql.conf`):

```
archive_mode = on
archive_command = 'rsync -a %p user@backup-server:/path/to/archive/%f'
```

Create base backup for PITR:

```bash
pg_basebackup -D /backup/base -Ft -z -P
```

Perform Point-in-Time Recovery:

```bash
# Create recovery.conf in the data directory
recovery_target_time = '2023-05-10 12:00:00'
restore_command = 'cp /path/to/archive/%f %p'
```

### Replication with pg_basebackup vs. pg_dump

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| pg_basebackup | Full instance replication | Exact copy, includes all DBs and settings | Must have same hardware architecture, requires WAL streaming |
| pg_dump | Selective data migration | Flexible, can restore specific objects, version-independent | Not real-time, larger overhead, application must be updated |

### Conflict Resolution in Logical Replication

Handle primary key conflicts:

```sql
-- On the subscriber
ALTER SUBSCRIPTION sub_name DISABLE;

-- Resolve conflicts (example: discard conflicts)
DELETE FROM conflicting_table 
WHERE primary_key IN (
    SELECT t1.primary_key
    FROM conflicting_table t1
    JOIN remote_source t2 USING (primary_key)
);

-- Re-enable subscription
ALTER SUBSCRIPTION sub_name ENABLE;
```

## Sharding Strategy Example

For a banking application with the schema provided:

```sql
-- Create sharding function based on customer_id
CREATE OR REPLACE FUNCTION shard_customer_id(uuid_val UUID) 
RETURNS INTEGER AS $$
BEGIN
    -- Extract numeric value from UUID and map to shard number (0-7)
    RETURN (('x' || substring(uuid_val::text, 1, 8))::bit(32)::int % 8);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create foreign servers for each shard
CREATE SERVER shard0 FOREIGN DATA WRAPPER postgres_fdw 
OPTIONS (host 'shard0.example.com', port '5432', dbname 'bankdb');

-- Repeat for shard1 through shard7

-- Create user mapping
CREATE USER MAPPING FOR CURRENT_USER SERVER shard0
OPTIONS (user 'postgres', password 'secure_password');

-- Repeat for shard1 through shard7

-- Create foreign tables for each shard
CREATE FOREIGN TABLE customers_shard0 (LIKE customers)
SERVER shard0 OPTIONS (table_name 'customers');

-- Repeat for other shards and tables

-- Create view that combines all shards
CREATE VIEW customers_all AS
    SELECT * FROM customers_shard0
    UNION ALL
    SELECT * FROM customers_shard1
    UNION ALL
    -- ... repeat for all shards
    SELECT * FROM customers_shard7;
```

For application-level sharding, implement logic to determine the shard:

```python
def get_shard_connection(customer_id):
    # Extract UUID bytes and determine shard number
    shard_num = hash(customer_id) % 8
    # Get connection to appropriate shard
    conn_string = f"host=shard{shard_num}.example.com dbname=bankdb user=app password=secure_password"
    return psycopg2.connect(conn_string)
```
