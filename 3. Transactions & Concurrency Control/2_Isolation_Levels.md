# PostgreSQL Isolation Levels for Banking Systems

## Introduction

In banking systems, `multiple users and processes need to work with the same data simultaneously`. A teller might be processing a withdrawal while an ATM is handling a deposit to the same account, and meanwhile, the accounting system is calculating interest. PostgreSQL's isolation levels are crucial for maintaining data integrity in these high-concurrency scenarios.

## Understanding Isolation in Banking Context

Isolation ensures that concurrent transactions don't interfere with each other. Without proper isolation, banking systems could experience:

- **Lost updates**: One transaction overwrites changes made by another
- **Dirty reads**: Reading uncommitted data that might be rolled back
- **Non-repeatable reads**: Getting different results when reading the same data twice
- **Phantom reads**: New rows appearing in a result set during a transaction

Each of these anomalies could be catastrophic in a banking system. For example, a dirty read could show a deposit that is later rolled back, causing the bank to disburse money that doesn't exist.

## PostgreSQL Isolation Levels

PostgreSQL provides four isolation levels as defined by the SQL standard:

1. **READ UNCOMMITTED** (behaves like READ COMMITTED in PostgreSQL)
2. **READ COMMITTED** (the default)
3. **REPEATABLE READ**
4. **SERIALIZABLE**

Let's examine each level in detail with banking-specific examples.

## READ COMMITTED Isolation

### What It Guarantees

- Prevents dirty reads (reading uncommitted data)
- Does NOT prevent non-repeatable reads
- Does NOT prevent phantom reads

### Banking Example

Consider a scenario where a customer is checking their balance while a deposit is being processed:

Transaction 1 (Deposit Processing):

```sql
BEGIN;
-- Initial balance is $1000
UPDATE accounts SET balance = balance + 500 WHERE account_id = 'A';
-- Balance is now $1500, but not yet committed
-- Processing payment details...
```

Transaction 2 (Balance Check - READ COMMITTED):

```sql
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Check balance
SELECT balance FROM accounts WHERE account_id = 'A';
-- Will return $1000 because Transaction 1 hasn't committed yet
```

Transaction 1 (continues):

```sql
-- Finalize deposit
COMMIT;
```

Transaction 2 (continues):

```sql
-- Check balance again
SELECT balance FROM accounts WHERE account_id = 'A';
-- Will return $1500 because Transaction 1 has now committed
COMMIT;
```

This demonstrates a non-repeatable read: the same query returns different results within the same transaction.

### Implementation Details

- PostgreSQL creates a new version of a row whenever it's updated
- Readers see the most recent committed version of a row
- Every statement gets a fresh snapshot of the database

### When to Use READ COMMITTED

- For routine account queries that don't need precise consistency
- When processing high-volume, independent transactions
- For dashboard or reporting applications that don't make decisions based on query results

## REPEATABLE READ Isolation

### What It Guarantees

- Prevents dirty reads
- Prevents non-repeatable reads
- Does NOT prevent phantom reads (though PostgreSQL's implementation actually does prevent them)

### Banking Example

Consider a scenario where a bank is running end-of-day calculations:

Transaction 1 (End-of-day Processing):

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Calculate total deposits
SELECT SUM(balance) FROM accounts WHERE account_type = 'Savings';
-- Result: $1,000,000

-- Perform other calculations that take time...
```

Transaction 2 (Deposit Processing):

```sql
BEGIN;
-- Process a new deposit
UPDATE accounts SET balance = balance + 50000 WHERE account_id = 'A';
COMMIT;
```

Transaction 1 (continues):

```sql
-- Calculate total deposits again
SELECT SUM(balance) FROM accounts WHERE account_type = 'Savings';
-- Result: $1,000,000 (unchanged, despite the deposit from Transaction 2)
COMMIT;
```

This is the key feature of REPEATABLE READ: queries within the same transaction see a consistent snapshot of the database, regardless of commits from other transactions.

### Implementation Details

- PostgreSQL takes a snapshot of the database at the start of a transaction
- All queries within the transaction see that snapshot
- Updates from other committed transactions are hidden from the current transaction

### When to Use REPEATABLE READ

- For financial reporting and analysis
- For batch processing jobs that need a consistent view
- When calculating interest or fees that depend on multiple related queries
- For transactions that make decisions based on query results

## SERIALIZABLE Isolation

### What It Guarantees

- Prevents dirty reads
- Prevents non-repeatable reads
- Prevents phantom reads
- Ensures transactions behave as if they were executed sequentially

### Banking Example

Consider a complex scenario involving overdraft protection:

Transaction 1 (Withdrawal with Overdraft Check):

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Check account balance
SELECT balance FROM accounts WHERE account_id = 'A';
-- Result: $100

-- Check pending automatic payments
SELECT SUM(amount) FROM scheduled_payments
WHERE account_id = 'A' AND payment_date = CURRENT_DATE;
-- Result: $50

-- Decide customer can withdraw $40 (leaving enough for scheduled payments)
UPDATE accounts SET balance = balance - 40 WHERE account_id = 'A';
COMMIT;
```

Transaction 2 (Another Withdrawal - runs concurrently):

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Check account balance
SELECT balance FROM accounts WHERE account_id = 'A';
-- Result: $100 (sees same starting balance)

-- Check pending automatic payments
SELECT SUM(amount) FROM scheduled_payments
WHERE account_id = 'A' AND payment_date = CURRENT_DATE;
-- Result: $50

-- Decide customer can withdraw $40
UPDATE accounts SET balance = balance - 40 WHERE account_id = 'A';

-- At this point, PostgreSQL detects a serialization failure
-- because both transactions are trying to make decisions based on
-- the same data and updating the same rows
-- This transaction will fail with error: "ERROR: could not serialize access due to concurrent update"
ROLLBACK;
```

This is the power of SERIALIZABLE isolation: it prevents situations where concurrent transactions could make decisions based on data that would be inconsistent if the transactions ran one after another.

### Implementation Details

- PostgreSQL uses a predicate lock system to detect serialization anomalies
- When a transaction would violate serializability, it fails with a serialization error
- Applications must be prepared to retry failed transactions

### When to Use SERIALIZABLE

- For critical financial operations where consistency is paramount
- When implementing complex business rules that depend on multiple conditions
- For operations that must be atomic across multiple tables or queries
- When the correctness of a transaction depends on the absence of concurrent changes

## Performance Considerations

Each isolation level has performance implications:

| Isolation Level | Concurrency | Performance | Use Case in Banking                                   |
| --------------- | ----------- | ----------- | ----------------------------------------------------- |
| READ COMMITTED  | High        | Best        | Routine account queries, high-volume operations       |
| REPEATABLE READ | Medium      | Good        | Financial reporting, interest calculations            |
| SERIALIZABLE    | Low         | Lowest      | Critical financial operations, complex business rules |

## Implementing Isolation Levels in Banking Applications

### Setting Transaction Isolation Level

```sql
-- For a single transaction
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Run your queries and updates
COMMIT;

-- For the entire session
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

### Handling Serialization Failures

Banking applications using SERIALIZABLE isolation should implement retry logic:

```sql
DO $$
DECLARE
  max_retries CONSTANT INT := 5;
  retry_count INT := 0;
  transaction_successful BOOLEAN := FALSE;
BEGIN
  WHILE retry_count < max_retries AND NOT transaction_successful LOOP
    BEGIN
      -- Start a serializable transaction
      PERFORM set_config('transaction_isolation', 'serializable', true);
      BEGIN;

      -- Perform your banking operation
      -- For example, a complex transfer with overdraft protection
      -- ...

      COMMIT;
      transaction_successful := TRUE;

    EXCEPTION WHEN serialization_failure OR deadlock_detected THEN
      -- Roll back the transaction
      ROLLBACK;
      -- Increment retry counter
      retry_count := retry_count + 1;
      -- Optionally add a small delay before retrying
      PERFORM pg_sleep(random() * 0.1);
    END;
  END LOOP;

  IF NOT transaction_successful THEN
    RAISE EXCEPTION 'Transaction failed after % retries', max_retries;
  END IF;
END $$;
```

## Advanced Isolation Techniques for Banking

### Advisory Locks for Specific Accounts

To prevent concurrency issues for specific high-value accounts:

```sql
-- Acquire advisory lock on an account before processing
SELECT pg_advisory_xact_lock(account_id) FROM accounts WHERE account_number = '12345678';

-- Now process the account with exclusive access
-- Other transactions trying to acquire a lock on this account will wait
```

### Deferrable Constraints for Complex Transactions

For complex operations that might temporarily violate constraints:

```sql
BEGIN;
SET CONSTRAINTS ALL DEFERRED;

-- Perform operations that might temporarily violate constraints
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 'A';
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 'B';

-- At COMMIT time, all constraints will be checked
COMMIT;
```

## Monitoring Isolation Issues

PostgreSQL provides several ways to monitor isolation-related issues:

1. **Transaction conflicts**:

   ```sql
   SELECT * FROM pg_stat_database_conflicts;
   ```

2. **Long-running transactions** (which can cause MVCC bloat):

   ```sql
   SELECT pid, now() - xact_start AS duration, query
   FROM pg_stat_activity
   WHERE state = 'active' AND xact_start IS NOT NULL
   ORDER BY duration DESC;
   ```

3. **Lock contention**:
   ```sql
   SELECT blocked_locks.pid AS blocked_pid,
          blocked_activity.usename AS blocked_user,
          blocking_locks.pid AS blocking_pid,
          blocking_activity.usename AS blocking_user,
          blocked_activity.query AS blocked_statement,
          blocking_activity.query AS blocking_statement
   FROM pg_catalog.pg_locks blocked_locks
   JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
   JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
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

## Isolation Level Best Practices for Banking

1. **Default to READ COMMITTED** for general operations
2. **Use REPEATABLE READ** for:
   - End-of-day processing
   - Financial reporting
   - Interest calculations
3. **Use SERIALIZABLE** for:
   - Overdraft protection
   - Complex account transfers
   - Operations involving multiple accounts or conditions

## Conclusion

Choosing the right isolation level is critical for banking applications. While higher isolation levels provide stronger guarantees, they come with performance costs and the potential for serialization failures. A well-designed banking system will use different isolation levels for different types of operations, balancing data consistency with performance and user experience.

Remember, no isolation level can replace proper application design and transaction management. Always structure your banking transactions carefully, handle potential failures gracefully, and monitor your system for isolation-related issues.
