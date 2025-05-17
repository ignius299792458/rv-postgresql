# 🧩 Sharding

**`Sharding`** is a database architecture pattern that horizontally partitions data across multiple machines. Each partition is called a **`shard`** and is stored on a different database node. PostgreSQL does not support native sharding (yet), but **extensions like [`Citus`](https://www.citusdata.com/)** make this possible.

# 🔷 PostgreSQL Sharding Core Concepts

## 1. **Coordinator Node**

- Acts like a PostgreSQL server.
- Accepts queries from applications.
- Routes parts of the query to the appropriate shard (worker nodes).
- Does aggregation and joins as needed.

## 2. **Worker Nodes**

- Actual data holders.
- Store the shard (partition) of the distributed table.
- Can be scaled horizontally.

## 3. **Shard Key (Distribution Column)**

- A column (or a hash of it) used to determine in which shard a row resides.
- Must be **immutable and high cardinality**.
- Good choices: `account_id`, `customer_id`, `transaction_id`.

---

# 💡 Why Sharding Matters in Banking

| Scenario                                       | Sharding Benefit                             |
| ---------------------------------------------- | -------------------------------------------- |
| Millions of accounts, billions of transactions | Enables scale-out by distributing load       |
| Branch-level analytics                         | Shard by `branch_id` for locality            |
| Tenant-based models (multi-bank SaaS)          | Shard by `tenant_id` or `customer_id`        |
| Avoiding single-node I/O bottlenecks           | Writes go to distributed shards concurrently |

---

# 🧱 Citus-based PostgreSQL Sharding Architecture

```
                             +------------------+
                             |   Application    |
                             +--------+---------+
                                      |
                         +------------v------------+
                         |  Coordinator (Citus DB)  |
                         +------------+------------+
                                      |
         +----------------------------+-----------------------------+
         |                            |                             |
+--------v--------+        +----------v----------+        +--------v--------+
|   Worker Node 1 |        |   Worker Node 2     |        |   Worker Node 3 |
|  (Shard 1, 4…)  |        |  (Shard 2, 5…)      |        |  (Shard 3, 6…)  |
+-----------------+        +---------------------+        +-----------------+
```

---

# 🛠️ Key Operations in PostgreSQL Sharding (via Citus)

## 1. **Setup Citus**

```sql
-- On Coordinator
CREATE EXTENSION citus;

-- Register Workers
SELECT * from master_add_node('worker1.local', 5432);
SELECT * from master_add_node('worker2.local', 5432);
```

## 2. **Create Distributed Table**

```sql
-- Create reference tables
CREATE TABLE branches (
  id UUID PRIMARY KEY,
  name TEXT
);
SELECT create_reference_table('branches');

-- Create distributed table
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  account_id UUID NOT NULL,
  amount NUMERIC,
  timestamp TIMESTAMP
);
SELECT create_distributed_table('transactions', 'account_id');
```

---

# 📊 Partitioning vs Sharding

| Feature          | Partitioning                       | Sharding                      |
| ---------------- | ---------------------------------- | ----------------------------- |
| Scope            | Single node                        | Multi-node                    |
| Performance gain | Local (index pruning, parallelism) | Global (scale-out)            |
| Complexity       | Lower                              | Higher                        |
| Best Use         | Time-series, static lists          | High-write OLTP, multi-tenant |

---

# 🛡️ Real-world Considerations in Banking Sharding

## 🔁 Replication:

- Use streaming replication per node.
- Enable WAL compression for network efficiency.

## 💥 High Availability:

- Coordinator can be HA with tools like `Patroni` or `Stolon`.
- Workers replicate independently (async or sync).

## 🪛 Failover Handling:

- Set up health checks for workers.
- Replace failed workers using `master_add_node()` / `master_remove_node()`.

## 🕵️ Query Routing and Optimization:

- Co-located joins → use same shard key.
- Use `reference tables` for common joins.
- Avoid distributed joins unless needed.

---

# 🧠 Performance Tips

- Choose a shard key with high cardinality and low update frequency.
- Aim for uniform data distribution (no hotspots).
- Use read replicas for analytics queries.
- Pre-aggregate for OLAP-style workloads.

---

# 🛠️ Monitoring Tools

- `pg_stat_activity` & `pg_stat_statements`
- `citus_stat_activity`, `citus_shards`
- Prometheus + Grafana dashboards
- Use pgBouncer for connection pooling

---

# 🔐 Security for Sharded Banking Systems

- TLS between all DB nodes and apps.
- Row-level security (RLS) per tenant if needed.
- Audit logging per shard.
- Use VPC/private networking to isolate data paths.

---

# ✅ Pros and Cons

| Pros                                | Cons                            |
| ----------------------------------- | ------------------------------- |
| Scales horizontally                 | Complex setup & maintenance     |
| Can isolate workloads per tenant    | Not ideal for cross-shard joins |
| Boosts write throughput             | Needs careful key selection     |
| Integrates with standard PostgreSQL | May require query rewriting     |

---

# 📁 Other ways

- Break down Citus vs other sharding alternatives (e.g., Postgres-XL, CockroachDB)?
- Generate a `docker-compose` playground for testing Citus sharding?
- Integrate this with your `banking_db` schema and create real sharding scenarios?
