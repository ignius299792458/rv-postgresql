# **JOINs and relationship types in PostgreSQL**

### 🔗 **RELATIONSHIP TYPES**

1. **One-to-One (1:1)**

   - Example: You could have a separate `kyc_details` table with `customer_id` as a **unique foreign key** to `customers.customer_id`.
   - ✅ Enforced via `UNIQUE` on the foreign key.

   ```sql
   CREATE TABLE kyc_details (
     customer_id UUID PRIMARY KEY REFERENCES customers(customer_id),
     document_type TEXT,
     document_number TEXT,
     issued_on DATE,
     verified BOOLEAN
   );
   ```

2. **One-to-Many (1\:N)**

   - ✅ Most common.
   - Example: One customer has many `bank_accounts` or `transactions`.

   ```sql
   -- customers.customer_id → bank_accounts.customer_id (1:N)
   ```

3. **Many-to-Many (M\:N)**

   - Requires a **junction table**.
   - Example: Let's say customers can have **multiple advisors**, and advisors can handle **multiple customers**.

   ```sql
   CREATE TABLE advisors (
     advisor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     name TEXT
   );

   CREATE TABLE customer_advisors (
     customer_id UUID REFERENCES customers(customer_id),
     advisor_id UUID REFERENCES advisors(advisor_id),
     PRIMARY KEY (customer_id, advisor_id)
   );
   ```

---

### 🔀 **JOIN TYPES IN POSTGRESQL**

Let’s break these down using your schema.

---

### 1. **INNER JOIN**

➡️ Returns rows **only if there is a match** in both tables.

**Example:** Get customers with their active bank accounts.

```sql
SELECT c.first_name, c.last_name, b.account_number
FROM customers c
INNER JOIN bank_accounts b ON c.customer_id = b.customer_id
WHERE b.status = 'Active';
```

---

### 2. **LEFT JOIN (or LEFT OUTER JOIN)**

➡️ Returns all rows from the **left** table, plus matched rows from the right. If no match, right side will be `NULL`.

**Example:** Get all customers, even if they don’t have bank accounts yet.

```sql
SELECT c.first_name, c.last_name, b.account_number
FROM customers c
LEFT JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

---

### 3. **RIGHT JOIN (or RIGHT OUTER JOIN)**

➡️ Opposite of LEFT JOIN: all rows from **right** table, matched rows from left.

**Example:** Not commonly used, but let’s say you want all bank accounts, even if the customer is soft-deleted.

```sql
SELECT c.first_name, b.account_number
FROM customers c
RIGHT JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

---

### 4. **FULL JOIN (or FULL OUTER JOIN)**

➡️ Combines `LEFT` and `RIGHT`: includes rows with no matches in either table.

**Example:** Get all customers and all accounts, regardless of matching.

```sql
SELECT c.first_name, b.account_number
FROM customers c
FULL JOIN bank_accounts b ON c.customer_id = b.customer_id;
```

---

### 5. **CROSS JOIN**

➡️ Returns **Cartesian product**: every row from `A` with every row from `B`.

**Use Case:** Rare in banking unless generating all combinations (e.g., simulation or batch rule applications).

```sql
SELECT c.first_name, b.account_number
FROM customers c
CROSS JOIN bank_accounts b;
```

---

### 6. **SELF JOIN**

➡️ Joining a table with itself.

**Example:** Find which customer was referred by another customer.

```sql
SELECT c1.first_name AS referred, c2.first_name AS referrer
FROM customers c1
LEFT JOIN customers c2 ON c1.referred_by = c2.customer_id;
```

---

### 7. **LATERAL JOIN**

➡️ Used when a subquery depends on a row from the outer query.

**Example:** Suppose we add a `transactions` summary for each account.

```sql
SELECT a.account_number, t.total_amount
FROM bank_accounts a
LEFT JOIN LATERAL (
    SELECT SUM(amount) AS total_amount
    FROM transactions t
    WHERE t.account_id = a.account_id
) t ON TRUE;
```

---

### 8. **NATURAL JOIN**

➡️ Joins on **columns with the same names** (dangerous if names overlap unexpectedly).

Not recommended in production unless controlled carefully:

```sql
SELECT *
FROM customers
NATURAL JOIN bank_accounts;
```

---

### RELATIONSHIPS + JOIN MAPPING SUMMARY

| Relationship     | PostgreSQL Join Style   | Example                       |
| ---------------- | ----------------------- | ----------------------------- |
| 1:1              | `JOIN` with `UNIQUE` FK | `customers` ↔ `kyc_details`   |
| 1\:N             | `JOIN` with FK          | `customers` → `bank_accounts` |
| M\:N             | Junction Table + 2 FKs  | `customer_advisors`           |
| Self-Referential | `JOIN` on same table    | `customers.referred_by`       |

---

### 🧠 Tip for Complex Types (JSONB, HSTORE):

You can also **join based on fields inside JSONB** using `->>`:

```sql
SELECT *
FROM customers c
JOIN transactions t ON c.customer_id = t.metadata->>'customer_id';
```

Or filter:

```sql
SELECT *
FROM transactions
WHERE metadata->>'device_type' = 'Mobile';
```

---
