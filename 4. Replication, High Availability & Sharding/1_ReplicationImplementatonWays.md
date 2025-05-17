# PostgreSQL Replication: Streaming and Logical (Principal Engineer Level)

## Overview

PostgreSQL replication allows one or more servers (standbys/replicas) to maintain a copy of the database from a primary server. Two primary replication techniques are:

- **Streaming Replication** (Physical/Binary)
- **Logical Replication** (Row-Level)

Both can be used in tandem to build a highly available, fault-tolerant, and scalable architecture for critical applications like banking systems.

---

## Streaming Replication (Physical/Binary)

### How It Works

- Replicates the entire database by shipping WAL (Write-Ahead Logs) from primary to standby.
- Standby continuously replays these WAL records to stay in sync.

### Use Cases

- High availability and failover
- Read scalability via hot standby

### Setup

#### 1. Configure Primary (`postgresql.conf`)

```conf
wal_level = replica
max_wal_senders = 10
wal_keep_size = 2GB
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'
hot_standby = on
```

#### 2. `pg_hba.conf` (Primary)

```conf
host replication replicator_user 192.168.1.0/24 md5
```

#### 3. Create Replication Role

```sql
CREATE ROLE replicator_user WITH REPLICATION LOGIN PASSWORD 'secret';
```

#### 4. Take Base Backup

```bash
pg_basebackup -h <primary-ip> -U replicator_user -D /var/lib/postgresql/data -P -R
```

#### 5. Start Replica

Ensure `standby.signal` file is present (auto-created with `-R` flag).

### Sync vs Async

- **Synchronous:** No transaction commit on primary until acknowledged by standby.
- **Asynchronous:** Primary doesn’t wait—may lose recent transactions on failover.
- **Quorum-based sync:** Wait for N out of M standbys.

---

## Logical Replication (Row-Level)

### How It Works

- Publishes individual table changes (INSERT, UPDATE, DELETE).
- Subscriber applies these changes independently.

### Use Cases

- Selective table replication
- Data warehouse feeding
- Online upgrades and migrations

### Setup

#### 1. Enable logical WAL

```conf
wal_level = logical
```

#### 2. On Publisher

```sql
CREATE PUBLICATION banking_pub FOR TABLE accounts, transactions;
```

#### 3. On Subscriber

```sql
CREATE SUBSCRIPTION banking_sub
  CONNECTION 'host=publisher_ip dbname=banking_db user=replicator password=secret'
  PUBLICATION banking_pub;
```

### Key Features

- Cross-version replication
- Subscriber is writable
- Bi-directional replication possible (complex conflict resolution required)

---

## Comparison Table

| Feature               | Streaming Replication | Logical Replication |
| --------------------- | --------------------- | ------------------- |
| Full DB replication   | ✅ Yes                | ❌ No (table-level) |
| Writeable replica     | ❌ No                 | ✅ Yes              |
| Cross-version support | ❌ No                 | ✅ Yes              |
| Supports DDL          | ❌ No                 | ❌ No (manual)      |
| Latency Sensitivity   | Low                   | Medium              |
| Use Case              | HA, failover          | ETL, migration      |

---

## Tooling for Production-Grade Replication

| Tool                 | Purpose                          |
| -------------------- | -------------------------------- |
| **Patroni**          | HA clustering with etcd/Consul   |
| **pg_auto_failover** | Auto failover, monitoring        |
| **repmgr**           | Replica management and promotion |
| **Stolon**           | Kubernetes-native HA             |
| **pgBackRest**       | WAL archiving & PITR             |

---

## Best Practices for Banking Systems

- Use **streaming replication** for HA and failover.
- Use **logical replication** for analytical replicas, auditing, reporting, or multi-region sync.
- Combine with **Citus** for sharded horizontal scaling.
- Automate with **Ansible/Terraform** for infrastructure as code.
- Monitor with `pg_stat_replication`, `pg_stat_wal_receiver`, and Prometheus exporters.
