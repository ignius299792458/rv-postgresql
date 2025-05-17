# **High Availability (HA)** architecture for PostgreSQL

It involves designing a fault-tolerant system that ensures minimal downtime, automated failover, load balancing, and optimized connection handling, you need to understand how these components interact **in production clusters**, how they behave during **failure scenarios**, and how to **tune and monitor** them effectively.

---

## 🔧 Core Tools in PostgreSQL High Availability

### 1. **Patroni** – _Automated Failover & Cluster Management_

#### ❓ What is Patroni ?

Patroni is a high-availability solution built on top of PostgreSQL that uses **Etcd**, **Consul**, or **ZooKeeper** as a distributed configuration and consensus system (DCS). It manages:

- Leader election
- Automated failover
- Cluster state consistency

#### 🔍 Core Components

- **PostgreSQL instance**: Each node runs PostgreSQL.
- **DCS (e.g., etcd)**: Stores cluster metadata and elects leader.
- **Patroni agent**: Manages local PostgreSQL and reports status to DCS.

#### 🧠 How It Works

- Patroni periodically checks the health of the local PostgreSQL instance.
- The leader node has read-write access; followers are read-only replicas.
- If the leader fails, the DCS triggers a new election.
- The most up-to-date follower becomes the new leader based on timeline and LSN.

#### ⚠️ Key Considerations

- **Etcd quorum must always be available**; DCS is a single point of truth.
- **Split-brain protection**: Ensure fencing mechanisms (e.g., STONITH, VIP switchovers).
- Can integrate with `HAProxy`, `pgbouncer`, `pgpool`, or DNS-based service discovery.

#### 🧪 Health Checks

- PostgreSQL health (pg_isready, custom scripts)
- Replication lag thresholds
- DCS TTLs

---

### 2. **pgpool-II** – _Connection Pooling, Load Balancing, and Failover Routing_

#### ❓ What It Is

Pgpool-II sits between the client and PostgreSQL servers. It supports:

- Connection pooling
- Load balancing (for SELECTs)
- Automated failover with script hooks
- Query caching and watchdog clustering

#### 📦 Features Breakdown

| Feature                | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| **Connection Pooling** | Reuses backend connections to reduce overhead.           |
| **Load Balancing**     | Distributes SELECT queries across replicas.              |
| **Automated Failover** | Can switch traffic during primary node failure.          |
| **Query Routing**      | Parses SQL and sends write to primary, read to replicas. |
| **Watchdog**           | Heartbeat-based HA across multiple pgpool instances.     |

#### ⚙️ Internal Modes

- **Replication mode**: pgpool writes to multiple backends (not preferred with streaming).
- **Streaming replication mode**: Used with PostgreSQL-native replication.

#### 🧠 Key Concepts

- **Blacklisting**: Failing nodes get blacklisted.
- **Backend health check**: Periodic TCP checks.
- **Mode settings**: `load_balance_mode`, `replication_mode`, `failover_command`.

#### ⚠️ Caveats

- Adds latency due to SQL parsing.
- Complex to configure for large systems.
- Not ideal for very high throughput unless carefully tuned.

---

### 3. **pgbouncer** – _Lightweight Connection Pooler_

#### ❓ What It Is

Pgbouncer is a high-performance connection pooler designed to reduce overhead from PostgreSQL's native connection handling.

#### 🔍 Pooling Modes

| Mode            | Description                                         |
| --------------- | --------------------------------------------------- |
| **Session**     | One backend per client connection. Safe but heavy.  |
| **Transaction** | Connection reused per transaction. Good balance.    |
| **Statement**   | Most aggressive. Not safe with session-level state. |

#### 🧠 Why It Matters

PostgreSQL forks a process per connection. With thousands of concurrent clients, it strains system resources. Pgbouncer mitigates this by:

- Maintaining a small pool of persistent backend connections
- Queueing new incoming client connections if all backend connections are busy

#### ⚠️ Considerations

- Does **not support all PostgreSQL features**, especially those requiring session state (e.g., `SET LOCAL` or temp tables).
- Limited to one database per pgbouncer instance unless you configure virtual databases.

#### 🔐 Auth & TLS

- Central auth via `.pgbouncer.userlist` or PostgreSQL’s own HBA mechanism.
- TLS termination is supported.

---

## 🧩 Putting It All Together – HA Architecture Design

```plaintext
                    +-----------------+
                    |  Application(s) |
                    +--------+--------+
                             |
                        [pgbouncer]
                             |
                        [HAProxy / pgpool-II]
                             |
               +-------------+---------------+
               |                             |
         +-----v-----+                 +-----v-----+
         | Patroni 1 |                 | Patroni 2 |
         | (Primary) | <--- WAL ---+--| (Replica) |
         +-----------+             |  +-----------+
                                   |
                             +-----v-----+
                             | Patroni N |
                             +-----------+
```

### 🧠 Flow of Operations

1. **Client → pgbouncer**: Manages pooled client sessions.
2. **pgbouncer → pgpool-II (optional)**: If used, handles load balancing and failover logic.
3. **pgpool/HAProxy → Patroni-managed PG**: Routes traffic to current leader (for writes) or replicas (for reads).
4. **Patroni**: Ensures one primary and consistent replication state.
5. **Failover**: Patroni uses DCS to promote a replica and notify other services.
6. **Service Discovery**: Applications use virtual IPs, DNS SRV, or Consul for leader tracking.

---

## 🔍 Real-World Practices for Principal Engineers

### 🛠 Operational Best Practices

| Area             | Best Practice                                                                     |
| ---------------- | --------------------------------------------------------------------------------- |
| **Monitoring**   | Use `Prometheus + Grafana`, `Patroni REST API`, `pg_stat_replication`             |
| **Backups**      | Integrate `pgBackRest` or `wal-g` for continuous archiving                        |
| **Security**     | TLS for all inter-node communication; password or certificate auth                |
| **Fencing**      | Use STONITH or cloud APIs (like AWS ASG or VIP demotion) to isolate old primaries |
| **Testing**      | Regular failover drills; chaos testing to ensure resilience                       |
| **Automation**   | Use Ansible, Terraform, or Kubernetes Operators for infrastructure as code        |
| **Upgrade Path** | Leverage Patroni’s controlled switchover and rolling upgrades                     |

---

## 🧪 Failure Scenarios & Resolution Paths

| Scenario        | Behavior                                                      |
| --------------- | ------------------------------------------------------------- |
| Leader fails    | Patroni triggers failover. New leader elected via DCS quorum. |
| Replica lags    | Patroni ensures it doesn't promote a stale node (LSN check).  |
| Network split   | Patroni uses TTL and fencing. Old leader steps down.          |
| pgpool fails    | If using watchdog, another pgpool node takes over.            |
| DCS quorum loss | Cluster becomes read-only (no leader election).               |

---

## 🧠 Final Thoughts

Focus should be:

- Designing fault-tolerant, observable, and testable clusters
- Ensuring **clean separation of concerns** (connection poolers vs. failover logic)
- Automating operational tasks and disaster recovery
- Understanding **failure propagation** and **how each component recovers or reacts**
