# **SQL Operators**

## What are SQL Operators?

**Operators** in SQL are special symbols or keywords used to perform operations on one or more expressions or values. They help you compare values, perform arithmetic calculations, combine conditions, and more.

---

# Types of SQL Operators

Here’s the full classification:

| Operator Type     | Purpose                                    | Examples                                  |                                          |                                  |
| ----------------- | ------------------------------------------ | ----------------------------------------- | ---------------------------------------- | -------------------------------- |
| Arithmetic        | Perform mathematical operations            | `+`, `-`, `*`, `/`, `%` (modulus)         |                                          |                                  |
| Comparison        | Compare values to form boolean expressions | `=`, `<>` (or `!=`), `<`, `>`, `<=`, `>=` |                                          |                                  |
| Logical           | Combine multiple conditions                | `AND`, `OR`, `NOT`                        |                                          |                                  |
| Bitwise           | Operate on bits of integer values          | `&`, \`                                   | `, `^`, `\~`, `<<`, `>>\` (varies by DB) |                                  |
| String            | Operate on strings (concatenation)         | \`                                        |                                          | `(in many DBs),`+\` (SQL Server) |
| Set               | Compare sets of values                     | `IN`, `NOT IN`                            |                                          |                                  |
| Null-related      | Handle `NULL` values                       | `IS NULL`, `IS NOT NULL`                  |                                          |                                  |
| Pattern Matching  | String pattern matching                    | `LIKE`, `NOT LIKE`                        |                                          |                                  |
| Other specialized | Additional operators depending on DBMS     | `EXISTS`, `ANY`, `ALL`, `BETWEEN`, etc.   |                                          |                                  |

---

## 1. Arithmetic Operators

Used for mathematical operations on numeric values.

| Operator | Description                  | Example              |
| -------- | ---------------------------- | -------------------- |
| `+`      | Addition                     | `SELECT 5 + 3;` → 8  |
| `-`      | Subtraction                  | `SELECT 10 - 4;` → 6 |
| `*`      | Multiplication               | `SELECT 6 * 7;` → 42 |
| `/`      | Division                     | `SELECT 20 / 5;` → 4 |
| `%`      | Modulus (remainder) (varies) | `SELECT 17 % 5;` → 2 |

**Example:**

```sql
SELECT price, quantity, price * quantity AS total_cost
FROM sales;
```

---

## 2. Comparison Operators

Return `TRUE`, `FALSE`, or `UNKNOWN` (when involving NULLs).

| Operator     | Description              | Example                      |
| ------------ | ------------------------ | ---------------------------- |
| `=`          | Equal to                 | `WHERE age = 25`             |
| `<>` or `!=` | Not equal to             | `WHERE status <> 'active'`   |
| `<`          | Less than                | `WHERE score < 80`           |
| `>`          | Greater than             | `WHERE salary > 50000`       |
| `<=`         | Less than or equal to    | `WHERE date <= '2025-01-01'` |
| `>=`         | Greater than or equal to | `WHERE level >= 10`          |

---

## 3. Logical Operators

Used to combine or negate boolean conditions.

| Operator | Description           | Example                            |
| -------- | --------------------- | ---------------------------------- |
| `AND`    | Both conditions true  | `WHERE age > 20 AND active = 1`    |
| `OR`     | Either condition true | `WHERE city = 'NY' OR city = 'LA'` |
| `NOT`    | Negates condition     | `WHERE NOT (status = 'inactive')`  |

**Example:**

```sql
SELECT * FROM users
WHERE age >= 18 AND status = 'active';
```

---

## 4. Bitwise Operators

Operate on bits within integers (support varies).

| Operator | Description                            | Example                          |     |         |
| -------- | -------------------------------------- | -------------------------------- | --- | ------- |
| `&`      | Bitwise AND                            | `5 & 3 = 1` (binary 0101 & 0011) |     |         |
| \`       | \`                                     | Bitwise OR                       | \`5 | 3 = 7\` |
| `^`      | Bitwise XOR                            | `5 ^ 3 = 6`                      |     |         |
| `~`      | Bitwise NOT (NOT supported everywhere) | `~5` (inverts bits)              |     |         |
| `<<`     | Left shift                             | `5 << 1 = 10`                    |     |         |
| `>>`     | Right shift                            | `5 >> 1 = 2`                     |     |         |

---

## 5. String Operators

### Concatenation

- In **most DBMS** (PostgreSQL, Oracle, SQLite): `||` is used.
- In **SQL Server**: `+` is used.

```sql
SELECT first_name || ' ' || last_name AS full_name FROM employees;  -- PostgreSQL
SELECT first_name + ' ' + last_name AS full_name FROM employees;    -- SQL Server
```

---

## 6. Set Operators

Used to test if a value exists in a list/set.

| Operator | Description                     | Example                            |
| -------- | ------------------------------- | ---------------------------------- |
| `IN`     | Value exists in the given set   | `WHERE department IN ('HR', 'IT')` |
| `NOT IN` | Value does not exist in the set | `WHERE id NOT IN (1, 2, 3)`        |

**Example:**

```sql
SELECT * FROM products WHERE category IN ('Electronics', 'Appliances');
```

---

## 7. Null-Related Operators

`NULL` is a special marker for missing/unknown data. You cannot use `= NULL` or `<> NULL`. Instead, use:

| Operator      | Description                 | Example                   |
| ------------- | --------------------------- | ------------------------- |
| `IS NULL`     | Checks if value is NULL     | `WHERE phone IS NULL`     |
| `IS NOT NULL` | Checks if value is not NULL | `WHERE email IS NOT NULL` |

---

## 8. Pattern Matching Operators

Used to match text patterns.

| Operator   | Description              | Example                                |
| ---------- | ------------------------ | -------------------------------------- |
| `LIKE`     | Matches a pattern        | `WHERE name LIKE 'A%'` (starts with A) |
| `NOT LIKE` | Does not match a pattern | `WHERE email NOT LIKE '%@gmail.com'`   |

**Wildcards in `LIKE`:**

- `%` — Matches zero or more characters
- `_` — Matches exactly one character

**Example:**

```sql
SELECT * FROM customers WHERE name LIKE 'J_n%';
-- Matches names like Jan, Jon, Jane, John...
```

---

## 9. Other Operators

### BETWEEN

Checks if a value lies within a range (inclusive).

```sql
WHERE salary BETWEEN 3000 AND 7000
```

### EXISTS

Tests if a subquery returns any rows.

```sql
WHERE EXISTS (SELECT 1 FROM orders WHERE orders.customer_id = customers.id)
```

### ANY and ALL

Compare a value to any or all values returned by a subquery.

```sql
salary > ANY (SELECT salary FROM employees WHERE department = 'HR')
salary >= ALL (SELECT salary FROM employees WHERE department = 'Sales')
```

---

# Notes on Operator Precedence

Operator precedence determines how expressions are evaluated when multiple operators are combined.

**Typical precedence (highest to lowest):**

1. Arithmetic operators (`*`, `/`, `%` before `+` and `-`)
2. Comparison operators (`=`, `<`, `>`, etc.)
3. NOT
4. AND
5. OR

Use parentheses `()` to explicitly specify evaluation order.

---

# Examples of Combined Use

```sql
SELECT first_name, last_name, salary
FROM employees
WHERE (department = 'Sales' OR department = 'Marketing')
  AND salary BETWEEN 3000 AND 7000
  AND email IS NOT NULL
ORDER BY salary DESC;
```

---

# Summary Table

| Operator Type    | Operators                            | Use Case                    |                         |                 |
| ---------------- | ------------------------------------ | --------------------------- | ----------------------- | --------------- |
| Arithmetic       | `+`, `-`, `*`, `/`, `%`              | Math calculations           |                         |                 |
| Comparison       | `=`, `<>`/`!=`, `<`, `>`, `<=`, `>=` | Value comparison            |                         |                 |
| Logical          | `AND`, `OR`, `NOT`                   | Combine Boolean expressions |                         |                 |
| Bitwise          | `&`, \`                              | `, `^`, `\~`, `<<`, `>>\`   | Bit-level operations    |                 |
| String           | \`                                   |                             | `, `+\` (concatenation) | Combine strings |
| Set              | `IN`, `NOT IN`                       | Membership tests            |                         |                 |
| Null-related     | `IS NULL`, `IS NOT NULL`             | Null checks                 |                         |                 |
| Pattern Matching | `LIKE`, `NOT LIKE`                   | Text pattern matching       |                         |                 |
| Others           | `BETWEEN`, `EXISTS`, `ANY`, `ALL`    | Range, subquery checks      |                         |                 |
