# Normalization and Denormalization Strategies

This understanding is crucial to balancing **data integrity**, **performance**, and **scalability** in complex, high-load systems like banking applications.

## 🧠 **1. What is Normalization?**

**Normalization** is the process of organizing data in a database to:

- Reduce data redundancy (eliminate duplication).
- Improve data integrity (avoid update anomalies).
- Break data into multiple related tables using **foreign keys**.

### ⚙️ Core Normal Forms

- **1NF (First Normal Form):** Atomic values, no arrays or multivalued columns.
- **2NF (Second Normal Form):** Remove partial dependencies (fields dependent on part of a composite PK).
- **3NF (Third Normal Form):** Remove transitive dependencies (fields dependent on non-key fields).

---

### ✅ **Example: Normalization in Your `banking_db`**

Your schema **already shows strong normalization**:

- The `bank_accounts` table stores customer references using a `customer_id` FK (no redundant customer data).
- Transactions are stored separately from accounts and customers — related via `account_id` and `executed_by`.

This prevents anomalies. For example:

```sql
-- Get all active savings accounts for a customer with email
SELECT
    c.first_name, c.last_name, ba.account_number, ba.balance
FROM
    customers c
JOIN
    bank_accounts ba ON c.customer_id = ba.customer_id
WHERE
    c.email = 'user@example.com'
    AND ba.account_type = 'Saving'
    AND ba.status = 'Active';
```

---

## 🏗️ **2. When to Denormalize?**

**Denormalization** combines data (redundantly) to:

- Improve read performance.
- Avoid expensive joins in high-read systems (e.g., analytics, dashboards).
- Simplify document-style storage (JSONB, HSTORE).

It trades off **write complexity** and **storage** for **read speed**.

---

### 🔁 **Example: Where Denormalization Helps**

1. **Audit logs and metadata as JSONB**
   Instead of creating normalized `audit_logs` or `device_info` tables:

```sql
-- Store audit and device info inline (denormalized)
audit_trail: {
    "action": "withdrawal",
    "timestamp": "2025-05-17T09:00:00Z",
    "actor": "mobile-app"
}
```

This avoids joins when you query logs for compliance or traceability:

```sql
SELECT transaction_id, metadata->>'note', audit_trail->>'actor'
FROM transactions
WHERE audit_trail->>'actor' = 'mobile-app';
```

2. **Customer `preferences`, `tags`, and `account_flags`**
   Storing preferences (like notification opt-ins, KYC preferences) in HSTORE allows flexibility without altering schema.

```sql
SELECT *
FROM customers
WHERE preferences -> 'notify_sms' = 'true';
```

3. **`transactions.tags` as TEXT\[]**
   Enables multi-category tagging without a join table:

```sql
SELECT *
FROM transactions
WHERE 'important' = ANY(tags);
```

---

## 🧬 **Hybrid Strategy: Normalize Core, Denormalize Non-Critical**

| Field Type                       | Normalize        | Denormalize (JSONB/HSTORE/Array)   |
| -------------------------------- | ---------------- | ---------------------------------- |
| Customer identity data           | ✅ Yes           | ❌ No                              |
| Transaction metadata/audit trail | ❌ No            | ✅ Yes                             |
| Account types/currency           | ✅ Lookup tables | ❌ Hardcode in enums only if fixed |
| Tags/preferences/flags           | ❌ No            | ✅ Yes                             |

---

## 🧰 Example Schema Improvement with Normalization

Let’s normalize recurring payment rules into a separate table instead of storing in `JSONB`.

### 👎 Current:

```sql
recurrence_rule JSONB
```

### 👍 Normalized:

```sql
CREATE TABLE recurrence_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    frequency TEXT CHECK (frequency IN ('Daily', 'Weekly', 'Monthly')),
    interval INT DEFAULT 1,
    end_date DATE,
    metadata JSONB
);

ALTER TABLE payments ADD COLUMN recurrence_rule_id UUID REFERENCES recurrence_rules(rule_id);
```

### Benefits:

- Easier to validate and reuse recurrence patterns.
- Reduced duplication.
- Query all weekly payments:

```sql
SELECT p.payment_id, p.amount
FROM payments p
JOIN recurrence_rules r ON p.recurrence_rule_id = r.rule_id
WHERE r.frequency = 'Weekly';
```

---

## 📊 Analytical Use Case: Denormalized JSONB for OLAP Queries

Let’s say your `audit_log` or `metadata` in `transactions` has app version or latency logs. You can index it:

```sql
CREATE INDEX idx_transactions_audit_log ON transactions USING GIN (audit_trail);
```

And query:

```sql
SELECT COUNT(*), audit_trail->>'actor'
FROM transactions
GROUP BY audit_trail->>'actor';
```

This is much faster than joining an external table in analytics use cases.

---

## ⚖️ Trade-offs Comparison

| Criteria           | Normalization                   | Denormalization                       |
| ------------------ | ------------------------------- | ------------------------------------- |
| Storage Efficiency | ✅ High                         | ❌ More duplication                   |
| Write Complexity   | ✅ Simple updates               | ❌ Higher due to redundancy           |
| Read Performance   | ❌ Requires joins               | ✅ Faster reads                       |
| Schema Evolution   | ❌ Rigid structure              | ✅ Flexible (JSONB/HSTORE/ARRAYS)     |
| Data Integrity     | ✅ Referential integrity via FK | ❌ Integrity must be handled manually |

---

## 🧪 When Should You Normalize vs Denormalize?

### Normalize when:

- Ensuring **strong integrity** (e.g., customers, accounts).
- Your writes/updates are frequent.
- Storage is a concern.

### Denormalize when:

- Optimizing **read-heavy workloads**.
- You have **unpredictable/optional fields** (e.g., preferences, metadata).
- You’re building **event logs**, **audit trails**, or **analytics**.

---

## 🧠 Summary

In a complex PostgreSQL schema like your `banking_db`:

✅ Normalize:

- Core relationships: Customers ↔ Accounts ↔ Transactions
- Lookup tables (account types, currencies, statuses)

✅ Denormalize:

- Metadata, audit logs, device info → JSONB
- Preferences, flags → HSTORE
- Tags → Arrays

---

## 🧩 Bonus Queries for Practice

### 1. Accounts with overdraft > 1000 and a "platinum" flag

```sql
SELECT a.account_id, a.balance
FROM bank_accounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE a.overdraft_limit > 1000
  AND account_flags -> 'tier' = 'platinum';
```

### 2. Transactions flagged and made on a mobile device

```sql
SELECT transaction_id, amount
FROM transactions
WHERE is_flagged = TRUE
  AND device_info -> 'device_type' = 'mobile';
```

---
