# **TCL (Transaction Control Language)**

## ✅ What is TCL?

**TCL (Transaction Control Language)** is a subset of SQL that is used to **manage transactions** in a database. Transactions are sequences of one or more SQL operations executed as a **single logical unit of work**.

### 🔑 Key Properties of a Transaction (ACID):

1. **Atomicity** – All operations succeed or none do.
2. **Consistency** – Data moves from one valid state to another.
3. **Isolation** – Transactions don't interfere with each other.
4. **Durability** – Once committed, changes are permanent.

---

## 🧱 TCL Commands

| Command                       | Description                                                    |
| ----------------------------- | -------------------------------------------------------------- |
| `BEGIN` / `START TRANSACTION` | Starts a new transaction                                       |
| `COMMIT`                      | Saves changes                                                  |
| `ROLLBACK`                    | Undoes changes                                                 |
| `SAVEPOINT`                   | Marks a point in a transaction                                 |
| `RELEASE SAVEPOINT`           | Deletes a savepoint                                            |
| `ROLLBACK TO SAVEPOINT`       | Reverts to a specific savepoint                                |
| `SET TRANSACTION`             | Configures transaction characteristics (e.g., isolation level) |

---

## 🔍 1. `BEGIN` or `START TRANSACTION`

### Syntax:

```sql
BEGIN;
-- or
START TRANSACTION;
```

This marks the **start** of a transaction block.

> ✅ **Note**: In PostgreSQL and most SQL-compliant DBMS, each command is auto-committed unless you begin an explicit transaction.

---

## 🔍 2. `COMMIT`

### Syntax:

```sql
COMMIT;
```

Commits the transaction—**makes all changes permanent**.

### Example:

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;
```

> ⚠️ Once committed, the changes **cannot be undone** unless you have enabled **PITR (Point-In-Time Recovery)**.

---

## 🔍 3. `ROLLBACK`

### Syntax:

```sql
ROLLBACK;
```

Reverts all operations back to the state before `BEGIN`.

### Example:

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
-- Error happens here
ROLLBACK;
```

> 💡 Use in error handling or when validations fail.

---

## 🔍 4. `SAVEPOINT`

### Syntax:

```sql
SAVEPOINT savepoint_name;
```

Marks a **named point** within a transaction to which you can **roll back** later without affecting all previous operations.

### Example:

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
SAVEPOINT deduct_done;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
-- Error occurs
ROLLBACK TO deduct_done;
-- Continue from deduct_done
COMMIT;
```

---

## 🔍 5. `ROLLBACK TO SAVEPOINT`

### Syntax:

```sql
ROLLBACK TO SAVEPOINT savepoint_name;
```

Rolls back only part of the transaction **up to the specified savepoint**.

---

## 🔍 6. `RELEASE SAVEPOINT`

### Syntax:

```sql
RELEASE SAVEPOINT savepoint_name;
```

Removes the named savepoint. After release, rollback to it is not possible.

> ⚠️ Not necessary in PostgreSQL, but good practice in highly concurrent or nested transactions.

---

## 🔍 7. `SET TRANSACTION`

### Syntax:

```sql
SET TRANSACTION [READ WRITE | READ ONLY] [ISOLATION LEVEL level];
```

Sets **transaction isolation level** and access mode.

### Supported Isolation Levels:

| Level              | Description                                                 |
| ------------------ | ----------------------------------------------------------- |
| `READ UNCOMMITTED` | Dirty reads allowed (Not supported in PostgreSQL)           |
| `READ COMMITTED`   | Default in PostgreSQL – Only committed data is visible      |
| `REPEATABLE READ`  | Same data throughout the transaction, phantom reads allowed |
| `SERIALIZABLE`     | Strictest – Full isolation                                  |

### Example:

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
-- Do more
COMMIT;
```

---

## 🔐 Real-World Use Case (Banking Transaction):

### Problem: Transferring \$100 from A to B ensuring atomicity

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE accounts
SET balance = balance - 100
WHERE account_id = 'A';

-- Business validation
DO $$
BEGIN
  IF (SELECT balance FROM accounts WHERE account_id = 'A') < 0 THEN
    RAISE EXCEPTION 'Insufficient funds';
  END IF;
END$$;

UPDATE accounts
SET balance = balance + 100
WHERE account_id = 'B';

COMMIT;
```

If **any part fails**, the entire transaction is **rolled back**.

---

## 💡 PostgreSQL Notes

- By default, PostgreSQL operates in **autocommit** mode.
- You must use `BEGIN` or `START TRANSACTION` for manual control.
- Nested transactions are handled via **savepoints**, since true nested transactions are not supported.
- PostgreSQL uses **MVCC (Multi-Version Concurrency Control)** to allow high concurrency while keeping transactions isolated.

---

## 🧠 Best Practices

1. **Keep transactions short** – Avoid holding locks too long.
2. **Check constraints and validations before COMMIT**.
3. **Use savepoints** in large transactions.
4. **Always handle rollback scenarios** programmatically.
5. **Log transactions**, especially in fintech/banking.

---

## 🛠️ Tools for Observing Transactions

- **pg_stat_activity** – Monitor active transactions.
- **pg_locks** – View lock information per transaction.
- **pg_stat_user_tables** – Analyze transactional impacts on tables.
- **pg_stat_statements** – Audit long-running transactions.

---

## 📚 Summary Table

| TCL Command                   | Purpose                                  |
| ----------------------------- | ---------------------------------------- |
| `BEGIN` / `START TRANSACTION` | Begin a transaction block                |
| `COMMIT`                      | Commit changes                           |
| `ROLLBACK`                    | Undo changes                             |
| `SAVEPOINT`                   | Set point in transaction to roll back to |
| `ROLLBACK TO`                 | Undo to a specific savepoint             |
| `RELEASE SAVEPOINT`           | Remove a savepoint                       |
| `SET TRANSACTION`             | Define isolation and access              |
