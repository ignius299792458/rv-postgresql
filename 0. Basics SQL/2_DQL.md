# **Data Query Language (DQL)**

DQL is focused on retrieving data from a relational database. Although **`SELECT`** is the primary keyword under DQL, it’s incredibly rich and powerful—especially when combined with SQL functions, clauses, joins, and expressions.

## 🔹 Overview of DQL

**DQL (Data Query Language)**:

- **Purpose**: Retrieve data from one or more tables.
- **Primary Command**: `SELECT`
- **Key Clauses**: `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`, `OFFSET`, and combinations with joins, subqueries, window functions, etc.

---

## 🔸 1. SELECT Syntax & Basic Usage

```sql
SELECT column1, column2, ...
FROM table_name;
```

### Examples:

```sql
SELECT name, email FROM users;
SELECT * FROM orders;
```

---

## 🔸 2. SELECT with WHERE (Filtering Rows)

```sql
SELECT * FROM users WHERE age > 25;
SELECT * FROM orders WHERE status = 'DELIVERED';
```

### Operators:

- `=`, `!=`, `<`, `>`, `<=`, `>=`
- `BETWEEN`, `IN`, `LIKE`, `IS NULL`, `IS NOT NULL`

---

## 🔸 3. SELECT with Logical Operators

```sql
SELECT * FROM users WHERE age > 25 AND city = 'Kathmandu';
SELECT * FROM orders WHERE status = 'CANCELLED' OR created_at < '2024-01-01';
```

---

## 🔸 4. SELECT with DISTINCT

```sql
SELECT DISTINCT country FROM customers;
```

Removes duplicate values in the result set.

---

## 🔸 5. ORDER BY (Sorting Results)

```sql
SELECT * FROM products ORDER BY price ASC;
SELECT * FROM products ORDER BY created_at DESC;
```

---

## 🔸 6. LIMIT & OFFSET (Pagination)

```sql
SELECT * FROM customers LIMIT 10;
SELECT * FROM customers LIMIT 10 OFFSET 20;
```

---

## 🔸 7. Aliases (`AS`)

```sql
SELECT first_name AS fname, last_name AS lname FROM employees;
```

---

## 🔸 8. Aggregate Functions (used with GROUP BY)

| Function  | Description       |
| --------- | ----------------- |
| `COUNT()` | Counts rows       |
| `SUM()`   | Sums values       |
| `AVG()`   | Average of values |
| `MAX()`   | Maximum value     |
| `MIN()`   | Minimum value     |

```sql
SELECT department_id, COUNT(*) FROM employees GROUP BY department_id;
SELECT department_id, AVG(salary) FROM employees GROUP BY department_id HAVING AVG(salary) > 50000;
```

---

## 🔸 9. JOINs (Combining Multiple Tables)

### Types:

- `INNER JOIN`
- `LEFT JOIN` (or LEFT OUTER)
- `RIGHT JOIN`
- `FULL OUTER JOIN`
- `CROSS JOIN`

```sql
SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id;
```

---

## 🔸 10. Subqueries

### Inline:

```sql
SELECT name FROM users WHERE id IN (SELECT user_id FROM orders WHERE total > 1000);
```

### In SELECT clause:

```sql
SELECT name, (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) as total_orders
FROM users u;
```

---

## 🔸 11. Window Functions

```sql
SELECT
  employee_id, department_id, salary,
  RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;
```

Functions: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE(n)`, `LEAD()`, `LAG()`, `SUM()`, `AVG()` OVER windows

---

## 🔸 12. CASE Expressions (Conditional Logic)

```sql
SELECT name,
       CASE
         WHEN age < 18 THEN 'Minor'
         WHEN age < 60 THEN 'Adult'
         ELSE 'Senior'
       END AS age_group
FROM users;
```

---

## 🔸 13. CTE (Common Table Expressions)

```sql
WITH top_customers AS (
  SELECT user_id, SUM(total) as total_spent
  FROM orders
  GROUP BY user_id
  HAVING SUM(total) > 10000
)
SELECT u.name, t.total_spent
FROM users u
JOIN top_customers t ON u.id = t.user_id;
```

---

## 🔸 14. Set Operations

```sql
SELECT name FROM customers
UNION
SELECT name FROM vendors;

SELECT name FROM customers
INTERSECT
SELECT name FROM vendors;

SELECT name FROM customers
EXCEPT
SELECT name FROM vendors;
```

---

## 🔸 15. JSON & Array Querying (PostgreSQL Specific)

### JSON:

```sql
SELECT data->>'name' AS name FROM json_table WHERE data->>'type' = 'premium';
```

### Arrays:

```sql
SELECT * FROM tags WHERE 'urgent' = ANY(tag_array);
```

---

## 🔸 16. Advanced Filtering with EXISTS

```sql
SELECT name FROM users u WHERE EXISTS (
  SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.total > 1000
);
```

---

## 🔸 17. Materialized Views & Performance

In read-heavy systems:

```sql
CREATE MATERIALIZED VIEW top_sellers AS
SELECT seller_id, COUNT(*) as sales FROM orders GROUP BY seller_id;
```

---

## 🧠 Summary Mind Map

```
DQL → SELECT
     → FROM → JOINs
     → WHERE → Operators → Logical
     → GROUP BY → HAVING
     → ORDER BY
     → LIMIT/OFFSET
     → Aggregates
     → Subqueries, CTEs
     → CASE, Window Functions
     → JSON/Array Querying
     → Set Operations
     → EXISTS, IN, NOT IN
```
