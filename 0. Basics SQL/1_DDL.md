# Data Definition Language (DDL)

the part of SQL responsible for **defining and managing database structures**.

---

## 🧠 What is DDL?

**DDL (Data Definition Language)** consists of SQL commands used to **define, modify, and remove database schema objects**, such as:

- Tables
- Views
- Indexes
- Schemas
- Users/Roles
- Constraints

> ❗ DDL commands **auto-commit** — changes are immediately permanent.

---

## ⚙️ 1. `CREATE` Statement

### a. `CREATE TABLE`

Defines a new table with column names, data types, and constraints.

```sql
CREATE TABLE accounts (
    account_id     SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL,
    balance        NUMERIC(12, 2) DEFAULT 0.00,
    status         VARCHAR(20) CHECK (status IN ('active', 'frozen', 'closed')),
    created_at     TIMESTAMP DEFAULT NOW()
);
```

**Notes:**

- `SERIAL`: Auto-incrementing integer (PostgreSQL-specific).
- `PRIMARY KEY`: Uniquely identifies a row.
- `CHECK`: Adds validation rule.
- `DEFAULT`: Provides default value.

### b. `CREATE SCHEMA`

Organizes objects under a namespace.

```sql
CREATE SCHEMA bank_data AUTHORIZATION postgres;
```

### c. `CREATE INDEX`

Improves performance of `SELECT` queries.

```sql
CREATE INDEX idx_customer_id ON accounts(customer_id);
```

### d. `CREATE VIEW`

Virtual table (query result that acts like a table).

```sql
CREATE VIEW active_accounts AS
SELECT * FROM accounts WHERE status = 'active';
```

### e. `CREATE TYPE` (for enums or composites)

```sql
CREATE TYPE account_status AS ENUM ('active', 'frozen', 'closed');
```

---

## ✏️ 2. `ALTER` Statement

Used to modify existing database objects.

### a. Altering Tables

```sql
-- Add a column
ALTER TABLE accounts ADD COLUMN currency_code CHAR(3) DEFAULT 'USD';

-- Modify column type
ALTER TABLE accounts ALTER COLUMN balance TYPE FLOAT;

-- Rename column
ALTER TABLE accounts RENAME COLUMN currency_code TO currency;

-- Drop column
ALTER TABLE accounts DROP COLUMN currency;
```

### b. Add or Drop Constraints

```sql
-- Add a foreign key
ALTER TABLE accounts
ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

-- Drop a constraint
ALTER TABLE accounts DROP CONSTRAINT fk_customer;
```

---

## 💣 3. `DROP` Statement

Removes database objects **permanently**.

### a. `DROP TABLE`

```sql
DROP TABLE IF EXISTS accounts CASCADE;
```

- `IF EXISTS`: Avoids error if table doesn't exist.
- `CASCADE`: Drops dependent objects (e.g., views, foreign keys).

### b. `DROP VIEW`, `DROP INDEX`, etc.

```sql
DROP VIEW active_accounts;
DROP INDEX idx_customer_id;
DROP SCHEMA bank_data CASCADE;
```

---

## 🧽 4. `TRUNCATE` Statement

Removes **all data** from a table, but **keeps the structure**.

```sql
TRUNCATE TABLE accounts RESTART IDENTITY CASCADE;
```

- `RESTART IDENTITY`: Resets `SERIAL` values.
- `CASCADE`: Truncates dependent tables.

---

## 🔐 5. DDL Constraints

### Common Constraint Types

| Constraint    | Description                                    |
| ------------- | ---------------------------------------------- |
| `PRIMARY KEY` | Unique, non-null identifier                    |
| `FOREIGN KEY` | Links to another table                         |
| `UNIQUE`      | All values must be unique                      |
| `NOT NULL`    | Prohibits `NULL` values                        |
| `CHECK`       | Validates against condition (e.g., salary > 0) |
| `DEFAULT`     | Supplies a default value if none is given      |

```sql
CREATE TABLE employees (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT UNIQUE,
    salary     NUMERIC CHECK (salary >= 0)
);
```

---

## 💬 DDL Advanced Topics

### a. Partitioned Tables (PostgreSQL)

```sql
CREATE TABLE transactions (
    id SERIAL,
    account_id INT,
    txn_date DATE,
    amount NUMERIC
) PARTITION BY RANGE (txn_date);
```

### b. Tablespaces

Specifies the physical location of table data.

```sql
CREATE TABLESPACE fastspace LOCATION '/ssd1/db';
CREATE TABLE large_data (...) TABLESPACE fastspace;
```

### c. Generated Columns

```sql
CREATE TABLE items (
    price NUMERIC,
    quantity INT,
    total_cost NUMERIC GENERATED ALWAYS AS (price * quantity) STORED
);
```

---

## 🧪 Best Practices

- Always use `IF EXISTS` or `IF NOT EXISTS` to avoid errors in DDL.
- Use `CASCADE` carefully — it can delete dependent data.
- Always version-control your DDL scripts.
- Prefer constraints over app logic for data integrity.
- Create indexes after loading large datasets (for performance).

---

## 📚 Summary: DDL Keywords

| Keyword    | Purpose                               |
| ---------- | ------------------------------------- |
| `CREATE`   | Create tables, schemas, indexes, etc. |
| `ALTER`    | Modify schema objects                 |
| `DROP`     | Delete schema objects                 |
| `TRUNCATE` | Remove data, keep structure           |

---

DDL generation and migrations using tools like `Flyway`, `Liquibase`, or `TypeORM/Prisma`?
