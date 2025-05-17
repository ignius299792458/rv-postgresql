# **Functions in SQL**

## What Are SQL Functions?

**Functions** in SQL are predefined or user-defined routines that accept zero or more input parameters and return a single value or a table (in some cases). Functions are used to perform operations on data — calculations, transformations, aggregations, and more.

---

### Types of SQL Functions

1. **Built-in (System) Functions**
2. **User-Defined Functions (UDFs)**

---

# 1. Built-in SQL Functions

These are functions provided by the SQL database engine by default.

### Categories of Built-in Functions

- **Scalar Functions** (return single value per row)
- **Aggregate Functions** (operate on sets/groups, return single value per group)
- **Window Functions** (operate on a set of rows related to the current row)
- **String Functions**
- **Numeric Functions**
- **Date & Time Functions**
- **Conversion Functions**
- **System Information Functions**

---

### 1.1 Scalar Functions

Operate on each row and return one value per row.

#### Examples:

- `UPPER(string)`: Converts string to uppercase.
- `LOWER(string)`: Converts string to lowercase.
- `LEN(string)` or `LENGTH(string)`: Returns length of string.
- `ROUND(number, decimals)`: Rounds a number.
- `ABS(number)`: Absolute value.
- `SQRT(number)`: Square root.
- `GETDATE()` or `CURRENT_TIMESTAMP`: Returns current system date/time.

---

### 1.2 Aggregate Functions

Operate on a group/set of rows and return a single value.

| Function                                                         | Description                            |
| ---------------------------------------------------------------- | -------------------------------------- |
| `COUNT(*)`                                                       | Count rows (including NULLs in column) |
| `SUM(col)`                                                       | Sum values in a column                 |
| `AVG(col)`                                                       | Average value of a column              |
| `MIN(col)`                                                       | Minimum value                          |
| `MAX(col)`                                                       | Maximum value                          |
| `GROUP_CONCAT(col)` (MySQL) or `STRING_AGG(col, sep)` (Postgres) | Concatenate strings                    |

---

### 1.3 Window Functions (Analytic Functions)

Operate over a "window" of rows around the current row, preserving detail rows.

Example: Ranking, running totals, moving averages.

| Function          | Description                                   |
| ----------------- | --------------------------------------------- |
| `ROW_NUMBER()`    | Assigns a sequential row number per partition |
| `RANK()`          | Assigns rank with gaps for ties               |
| `DENSE_RANK()`    | Assigns rank without gaps                     |
| `LEAD()`          | Access next row value                         |
| `LAG()`           | Access previous row value                     |
| `SUM() OVER(...)` | Running total                                 |

---

### 1.4 String Functions (examples from PostgreSQL/MySQL/SQL Server)

| Function                        | Description             | Example                                |
| ------------------------------- | ----------------------- | -------------------------------------- |
| `CONCAT(str1, str2)`            | Concatenates strings    | `CONCAT('Hi', ' there') → 'Hi there'`  |
| `SUBSTRING(str, start, length)` | Extract substring       | `SUBSTRING('abcdef', 2, 3) → 'bcd'`    |
| `TRIM()`, `LTRIM()`, `RTRIM()`  | Remove whitespace       | `TRIM('  hello  ') → 'hello'`          |
| `REPLACE(str, from, to)`        | Replace substring       | `REPLACE('apple', 'p', 'b') → 'abble'` |
| `LEFT(str, n)`, `RIGHT(str, n)` | First/last n characters | `LEFT('abcdef', 3) → 'abc'`            |

---

### 1.5 Numeric Functions

| Function               | Description              | Example                     |
| ---------------------- | ------------------------ | --------------------------- |
| `ROUND(num, decimals)` | Round number to decimals | `ROUND(12.3456, 2) → 12.35` |
| `FLOOR(num)`           | Largest integer <= num   | `FLOOR(3.9) → 3`            |
| `CEILING(num)`         | Smallest integer >= num  | `CEILING(3.1) → 4`          |
| `ABS(num)`             | Absolute value           | `ABS(-10) → 10`             |
| `POWER(base, exp)`     | Exponentiation           | `POWER(2, 3) → 8`           |

---

### 1.6 Date and Time Functions

| Function                           | Description                 | Example                                         |
| ---------------------------------- | --------------------------- | ----------------------------------------------- |
| `CURRENT_DATE`                     | Returns current date        | `2025-05-18`                                    |
| `CURRENT_TIME`                     | Returns current time        | `14:30:15`                                      |
| `DATEADD(interval, number, date)`  | Add interval to date        | `DATEADD(day, 3, '2025-05-18') → 2025-05-21`    |
| `DATEDIFF(interval, date1, date2)` | Difference between dates    | `DATEDIFF(day, '2025-05-18', '2025-05-21') → 3` |
| `EXTRACT(field FROM date)`         | Extract part from date/time | `EXTRACT(year FROM '2025-05-18') → 2025`        |

---

### 1.7 Conversion Functions

Convert data from one type to another.

| Function                | Description                  | Example                               |
| ----------------------- | ---------------------------- | ------------------------------------- |
| `CAST(expr AS type)`    | Cast expression to data type | `CAST('123' AS INT) → 123`            |
| `CONVERT(type, expr)`   | Similar to CAST in some DBs  | `CONVERT(INT, '123')`                 |
| `TO_CHAR(date, format)` | Format date to string        | `TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD')` |

---

### 1.8 System Information Functions

Examples:

- `USER()`, `CURRENT_USER`: Return current database user.
- `VERSION()`: Return database version.
- `DATABASE()`: Current database name.

---

# 2. User-Defined Functions (UDFs)

Functions created by users for reusable custom logic.

### Types of UDFs

- **Scalar Functions:** Return single scalar value
- **Table-Valued Functions:** Return a table (set of rows)

---

### 2.1 Syntax Examples

#### SQL Server Scalar Function Example

```sql
CREATE FUNCTION dbo.GetFullName(@FirstName VARCHAR(50), @LastName VARCHAR(50))
RETURNS VARCHAR(101)
AS
BEGIN
    RETURN @FirstName + ' ' + @LastName;
END
```

Usage:

```sql
SELECT dbo.GetFullName('John', 'Doe') AS FullName;
```

---

#### PostgreSQL Function Example

```sql
CREATE OR REPLACE FUNCTION add_numbers(a INT, b INT)
RETURNS INT AS $$
BEGIN
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```

Usage:

```sql
SELECT add_numbers(10, 5);
```

---

### 2.2 Benefits of UDFs

- Encapsulate complex logic.
- Reuse code.
- Improve maintainability.
- Enhance readability of SQL queries.

---

### 2.3 Limitations & Considerations

- UDFs can sometimes degrade performance if not carefully used (especially scalar UDFs in SQL Server).
- Often non-inline functions prevent query optimization.
- Some DBs restrict side-effects inside functions.

---

# 3. Functions Usage in SQL Queries

Functions are used in:

- `SELECT` clauses
- `WHERE` clauses
- `GROUP BY` clauses
- `HAVING` clauses
- `ORDER BY` clauses
- Within joins or subqueries

---

### Examples:

**Using Scalar Functions:**

```sql
SELECT UPPER(name), LENGTH(name) FROM employees;
```

**Using Aggregate Functions:**

```sql
SELECT department, COUNT(*) AS num_employees, AVG(salary) AS avg_salary
FROM employees
GROUP BY department;
```

**Using Window Functions:**

```sql
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```

---

# 4. Advanced Topics About SQL Functions

---

### 4.1 Deterministic vs Non-Deterministic Functions

- **Deterministic:** Returns same output for same input every time.
- **Non-deterministic:** Output can vary (e.g., `GETDATE()`).

This distinction matters for optimization and indexing.

---

### 4.2 Collations and String Functions

String functions may behave differently depending on the database's collation settings (case sensitivity, accent sensitivity).

---

### 4.3 NULL Handling in Functions

- Most functions return `NULL` if input is `NULL`.
- Some functions have special handling (`COALESCE`, `IFNULL`, `NVL`).

Example:

```sql
SELECT COALESCE(NULL, 'default'); -- returns 'default'
```

---

### 4.4 Recursive Functions

Some SQL dialects (e.g., PostgreSQL) allow recursive functions for tasks like hierarchical queries.

---

### 4.5 Performance Considerations

- Minimize use of scalar UDFs inside large queries.
- Use set-based operations and window functions for better performance.
- Avoid unnecessary conversions inside functions.
- Use indexes wisely with functions (some DBs allow function-based indexes).

---

# 5. Examples & Practice

---

### Example: Aggregate & Scalar Functions

```sql
SELECT department,
       COUNT(*) AS total_employees,
       AVG(salary) AS avg_salary,
       MAX(hire_date) AS latest_hire
FROM employees
GROUP BY department
HAVING COUNT(*) > 5
ORDER BY avg_salary DESC;
```

---

### Example: String Functions

```sql
SELECT
    first_name,
    last_name,
    CONCAT(UPPER(LEFT(first_name, 1)), LOWER(SUBSTRING(first_name, 2))) AS ProperFirstName
FROM employees;
```

---

### Example: Date Functions

```sql
SELECT
    employee_id,
    hire_date,
    CURRENT_DATE - hire_date AS days_employed,
    DATEADD(year, 1, hire_date) AS one_year_anniversary
FROM employees;
```

---

### Example: Window Functions

```sql
SELECT
    employee_id,
    department,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_salary_rank
FROM employees;
```

---

# Summary

| Function Type          | Returns                                  | Usage Scenario                                   |
| ---------------------- | ---------------------------------------- | ------------------------------------------------ |
| Scalar Functions       | Single value per row                     | Format string, calculate value, manipulate dates |
| Aggregate Functions    | Single value per group                   | Count, sum, average over groups                  |
| Window Functions       | Value per row but computed over a window | Running totals, ranks per group                  |
| User Defined Functions | Single value or table                    | Custom reusable business logic                   |
