# Replication Techniques

Replication focuses on **Streaming Replication** and **Logical Replication**, especially for high-availability financial platforms like `banking_db`.

## 🔁 PostgreSQL Replication: Overview

**`Replication`** enables one or more PostgreSQL servers (**replicas**) to maintain copies of the data on a primary server. This allows for:

- **High Availability**
- **Disaster Recovery**
- **Horizontal Read Scaling**
- **Data Distribution**

PostgreSQL offers two primary replication techniques:

| Type                      | Use Case                            | Data Level   | Supports Writes?   | Lag Sensitivity | Use With |
| ------------------------- | ----------------------------------- | ------------ | ------------------ | --------------- | -------- |
| **Streaming Replication** | Hot standby, failover               | Binary (WAL) | ❌ No              | Low             | HA       |
| **Logical Replication**   | Fine-grained replication, migration | Table rows   | ✅ Yes (on target) | Moderate        | BI, Sync |

---

## 1. 🔌 Streaming Replication (Binary Replication)

### 🔧 How It Works

- **Physical** replication of WAL (Write-Ahead Logs)
- Standby continuously receives WAL from the primary via TCP
- Can be **synchronous** or **asynchronous**

### 🏦 Banking Use Case

- Failover for transaction-critical systems
- Ensures **no data loss** in synchronous mode
- Enables **read scaling** by routing heavy read queries to replicas

### ✅ Setup Steps

#### 🔹 Primary Node Config (`postgresql.conf`)

```conf
wal_level = replica
max_wal_senders = 10
wal_keep_size = 2GB
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'
hot_standby = on
```

#### 🔹 `pg_hba.conf` Entry (Allow Standby to Connect)

```
host replication replicator_user 192.168.1.0/24 md5
```

#### 🔹 Create Replication User

```sql
CREATE ROLE replicator_user WITH REPLICATION LOGIN PASSWORD 'secret';
```

#### 🔹 Base Backup to Replica

```bash
pg_basebackup -h primary_host -U replicator_user -D /var/lib/postgresql/15/main -P -R
```

💡 `-R` auto-generates `standby.signal` and `primary_conninfo` for recovery.

---

### 🔄 Sync vs Async

| Mode   | Behavior                                | Risk               |
| ------ | --------------------------------------- | ------------------ |
| Async  | WAL sent but not guaranteed applied     | Some data loss     |
| Sync   | WAL must be **acknowledged** by standby | Slower write speed |
| Quorum | Wait for _N out of M_ standbys          | HA + Performance   |

### 🧠 Considerations

- Place replicas in **different data centers**
- Use **pg_auto_failover** or **Patroni** for HA cluster management
- Consider **pgBackRest** for WAL archiving & replication consistency

---

## 2. 🔄 Logical Replication (Row-Level Streaming)

### 🔧 How It Works

- Replicates **table-level changes** (INSERT/UPDATE/DELETE)
- Uses **logical decoding** of WAL stream
- Publisher–Subscriber model

### 🏦 Banking Use Case

- Real-time **reporting systems**
- **Audit log database**
- **Cross-region data** syncs for low-latency reads

---

### ✅ Setup Steps

#### 🔹 Publisher DB (Primary)

```sql
-- Ensure wal_level = logical in postgresql.conf
CREATE PUBLICATION banking_pub FOR TABLE accounts, transactions;
```

#### 🔹 Subscriber DB (Secondary)

```sql
CREATE SUBSCRIPTION banking_sub
  CONNECTION 'host=primary_ip dbname=banking_db user=replicator password=secret'
  PUBLICATION banking_pub;
```

### 📌 Key Facts

- Supports **row filtering** and **column projection** (PostgreSQL 15+)
- Useful for **blue-green deployments**, **zero-downtime migrations**
- Supports **bi-directional replication** (careful: conflict resolution needed)

---

## 🧠 Logical Replication vs Streaming Replication

| Feature               | Streaming | Logical                       |
| --------------------- | --------- | ----------------------------- |
| Whole DB replicated   | ✅ Yes    | ❌ No (table-level only)      |
| Cross-version support | ❌ No     | ✅ Yes (PostgreSQL ≥10)       |
| Writeable subscribers | ❌ No     | ✅ Yes                        |
| Supports DDL          | ❌ No     | ❌ No (must reapply manually) |
| Use case              | HA, DR    | ETL, Auditing, Sync           |

---

## 🛠️ Tooling for HA & Replication Management

| Tool                 | Purpose                         |
| -------------------- | ------------------------------- |
| **Patroni**          | HA clustering, leader election  |
| **repmgr**           | Replica management and failover |
| **pg_auto_failover** | Auto promotion of standbys      |
| **pgBackRest**       | WAL archiving & backups         |
| **Stolon**           | Kubernetes-native HA system     |

---

## 💡 Scaling Banking Systems

- **Combine streaming + logical**:

  - Use streaming replication for HA
  - Use logical replication for reporting/migration

- Design **read replicas** per region
- Use **pglogical** for fine-grained logical replication features
- Automate replication setup in CI/CD pipeline using Ansible/Terraform

---

## 📄 Moreover setup

1. **Docker Compose-based replication cluster** with `pg_auto_failover` or `Patroni`
2. **Script-based end-to-end setup** of both replication types
3. **Kubernetes manifest** for PostgreSQL HA with replication
4. **Monitoring setup** (e.g., `pg_stat_replication`, `pgmetrics`, `Prometheus`)
