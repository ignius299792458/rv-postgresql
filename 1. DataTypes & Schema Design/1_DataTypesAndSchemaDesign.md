# PostgreSQL Data Types and Schema Design

# 🧱 PART 1: PostgreSQL Data Types

PostgreSQL offers **rich, extensible data types**, some of which are built-in and some user-defined.

## 🧮 1. Numeric Types

| Type                  | Description         | Storage  | Notes                              |
| --------------------- | ------------------- | -------- | ---------------------------------- |
| `smallint`            | 2-byte integer      | 2B       | Range: -32k to 32k                 |
| `integer`             | 4-byte integer      | 4B       | Default for most IDs               |
| `bigint`              | 8-byte integer      | 8B       | For large counters, like sequences |
| `numeric` / `decimal` | Arbitrary precision | variable | Slower, use for money              |
| `real`                | 4-byte float        | 4B       | Approximate, avoid for money       |
| `double precision`    | 8-byte float        | 8B       | Approximate, scientific computing  |

🧠 **Insights:**

- **Use `bigint` for IDs if system may scale significantly.**
- **Avoid floating-point for monetary values due to rounding errors.** Use `numeric(12,2)` or similar.
- **`numeric` is slower** than fixed-size ints/floats — avoid overusing it.

---

## 📅 2. Date/Time Types

| Type                                                     | Description                         |
| -------------------------------------------------------- | ----------------------------------- |
| `timestamp` / `timestamp with time zone` (`timestamptz`) | With or without time zone awareness |
| `date`                                                   | Calendar date only                  |
| `time`                                                   | Time of day                         |
| `interval`                                               | Duration                            |
| `timezone`                                               | Implicit in `timestamptz`           |

🧠 **Insight:**

- Always **prefer `timestamptz`** unless you're sure you don't need time zone handling.
- **Use `interval`** for time differences or durations.
- Be aware: **`timestamp` is not aware of time zones**, `timestamptz` is stored in UTC and converted to the session’s time zone.

---

## 🧾 3. Textual Types

| Type         | Description              |
| ------------ | ------------------------ |
| `text`       | Unlimited length string  |
| `varchar(n)` | String with max length n |
| `char(n)`    | Fixed-length string      |

🧠 **Best Practices:**

- Use `text` **almost always**; there's no performance gain with `varchar(n)`.
- `char(n)` is mostly for legacy or fixed-format needs (like ISO codes).

---

## 🔢 4. Boolean

- `boolean` stores `TRUE`, `FALSE`, `NULL`.
- Uses 1 byte.

🧠 Avoid creating `enum('yes', 'no')` types when `boolean` suffices.

---

## 🧬 5. Enumerated Types (`enum`)

- `CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');`

🧠 **Use for controlled, small categorical values.**

- Internally stored as **int**.
- **Hard to modify** (adding values requires `ALTER TYPE` and possible downtime in migrations).

---

## 📦 6. Arrays

- Any PostgreSQL type can be stored in arrays.
- Example: `integer[]`, `text[]`, `uuid[]`.

🧠 **Use carefully** — they're easy to query (`ANY`, `UNNEST`), but can hinder normalization.

- **Indexing arrays** via GIN index helps with performance (`CREATE INDEX ... USING GIN`).

---

## 🧩 7. JSON / JSONB

- `json`: Textual, stored as-is.
- `jsonb`: Binary, decomposed, indexed, faster.

🧠 Prefer **`jsonb`** for querying or indexing.

- `jsonb` supports **GIN indexing**, key existence queries (`?`, `@>`), path queries.
- Don't use it as an excuse to avoid normalization — **great for schema-less side attributes**, not primary models.

---

## 🧾 8. UUID

- Universally Unique Identifiers.
- Use for **distributed ID generation**, safer than `bigserial`.

🧠 Downsides:

- **Slower joins** (16 bytes vs 8 bytes for `bigint`).
- **Harder to debug** manually.

---

## 💎 9. Composite & Custom Types

- `CREATE TYPE my_type AS (field1 integer, field2 text);`
- Can be used in tables or functions.

🧠 Useful for structured return types, e.g., from functions returning table-like data.

---

## 🧠 10. Special Types

- `cidr`, `inet`, `macaddr`: network types
- `tsvector`, `tsquery`: full-text search
- `range` types: `[int4range, tsrange, daterange]` – powerful for time-based scheduling, range constraints
- `money`: Fixed precision, but locale-sensitive — prefer `numeric`

---

# 📐 PART 2: PostgreSQL Schema Design (Advanced)

Designing schemas like a principal engineer involves **domain modeling**, **performance-aware choices**, and **migration planning**.

---

## 1. 🎯 Data Modeling Principles

- **Normalize** for integrity (3NF or higher).
- **Denormalize** selectively for performance (with care).
- **Prefer UUID or BIGINT PKs** — avoid natural keys as PKs.
- **Use Foreign Keys** to enforce integrity — **never rely on app-level joins only.**
- Use **CHECK constraints**, **NOT NULL**, and **DEFAULT**s.

---

## 2. 📊 Indexing Strategy

- Use **B-tree indexes** for equality/range.
- Use **GIN** for arrays, JSONB, full-text.
- Use **BRIN** for large, append-only datasets with natural ordering (e.g., logs).
- Use **partial indexes** and **expression indexes** for performance tuning.

🧠 Principal tips:

- Avoid **index sprawl** — each index adds overhead to writes.
- **Composite indexes** should match query patterns (leftmost prefix rule).
- Use `EXPLAIN (ANALYZE)` regularly.

---

## 3. 🔀 Partitioning & Sharding

- **Declarative Partitioning** in PG ≥10:

  - Range, List, Hash

- Partition large, write-heavy tables by `created_at`, `user_id`, etc.
- Combine with **foreign table** or **Citus** for sharding.

---

## 4. 🔁 Schema Evolution

- Use **idempotent migrations** via tools (like `Flyway`, `Sqitch`, `Alembic`, `Liquibase`).
- Never drop columns/tables without prior deprecation phases.
- Be aware of **lock acquisition** when running `ALTER TABLE` — use `pg_repack` or background migrations for large data.

---

## 5. 🔐 Security & Permissions

- Use **roles and grants** to separate access (read-only, app user, admin).
- Use **row-level security (RLS)** for multitenancy.
- Enforce **connection pooling** with tools like `PgBouncer`.

---

## 6. ⚙️ Performance Monitoring

- Track slow queries via `pg_stat_statements`.
- Tune autovacuum, checkpoints.
- Understand `EXPLAIN`, `VACUUM`, `ANALYZE`, WAL implications.

---

## 📦 Use Cases & Design Examples

**Case: Audit Log Table**

```sql
CREATE TABLE audit_log (
  id bigserial PRIMARY KEY,
  actor_id uuid NOT NULL,
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid,
  data jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);
```

- Add **BRIN indexes** on `created_at`.
- Partition monthly.
- Use **foreign keys** to user table if needed.

---

## ✅ Final Tips

1. **Master `EXPLAIN (ANALYZE)` and `pg_stat_statements`**.
2. Understand how **MVCC**, WAL, and Vacuum\*\* work internally.
3. Think **migration-safe**: zero downtime deployments.
4. Use **schemas** (`public`, `internal`, `admin`, etc.) to isolate subsystems.
5. Evaluate **logical replication** for live migrations.
6. Stay on top of PostgreSQL releases — new features often simplify older workarounds.

---
