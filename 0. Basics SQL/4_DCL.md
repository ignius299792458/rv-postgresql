# **DCL (Data Control Language)** of SQL

## 🔷 What is DCL?

**DCL (Data Control Language)** is a subset of SQL used to **control access to data in a database system**, managing _permissions_, _rights_, and _security_. It is essential for maintaining data integrity, privacy, and compliance in multi-user environments.

> 🔐 DCL governs **who can do what** on **which database objects**.

---

## 🔷 Core DCL Commands

| Command  | Purpose                       |
| -------- | ----------------------------- |
| `GRANT`  | Gives privileges to users     |
| `REVOKE` | Removes privileges from users |

---

# 1️⃣ `GRANT` – Giving Access

### ✅ Syntax:

```sql
GRANT privilege_type [(column_list)]
ON object_type object_name
TO user_or_role
[WITH GRANT OPTION];
```

### 🔍 Parameters:

- `privilege_type`: Type of access like `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `ALL PRIVILEGES`, etc.
- `object_type`: `TABLE`, `SEQUENCE`, `DATABASE`, `SCHEMA`, etc.
- `WITH GRANT OPTION`: Allows the user to **grant the same privileges** to others.

### 📘 Example:

```sql
-- Grant SELECT on employees table to user john
GRANT SELECT ON employees TO john;

-- Grant INSERT and UPDATE on specific columns
GRANT UPDATE (salary, position) ON employees TO payroll_admin;

-- Grant all privileges with GRANT OPTION
GRANT ALL PRIVILEGES ON employees TO hr_manager WITH GRANT OPTION;
```

### 💡 Pro Tip:

Use **roles** (groups of privileges) rather than assigning permissions to each user individually.

---

# 2️⃣ `REVOKE` – Removing Access

### ✅ Syntax:

```sql
REVOKE privilege_type [(column_list)]
ON object_type object_name
FROM user_or_role
[CASCADE | RESTRICT];
```

### 🔍 Options:

- `CASCADE`: Revokes the privileges from users who got them **indirectly** via `GRANT OPTION`.
- `RESTRICT`: Refuses to revoke if others depend on the privileges.

### 📘 Example:

```sql
-- Revoke SELECT from user john
REVOKE SELECT ON employees FROM john;

-- Revoke UPDATE on specific columns
REVOKE UPDATE (salary) ON employees FROM payroll_admin;

-- Revoke all privileges
REVOKE ALL PRIVILEGES ON employees FROM hr_manager CASCADE;
```

---

## 🔸 Privilege Types in PostgreSQL (and most RDBMS)

| Privilege    | Applies To       | Description                                             |
| ------------ | ---------------- | ------------------------------------------------------- |
| `SELECT`     | TABLE, VIEW      | Read data                                               |
| `INSERT`     | TABLE            | Add new rows                                            |
| `UPDATE`     | TABLE            | Modify existing rows                                    |
| `DELETE`     | TABLE            | Delete rows                                             |
| `TRUNCATE`   | TABLE            | Remove all rows                                         |
| `REFERENCES` | TABLE            | Create foreign keys                                     |
| `TRIGGER`    | TABLE            | Create triggers                                         |
| `USAGE`      | SCHEMA, SEQUENCE | Access objects in schema / read nextval() from sequence |
| `EXECUTE`    | FUNCTIONS        | Call a stored procedure or function                     |
| `CREATE`     | DATABASE, SCHEMA | Create objects inside                                   |
| `CONNECT`    | DATABASE         | Connect to the DB                                       |
| `TEMPORARY`  | DATABASE         | Create temporary tables                                 |

---

## 3️⃣ PostgreSQL Role System and DCL

In **PostgreSQL**, everything related to users, groups, and access is managed using **roles**.

### ✅ Create Role:

```sql
CREATE ROLE read_only_user WITH LOGIN PASSWORD 'strong_pass';
```

### ✅ Grant Role:

```sql
-- Create a role with SELECT-only rights
CREATE ROLE read_access;

-- Grant SELECT on a table to that role
GRANT SELECT ON employees TO read_access;

-- Grant role to user
GRANT read_access TO read_only_user;
```

### ✅ Check Privileges:

```sql
-- Show all grants
\z tablename       -- (psql)
```

Or use the `information_schema` views:

```sql
SELECT * FROM information_schema.role_table_grants WHERE grantee = 'john';
```

---

## 4️⃣ Granting Privileges on Database-Wide and Schema-Wide Level

### ✅ Database Level:

```sql
GRANT CONNECT ON DATABASE company_db TO hr_team;
GRANT TEMPORARY ON DATABASE company_db TO temp_user;
```

### ✅ Schema Level:

```sql
GRANT USAGE ON SCHEMA public TO analyst;
GRANT CREATE ON SCHEMA public TO developer;
```

---

## 5️⃣ Column-Level Permissions

You can grant `SELECT`, `UPDATE`, or `REFERENCES` on specific columns:

```sql
GRANT SELECT (name, department) ON employees TO hr_analyst;
GRANT UPDATE (salary) ON employees TO payroll_team;
```

---

## 6️⃣ Function and Procedure Permissions

```sql
-- Grant EXECUTE on a function
GRANT EXECUTE ON FUNCTION calculate_salary(int) TO hr_team;
```

---

## 7️⃣ Best Practices

### 🔐 Security and Compliance:

- Never use `GRANT ALL` in production for regular users.
- Use **roles** to abstract privilege sets.
- Rotate passwords and review access periodically.
- Use **`WITH GRANT OPTION`** very carefully.
- Follow **principle of least privilege**.

### 📁 Use Group Roles:

```sql
CREATE ROLE admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT admin_role TO john, jane;
```

### 🔄 Automate Privilege Management:

Use tools like:

- **Liquibase** or **Flyway** to track DCL changes.
- **Ansible** / **Terraform** with PostgreSQL modules.
- SQL scripts version-controlled with Git.

---

## 8️⃣ Viewing DCL Metadata

Use PostgreSQL views for deep inspection:

- `pg_roles`: List of all roles
- `pg_user`: All users (roles with login)
- `information_schema.role_table_grants`
- `pg_auth_members`: Role memberships

Example:

```sql
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'employees';
```

---

## 9️⃣ Revoking Public Access

By default, many DBMS grant access to the `PUBLIC` role (all users):

```sql
-- Revoke public access
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
```

---

## 🔟 Audit and Trace Permissions

PostgreSQL Extensions:

- `pgaudit`: Logs DCL changes and access
- `pg_stat_activity`: Monitor live sessions
- `log_statement = 'ddl'` or `'all'` in `postgresql.conf` to log permission changes

---

## 🧪 Real-World DCL Scenario (Banking App)

Let’s say you’re designing a banking database.

### Roles:

- `teller_role` → `SELECT`, `INSERT` on `transactions`
- `auditor_role` → `SELECT` on all tables
- `admin_role` → all privileges

```sql
CREATE ROLE teller_role;
CREATE ROLE auditor_role;
CREATE ROLE admin_role;

GRANT SELECT, INSERT ON transactions TO teller_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;

-- Assign users to roles
GRANT teller_role TO user_teller;
GRANT auditor_role TO user_auditor;
GRANT admin_role TO user_admin;
```

---

# 📚 Summary – SQL DCL

| Feature                      | Purpose                 |
| ---------------------------- | ----------------------- |
| `GRANT`                      | Give access rights      |
| `REVOKE`                     | Take away access        |
| `WITH GRANT OPTION`          | Allow re-granting       |
| Roles                        | Manage group privileges |
| Column-level permissions     | Fine-grained control    |
| Schema/database-level grants | Broad permissions       |
| Auditing                     | Track changes and usage |
| Revoking PUBLIC              | Increase security       |

---
