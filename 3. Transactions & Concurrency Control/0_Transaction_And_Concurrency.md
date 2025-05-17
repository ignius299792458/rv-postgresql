# PostgreSQL Transactions & Concurrency Control in Banking DB

## ACID Compliance in PostgreSQL

PostgreSQL is fully ACID compliant, meaning it guarantees:

- **Atomicity**: Transactions are all-or-nothing
- **Consistency**: Database remains in a valid state
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed transactions survive crashes

### Why ACID Matters in Banking

In financial systems, ACID properties are critical:

- Money transfers must complete entirely or not at all
- Account balances must always be accurate
- Concurrent transfers must not corrupt data
- Transactions must survive system failures

## Transaction Basics

### Simple Transaction Example

```sql
BEGIN;
-- Transfer $100 from account A to B
UPDATE bank_accounts SET balance = balance - 100 WHERE account_id = 'a1b2c3d4';
UPDATE bank_accounts SET balance = balance + 100 WHERE account_id = 'e5f6g7h8';
INSERT INTO transactions (account_id, transaction_type, amount, status)
VALUES ('a1b2c3d4', 'Transfer', -100, 'Completed'),
       ('e5f6g7h8', 'Transfer', 100, 'Completed');
COMMIT;
```

If any operation fails, the entire transaction rolls back, preserving data integrity.

## Concurrency Control Mechanisms

PostgreSQL uses Multi-Version Concurrency Control (MVCC) to handle concurrent transactions.

### 1. Isolation Levels

PostgreSQL supports four isolation levels with different behavior:

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Default
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Same as READ COMMITTED in PG
```

#### Banking Example: Account Balance Check

```sql
-- Session 1
BEGIN;
SELECT balance FROM bank_accounts WHERE account_id = 'a1b2c3d4'; -- Returns 1000

-- Session 2 (concurrently)
BEGIN;
UPDATE bank_accounts SET balance = balance - 200 WHERE account_id = 'a1b2c3d4';
COMMIT;

-- In READ COMMITTED (default):
SELECT balance FROM bank_accounts WHERE account_id = 'a1b2c3d4'; -- Now returns 800

-- In REPEATABLE READ:
SELECT balance FROM bank_accounts WHERE account_id = 'a1b2c3d4'; -- Still returns 1000
```

### 2. Locking Mechanisms

PostgreSQL provides various locks for concurrency control:

#### Row-Level Locks

```sql
BEGIN;
SELECT * FROM bank_accounts WHERE account_id = 'a1b2c3d4' FOR UPDATE;
-- Now this row is locked for updates by other transactions
UPDATE bank_accounts SET balance = balance - 100 WHERE account_id = 'a1b2c3d4';
COMMIT;
```

#### Advisory Locks

```sql
BEGIN;
SELECT pg_advisory_xact_lock(123); -- Application-defined lock ID
-- Perform critical operations
COMMIT; -- Lock automatically released
```

### 3. Deadlock Handling

PostgreSQL automatically detects and resolves deadlocks by aborting one of the transactions.

```sql
-- Session 1
BEGIN;
UPDATE bank_accounts SET balance = balance - 100 WHERE account_id = 'a1b2c3d4';
-- Holds lock on account a1b2c3d4

-- Session 2
BEGIN;
UPDATE bank_accounts SET balance = balance - 200 WHERE account_id = 'e5f6g7h8';
-- Holds lock on account e5f6g7h8

-- Session 1 then tries to update e5f6g7h8 (waits for Session 2's lock)
UPDATE bank_accounts SET balance = balance + 100 WHERE account_id = 'e5f6g7h8';

-- Session 2 then tries to update a1b2c3d4 (waits for Session 1's lock)
UPDATE bank_accounts SET balance = balance + 200 WHERE account_id = 'a1b2c3d4';

-- PostgreSQL detects deadlock and aborts one transaction
```

## Advanced Banking Transaction Example

Here's a complete funds transfer transaction with proper error handling:

```sql
DO $$
DECLARE
    from_acct UUID := 'a1b2c3d4';
    to_acct UUID := 'e5f6g7h8';
    transfer_amount NUMERIC := 100.00;
    from_balance NUMERIC;
    to_balance NUMERIC;
    min_balance NUMERIC := 0.00; -- Assuming no overdraft allowed
    transfer_id UUID;
BEGIN
    -- Start transaction
    BEGIN
        -- Get and lock both accounts
        SELECT balance INTO from_balance
        FROM bank_accounts
        WHERE account_id = from_acct
        FOR UPDATE;

        SELECT balance INTO to_balance
        FROM bank_accounts
        WHERE account_id = to_acct
        FOR UPDATE;

        -- Validate funds
        IF from_balance - transfer_amount < min_balance THEN
            RAISE EXCEPTION 'Insufficient funds in source account';
        END IF;

        -- Perform transfer
        UPDATE bank_accounts
        SET balance = balance - transfer_amount
        WHERE account_id = from_acct;

        UPDATE bank_accounts
        SET balance = balance + transfer_amount
        WHERE account_id = to_acct;

        -- Record transactions
        INSERT INTO transactions (account_id, transaction_type, amount, status)
        VALUES (from_acct, 'Transfer', -transfer_amount, 'Completed'),
               (to_acct, 'Transfer', transfer_amount, 'Completed');

        -- Record fund transfer
        INSERT INTO fund_transfers (
            from_account, to_account, amount, status,
            initiated_at, completed_at, transfer_mode
        ) VALUES (
            from_acct, to_acct, transfer_amount, 'Completed',
            now(), now(), 'Online'
        ) RETURNING transfer_id INTO transfer_id;

        -- Log success
        RAISE NOTICE 'Transfer % completed successfully', transfer_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Transfer failed: %', SQLERRM;
    END;
END $$;
```

## Optimizing for High Concurrency

### 1. Indexing Strategy

Your schema already includes good GIN indexes for JSONB/HSTORE fields. Additional indexes that would help:

```sql
-- For frequent balance checks
CREATE INDEX idx_bank_accounts_balance ON bank_accounts(balance)
WHERE status = 'Active';

-- For transaction history lookups
CREATE INDEX idx_transactions_account_date ON transactions(account_id, created_at);

-- For fund transfer status checks
CREATE INDEX idx_fund_transfers_status ON fund_transfers(status, initiated_at);
```

### 2. Transaction Design Best Practices

1. **Keep transactions short** - Minimize lock duration
2. **Access tables in consistent order** - Prevent deadlocks
3. **Use appropriate isolation levels** - Default (READ COMMITTED) is usually sufficient
4. **Handle errors gracefully** - Use savepoints for complex operations

### 3. Savepoints for Complex Operations

```sql
BEGIN;
-- Initial operations
SAVEPOINT step1;

-- Try processing payment
BEGIN
    -- Payment processing logic
    -- If error occurs:
    ROLLBACK TO SAVEPOINT step1;
    -- Alternative processing
END;

-- Continue with other operations
COMMIT;
```

## Monitoring and Troubleshooting

### Checking for Locks

```sql
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.usename AS blocked_user,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;
```

### Transaction Performance Metrics

```sql
SELECT
    pid,
    now() - xact_start AS duration,
    query
FROM pg_stat_activity
WHERE state = 'active' AND xact_start IS NOT NULL
ORDER BY duration DESC;
```

## Conclusion

PostgreSQL's transaction and concurrency control features provide the robustness needed for banking applications. By understanding isolation levels, locking mechanisms, and proper transaction design, you can build systems that handle high concurrency while maintaining data integrity. The examples provided demonstrate how to implement secure financial transactions in your banking database schema.

Remember to:

1. Always use transactions for financial operations
2. Choose appropriate isolation levels
3. Implement proper error handling
4. Monitor for long-running transactions and locks
5. Optimize with proper indexing
