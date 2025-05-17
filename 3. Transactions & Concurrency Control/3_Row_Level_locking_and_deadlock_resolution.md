# Row-Level Locking & Deadlock Resolution in PostgreSQL

## Introduction

Row-level locking is a critical mechanism in PostgreSQL that manages how concurrent transactions interact with the same data. In a banking environment, where data integrity is paramount, understanding row-level locking is essential to ensure consistent and reliable operations.

This guide explores the intricacies of row-level locking in PostgreSQL with practical examples using the banking database schema.

## 1. Understanding Row-Level Locking

### 1.1 Lock Modes in PostgreSQL

PostgreSQL supports various lock modes, each with different levels of restrictiveness:

| Lock Mode | Description | Conflicts With |
|-----------|-------------|---------------|
| ACCESS SHARE | Read-only operations | ACCESS EXCLUSIVE |
| ROW SHARE | SELECT FOR UPDATE/SHARE | EXCLUSIVE, ACCESS EXCLUSIVE |
| ROW EXCLUSIVE | UPDATE, DELETE, INSERT | SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| SHARE UPDATE EXCLUSIVE | VACUUM, CREATE INDEX CONCURRENTLY | SHARE UPDATE EXCLUSIVE, SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| SHARE | CREATE INDEX | ROW EXCLUSIVE, SHARE UPDATE EXCLUSIVE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| SHARE ROW EXCLUSIVE | Rarely used directly | ROW EXCLUSIVE, SHARE UPDATE EXCLUSIVE, SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| EXCLUSIVE | Blocks most writes | ROW SHARE, ROW EXCLUSIVE, SHARE UPDATE EXCLUSIVE, SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| ACCESS EXCLUSIVE | Blocks all access | ALL |

### 1.2 Implicit vs. Explicit Locking

PostgreSQL employs two locking approaches:

- **Implicit locking**: Automatically applied by PostgreSQL during DML operations (INSERT, UPDATE, DELETE)
- **Explicit locking**: Manually specified using locking clauses like `FOR UPDATE`, `FOR SHARE`

## 2. Row-Level Locking in Banking Applications

### 2.1 Account Balance Updates

When updating account balances, row-level locking ensures that concurrent transactions don't interfere with each other:

```sql
-- Transaction 1: Transfer $100 from Account A to Account B
BEGIN;
-- Lock and update source account
UPDATE bank_accounts 
SET balance = balance - 100.00
WHERE account_id = 'source_account_uuid'
  AND balance >= 100.00
RETURNING balance;  -- Verify sufficient funds

-- If returned row exists, funds are sufficient and row is locked
-- Lock and update destination account
UPDATE bank_accounts 
SET balance = balance + 100.00
WHERE account_id = 'destination_account_uuid';

-- Record the transaction
INSERT INTO transactions (account_id, transaction_type, amount, status, description)
VALUES ('source_account_uuid', 'Transfer', 100.00, 'Completed', 'Transfer to Account B');

INSERT INTO transactions (account_id, transaction_type, amount, status, description)
VALUES ('destination_account_uuid', 'Transfer', 100.00, 'Completed', 'Transfer from Account A');

-- Record the fund transfer
INSERT INTO fund_transfers (from_account, to_account, amount, status, remarks)
VALUES ('source_account_uuid', 'destination_account_uuid', 100.00, 'Completed', 'Regular transfer');

COMMIT;
```

### 2.2 Explicit Locking Examples

#### 2.2.1 `FOR UPDATE` Lock for Preventing Race Conditions

```sql
BEGIN;
-- Lock the row while reading it
SELECT * FROM bank_accounts 
WHERE account_id = 'account_uuid' 
FOR UPDATE;

-- Now process the account with assurance that no other transaction can modify it
UPDATE bank_accounts 
SET balance = balance - 200.00
WHERE account_id = 'account_uuid';

COMMIT;
```

#### 2.2.2 `FOR SHARE` Lock for Concurrent Read Protection

```sql
BEGIN;
-- Allow other transactions to read but not modify
SELECT * FROM bank_accounts 
WHERE account_id = 'account_uuid' 
FOR SHARE;

-- Perform complex verification without worrying about the data changing
-- ...

COMMIT;
```

### 2.3 NOWAIT and SKIP LOCKED Options

#### 2.3.1 NOWAIT for Non-Blocking Operations

```sql
BEGIN;
-- Try to acquire lock, but fail immediately if not available
SELECT * FROM bank_accounts 
WHERE account_id = 'account_uuid' 
FOR UPDATE NOWAIT;

-- Process if lock acquired...
COMMIT;
```

#### 2.3.2 SKIP LOCKED for Queue Processing

```sql
BEGIN;
-- Process unprocessed payments, skipping any already locked by other transactions
SELECT * FROM payments 
WHERE status = 'Scheduled' AND scheduled_at <= now() 
FOR UPDATE SKIP LOCKED 
LIMIT 10;

-- Process these payments...
COMMIT;
```

## 3. Deadlock Detection and Resolution

### 3.1 What is a Deadlock?

A deadlock occurs when two or more transactions are waiting for each other to release locks, resulting in a circular dependency. PostgreSQL automatically detects deadlocks and resolves them by aborting one of the transactions.

### 3.2 Deadlock Scenario in Banking Context

Consider this deadlock scenario:

```
Transaction 1                 Transaction 2
------------                  ------------
BEGIN;                        BEGIN;
UPDATE bank_accounts          UPDATE bank_accounts
SET balance = balance - 100   SET balance = balance - 200
WHERE account_id = 'A';       WHERE account_id = 'B';

UPDATE bank_accounts          UPDATE bank_accounts
SET balance = balance + 100   SET balance = balance + 200
WHERE account_id = 'B';       WHERE account_id = 'A';

COMMIT;                       COMMIT;
```

Here, each transaction holds a lock on one account and waits for a lock on the other, creating a circular dependency.

### 3.3 PostgreSQL Deadlock Resolution

PostgreSQL:
1. Automatically detects deadlocks
2. Chooses a "victim" transaction to abort
3. Rolls back the victim transaction
4. Allows the other transaction to proceed
5. Returns a deadlock error to the client of the victim transaction

```
ERROR:  deadlock detected
DETAIL:  Process 1234 waits for ShareLock on transaction 5678; blocked by process 5678.
Process 5678 waits for ShareLock on transaction 1234; blocked by process 1234.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,1) in relation "bank_accounts"
```

### 3.4 Best Practices to Avoid Deadlocks

1. **Consistent Lock Acquisition Order**: Always acquire locks in the same order
   ```sql
   -- Always lock accounts in order of account_id
   BEGIN;
   -- First lock account with lower ID
   UPDATE bank_accounts 
   SET balance = balance - 100
   WHERE account_id = LEAST('A', 'B');
   
   -- Then lock account with higher ID
   UPDATE bank_accounts 
   SET balance = balance + 100
   WHERE account_id = GREATEST('A', 'B');
   COMMIT;
   ```

2. **Minimize Lock Duration**: Keep transactions short and focused

3. **Use Lock Timeouts**: Set `statement_timeout` or `lock_timeout` to prevent indefinite waiting
   ```sql
   -- Set transaction-level lock timeout
   SET lock_timeout = '5s';
   BEGIN;
   -- Try to acquire lock, but give up after 5 seconds
   UPDATE bank_accounts 
   SET balance = balance - 100
   WHERE account_id = 'account_uuid';
   COMMIT;
   ```

4. **Deadlock-Aware Application Logic**: Implement retry logic in your application
   ```python
   def perform_transfer(from_account, to_account, amount):
       max_retries = 3
       for attempt in range(max_retries):
           try:
               # Execute transaction
               # ...
               return "Success"
           except psycopg2.extensions.TransactionRollbackError as e:
               if "deadlock detected" in str(e) and attempt < max_retries - 1:
                   # Wait a bit and retry
                   time.sleep(0.5)
                   continue
               raise
   ```

## 4. Performance Considerations

### 4.1 Optimizing Row-Locking Performance

1. **Index Optimization**: Ensure that columns used in WHERE clauses are properly indexed
   ```sql
   CREATE INDEX idx_bank_accounts_customer_id ON bank_accounts(customer_id);
   ```

2. **Batch Processing**: Process large amounts of data in smaller batches
   ```sql
   -- Process account updates in batches 
   UPDATE bank_accounts
   SET status = 'Inactive'
   WHERE customer_id IN (
       SELECT customer_id FROM customers WHERE is_active = FALSE
   )
   LIMIT 1000;
   ```

3. **Lock Monitoring**: Use pg_stat_activity to monitor lock situations
   ```sql
   SELECT pid, query, query_start, state, waiting 
   FROM pg_stat_activity 
   WHERE state = 'active';
   ```

### 4.2 Optimizing for Different Workloads

1. **Read-Heavy Workloads**: Utilize MVCC (covered in the MVCC document)

2. **Write-Heavy Workloads**: Consider table partitioning to reduce lock contention
   ```sql
   -- Example: Partitioning transactions by date
   CREATE TABLE transactions_partitioned (
       transaction_id UUID,
       account_id UUID NOT NULL,
       transaction_type TEXT,
       amount NUMERIC(18,2) NOT NULL,
       status TEXT,
       created_at TIMESTAMPTZ DEFAULT now(),
       -- other fields
       PRIMARY KEY (transaction_id, created_at)
   ) PARTITION BY RANGE (created_at);
   
   -- Create monthly partitions
   CREATE TABLE transactions_y2025m01 PARTITION OF transactions_partitioned
       FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
   ```

## 5. Advanced Locking Techniques

### 5.1 Advisory Locks

PostgreSQL offers application-level locks that aren't tied to specific database objects:

```sql
-- Acquire an advisory lock for a specific customer
SELECT pg_advisory_xact_lock(hashtext('customer_process_' || customer_id::text))
FROM customers
WHERE customer_id = 'specific_uuid';

-- Process customer data
-- Lock will be released automatically when transaction ends
```

### 5.2 Row-Level Security for Additional Protection

```sql
-- Create a policy that only allows access to accounts owned by the current user
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY account_access_policy ON bank_accounts
    USING (customer_id = current_setting('app.current_customer_id')::uuid);
```

## 6. Real-World Banking Scenarios

### 6.1 High-Frequency Trading Module

```sql
-- Process trading orders with minimal lock contention
BEGIN;
-- Lock only the specific records needed
SELECT * FROM bank_accounts
WHERE account_id = 'trading_account_uuid'
FOR UPDATE SKIP LOCKED;

-- Execute trade if conditions met
-- ...

COMMIT;
```

### 6.2 Month-End Batch Processing

```sql
-- Efficient batch processing of monthly account maintenance fees
BEGIN;
-- Process in batches with ordered locking to avoid deadlocks
WITH accounts_to_update AS (
    SELECT account_id, balance, account_type
    FROM bank_accounts
    WHERE account_type = 'Checking'
      AND balance > 0
    ORDER BY account_id  -- Consistent ordering prevents deadlocks
    LIMIT 1000
    FOR UPDATE SKIP LOCKED
)
UPDATE bank_accounts ba
SET balance = ba.balance - 
    CASE WHEN ba.balance >= 5.00 THEN 5.00 ELSE ba.balance END
FROM accounts_to_update atu
WHERE ba.account_id = atu.account_id;

-- Record the maintenance fee transactions
INSERT INTO transactions (account_id, transaction_type, amount, status, description)
SELECT account_id, 'Withdrawal', 
    CASE WHEN balance >= 5.00 THEN 5.00 ELSE balance END,
    'Completed', 'Monthly maintenance fee'
FROM accounts_to_update;

COMMIT;
```

### 6.3 Distributed Banking System

```sql
-- Use explicit locking with NOWAIT for distributed systems
BEGIN;
-- Try to lock the account
SELECT * FROM bank_accounts
WHERE account_id = 'account_uuid'
FOR UPDATE NOWAIT;

-- If we get here, we have the lock
UPDATE bank_accounts
SET balance = balance - 100.00
WHERE account_id = 'account_uuid';

-- If another node already has the lock, we'll get an error
-- and can retry or route to the correct node
COMMIT;
```

## Conclusion

Row-level locking in PostgreSQL provides the necessary mechanisms to ensure data integrity in high-concurrency banking applications. Understanding the different lock modes, deadlock resolution, and implementing best practices will help you build robust banking systems that can handle concurrent operations safely and efficiently.

Remember that locking strategies should be designed with your specific workload in mind, balancing between data integrity guarantees and performance considerations.
