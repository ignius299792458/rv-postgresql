# **SQL Data Manipulation Language (DML)**

## 🧠 What is DML?

**Data Manipulation Language (DML)** is the subset of SQL used to **manipulate data** stored in relational database tables. It does **not** define the structure of the tables (that's DDL), but rather **operates on the data inside the structure**.

### ✅ DML Commands:

| Command  | Description          |
| -------- | -------------------- |
| `SELECT` | Retrieve data        |
| `INSERT` | Add new data         |
| `UPDATE` | Modify existing data |
| `DELETE` | Remove data          |

> ❗️Note: While `SELECT` is technically not part of DML in some strict definitions (especially in the SQL standard, which puts it under DQL), most real-world practitioners include it in DML.

---

## 📚 1. `SELECT` — Reading Data

### 🔹 Basic Syntax

```sql
SELECT column1, column2
FROM table_name
WHERE condition
ORDER BY column1 DESC
LIMIT 10;
```

### 🔹 Advanced Concepts

#### a. Aliases

```sql
SELECT first_name AS fname, salary * 12 AS annual_salary
FROM employees;
```

#### b. Filtering: `WHERE`, `IN`, `BETWEEN`, `LIKE`, `IS NULL`

```sql
WHERE age BETWEEN 20 AND 30
AND name LIKE 'A%'
AND department_id IN (1, 2, 3)
```

#### c. Aggregate Functions

```sql
SELECT COUNT(*), AVG(salary), MAX(join_date)
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 5000;
```

#### d. Joins

- `INNER JOIN`
- `LEFT OUTER JOIN`
- `RIGHT OUTER JOIN`
- `FULL OUTER JOIN`
- `CROSS JOIN`
- `SELF JOIN`

```sql
SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.dept_id = d.id;
```

#### e. Subqueries and Common Table Expressions (CTEs)

```sql
-- Subquery
SELECT name
FROM employees
WHERE salary > (
    SELECT AVG(salary) FROM employees
);

-- CTE
WITH HighEarners AS (
    SELECT * FROM employees WHERE salary > 10000
)
SELECT * FROM HighEarners WHERE department_id = 3;
```

#### f. Window Functions

```sql
SELECT name, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;
```

---

## 📚 2. `INSERT` — Adding Data

### 🔹 Basic Syntax

```sql
INSERT INTO table_name (column1, column2)
VALUES ('value1', 'value2');
```

### 🔹 Multiple Rows

```sql
INSERT INTO products (name, price)
VALUES
  ('Laptop', 1500),
  ('Phone', 800);
```

### 🔹 Insert from another query

```sql
INSERT INTO archived_employees
SELECT * FROM employees WHERE status = 'INACTIVE';
```

### 🔹 With `RETURNING` (PostgreSQL, Oracle, etc.)

```sql
INSERT INTO users (name, email)
VALUES ('Ignius', 'ignius@fire.com')
RETURNING id;
```

---

## 📚 3. `UPDATE` — Modifying Data

### 🔹 Basic Syntax

```sql
UPDATE employees
SET salary = salary * 1.1
WHERE department_id = 5;
```

### 🔹 Update with Subquery

```sql
UPDATE employees
SET department_id = (
  SELECT id FROM departments WHERE name = 'R&D'
)
WHERE name = 'Ignius';
```

### 🔹 Update with `FROM` (PostgreSQL)

```sql
UPDATE employees e
SET salary = salary + b.bonus
FROM bonuses b
WHERE e.id = b.employee_id;
```

### 🔹 Return updated rows (PostgreSQL)

```sql
UPDATE employees
SET salary = salary + 500
WHERE performance_rating = 'A'
RETURNING id, name, salary;
```

---

## 📚 4. `DELETE` — Removing Data

### 🔹 Basic Syntax

```sql
DELETE FROM employees
WHERE resignation_date IS NOT NULL;
```

### 🔹 Using `RETURNING`

```sql
DELETE FROM employees
WHERE id = 42
RETURNING *;
```

### 🔹 With Subquery

```sql
DELETE FROM orders
WHERE customer_id IN (
  SELECT id FROM customers WHERE inactive = true
);
```

---

## 🔒 Transactional Control with DML

- **DML statements are transactional**. Changes are _not permanent_ until committed.

### 🔹 Example

```sql
BEGIN;

UPDATE accounts SET balance = balance - 500 WHERE id = 1;
UPDATE accounts SET balance = balance + 500 WHERE id = 2;

-- Commit when all OK
COMMIT;

-- Rollback if any issue
ROLLBACK;
```

---

## 🧰 DML Optimization Tips for Advanced Engineers

### 1. **Use Indexes Wisely**

- On `WHERE`, `JOIN`, `ORDER BY` columns.
- Avoid full-table scans for frequent queries.

### 2. **Batch Inserts/Updates**

- Use `INSERT INTO ... VALUES (...), (...)` over individual statements.

### 3. **Avoid Deadlocks**

- Always acquire locks in the same order.
- Use smaller transactions.

### 4. **Analyze Query Plans**

- PostgreSQL: `EXPLAIN ANALYZE`
- Helps identify slow joins or sequential scans.

### 5. **Use `RETURNING`**

- Saves round trips by getting affected data in a single query.

### 6. **Use `UPSERT` (`INSERT ... ON CONFLICT`)**

```sql
INSERT INTO users (id, name)
VALUES (1, 'Ignius')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
```

---

## 📋 Advanced Use Cases

### 🔸 Soft Delete (Logical Deletion)

```sql
-- Instead of DELETE
UPDATE users SET is_deleted = TRUE WHERE id = 1;
```

### 🔸 History Table (Audit Logs)

```sql
-- Trigger to capture INSERT/UPDATE/DELETE into audit table
```

### 🔸 Merge / Upsert in ANSI SQL (not supported by all)

```sql
MERGE INTO employees AS target
USING new_employees AS source
ON target.id = source.id
WHEN MATCHED THEN
  UPDATE SET target.salary = source.salary
WHEN NOT MATCHED THEN
  INSERT (id, name, salary) VALUES (source.id, source.name, source.salary);
```

---

## ⚖️ DML vs DDL vs DCL vs TCL

| Type | Full Form           | Examples                               | Purpose             |
| ---- | ------------------- | -------------------------------------- | ------------------- |
| DML  | Data Manipulation   | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | Work with data      |
| DDL  | Data Definition     | `CREATE`, `ALTER`, `DROP`              | Change schema       |
| DCL  | Data Control        | `GRANT`, `REVOKE`                      | Access control      |
| TCL  | Transaction Control | `COMMIT`, `ROLLBACK`, `SAVEPOINT`      | Manage transactions |

---

## ✅ Summary Checklist for Mastery

- [x] Fully understand all DML commands and their variations.
- [x] Know how transactions interact with DML.
- [x] Be proficient with joins, subqueries, and window functions.
- [x] Use `RETURNING`, CTEs, and batch DML effectively.
- [x] Handle concurrency and deadlocks.
- [x] Profile and optimize DML queries using EXPLAIN/ANALYZE.
- [x] Design systems with soft deletes, audit trails, and safe upserts.
