**Patroni**, **pgpool-II**, and **PgBouncer**. This setup ensures automated failover, load balancing, and efficient connection pooling, suitable for production environments.

---

## 🛠️ Deployment Overview

**Architecture Components:**

- **PostgreSQL**: Core database instances.
- **Patroni**: Manages PostgreSQL high availability and failover using a Distributed Configuration Store (DCS) like etcd, Consul, or Kubernetes.
- **pgpool-II**: Provides connection pooling, load balancing, and failover handling.
- **PgBouncer**: Lightweight connection pooler to manage client connections efficiently.

**Deployment Strategies:**

- **Ansible**: Automate the provisioning and configuration of the entire stack.
- **Kubernetes**: Deploy and manage the cluster using StatefulSets and Services for scalability and resilience.

---

## 📦 Component Configurations

### 1. Patroni Configuration (`patroni.yml`)

```yaml
scope: postgres-ha
namespace: /db/
name: node1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.1.101:8008

etcd:
  host: 192.168.1.100:2379

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
        wal_keep_segments: 8
        max_wal_senders: 5
        max_replication_slots: 5
  initdb:
    - encoding: UTF8
    - data-checksums
  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.1.101:5432
  data_dir: /var/lib/postgresql/data
  bin_dir: /usr/lib/postgresql/13/bin
  authentication:
    replication:
      username: replicator
      password: replicate
    superuser:
      username: postgres
      password: postgres
  parameters:
    unix_socket_directories: "/var/run/postgresql"
```

**Key Points:**

- Defines the cluster scope and node-specific settings.
- Configures etcd as the DCS for leader election and cluster state management.
- Sets PostgreSQL parameters essential for replication and high availability.

**Reference:** [Patroni Kubernetes Deployment Guide](https://patroni.readthedocs.io/en/latest/kubernetes.html)

---

### 2. pgpool-II Configuration (`pgpool.conf`)

```ini
listen_addresses = '*'
port = 9999
socket_dir = '/var/run/postgresql'

backend_hostname0 = '192.168.1.101'
backend_port0 = 5432
backend_weight0 = 1
backend_flag0 = 'ALLOW_TO_FAILOVER'

backend_hostname1 = '192.168.1.102'
backend_port1 = 5432
backend_weight1 = 1
backend_flag1 = 'ALLOW_TO_FAILOVER'

enable_pool_hba = on
pool_passwd = 'pool_passwd'
authentication_timeout = 60

load_balance_mode = on
replication_mode = off
master_slave_mode = on
master_slave_sub_mode = 'stream'

failover_command = '/etc/pgpool/failover.sh %d %H %P %R'
fail
```

Here’s a deep-dive explanation of high availability (HA) in PostgreSQL using **Patroni**, **pgpool-II**, and **PgBouncer**, tailored for a **principal engineer** level, focusing on **fault tolerance**, **scalability**, and **operational robustness**.

---

## 🧠 Why These Tools?

| Tool          | Purpose                                                                    |
| ------------- | -------------------------------------------------------------------------- |
| **Patroni**   | Automates failover and leader election using DCS (etcd, Consul, Zookeeper) |
| **pgpool-II** | Provides connection pooling, load balancing, and replication control       |
| **PgBouncer** | Lightweight connection pooler to reduce connection overhead                |

A production-grade setup often combines all three, with Patroni for **failover and health checks**, pgpool-II for **connection routing and load balancing**, and PgBouncer for **client-side pooling**.

---

## 🧱 Architecture Breakdown

### 1. **Patroni**: HA Coordinator

- Uses a distributed consensus system like **etcd/Consul/ZooKeeper/Kubernetes API** for shared cluster state.
- Runs on every PostgreSQL node and manages:

  - Health monitoring
  - Replication configuration
  - Promotion of standby to leader during failures

- Patroni PostgreSQL nodes are configured with **hot standby** and **streaming replication**.

#### 🔁 Failover Process:

1. Node health check fails
2. Patroni checks replication lag on followers
3. Best follower promoted to primary
4. Other nodes update config to follow new primary
5. Cluster state is updated in DCS

> Key Feature: _Zero manual intervention in failover events_

---

### 2. **pgpool-II**: Load Balancer + Smart Router

- Handles SQL-aware routing (e.g., read to replicas, write to master)
- Performs **load balancing** among replicas
- Supports:

  - **Health checks**
  - **Failover scripts**
  - **Query rewriting**
  - **Connection pooling**

#### Configuration Highlights:

- `backend_flag0 = 'ALLOW_TO_FAILOVER'`
- `master_slave_mode = on`
- `master_slave_sub_mode = 'stream'`
- `load_balance_mode = on`

#### 🔁 Role in Failover:

- pgpool can detect primary change via health checks
- It uses `failover.sh` script to demote nodes or reconfigure connections
- Supports _watchdog_ mode for HA at the load-balancer level

> Tip: pgpool-II is heavier than PgBouncer; careful tuning is required for high TPS systems.

---

### 3. **PgBouncer**: Client-Side Connection Pooling

- Extremely **lightweight**; uses a **single TCP connection** model
- Good for applications that open/close DB connections frequently
- Reduces overhead on PostgreSQL’s `max_connections` limit

#### Pooling Modes:

- `session`: default; connection is held for entire session
- `transaction`: released after each transaction
- `statement`: most granular (rarely used)

> Use PgBouncer **in front of pgpool-II**, or **directly in front of Patroni primary**.

---

## 🧭 Deployment Topology

```
                      +---------------------+
                      |     Clients/App     |
                      +----------+----------+
                                 |
                      +----------v----------+
                      |      PgBouncer      |  (Client-side pooling)
                      +----------+----------+
                                 |
                      +----------v----------+
                      |      pgpool-II      |  (SQL-aware load balancing)
                      +-----+------+--------+
                            |      |
            +---------------+      +----------------+
            |                                     |
+-----------v----------+            +-------------v-----------+
|   Patroni Node 1     | <-- Primary |   Patroni Node 2       | <-- Replica
| (PostgreSQL + Patroni)|           | (PostgreSQL + Patroni) |
+----------------------+           +-------------------------+
```

---

## 🧪 Best Practices & Advanced Tips

### ⚙ Patroni

- Use `ttl`, `loop_wait`, `retry_timeout` wisely to avoid split-brain
- Combine with **pg_rewind** or WAL-G for fast replica sync
- Store PostgreSQL password in `.pgpass` or DCS secrets for automation

### 🧰 pgpool-II

- Watchdog mode provides **HA for pgpool-II itself**
- Use `pcp` (Pgpool Control Protocol) for remote management
- Monitor with `pgpoolAdmin` or custom dashboards

### 🧵 PgBouncer

- Use `transaction` pooling for best balance of performance and compatibility
- Set `server_lifetime` to recycle backend connections periodically
- Use DNS-based reconfiguration (e.g., primary.example.com) with HAProxy for failover transparency

---

## 🔒 Security Considerations

- TLS for all DCS (etcd/Consul) communication
- Authentication on Patroni REST API
- Pooler-level auth for pgpool-II and PgBouncer
- Role-based access control (RBAC) for all PostgreSQL users

---

## 📈 Observability & Monitoring

- Exporter: `postgres_exporter` for Prometheus metrics
- Patroni: Built-in `/patroni` REST API for health
- pgpool-II: `/pgpool_status`, PCP commands
- PgBouncer: `SHOW POOLS`, `SHOW STATS` for diagnostics

---
