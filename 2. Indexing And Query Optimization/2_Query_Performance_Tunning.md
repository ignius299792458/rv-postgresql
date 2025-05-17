# 2. Query Performance Tuning

Performance tuning `is the process of optimizing the speed, efficiency, and scalability of a database system`. It involves identifying and removing bottlenecks in queries, schema, indexes, configuration, and hardware resources to ensure your PostgreSQL database performs at its best under given workloads.

Understanding how PostgreSQL executes queries is essential for performance tuning. The `EXPLAIN` and `EXPLAIN ANALYZE` commands `reveal the query execution plan and actual performance data`.

## The EXPLAIN Command

`EXPLAIN` shows the `query execution plan without actually running the query`:

```sql
EXPLAIN
SELECT t.transaction_id, t.amount, c.first_name, c.last_name
FROM transactions t
JOIN bank_accounts b ON t.account_id = b.account_id
JOIN customers c ON b.customer_id = c.customer_id
WHERE t.amount > 1000
AND t.created_at > '2023-01-01'
ORDER BY t.amount DESC;
```

## EXPLAIN ANALYZE

EXPLAIN ANALYZE actually `executes the query and provides real-world timing information`:

```sql
EXPLAIN ANALYZE
SELECT t.transaction_id, t.amount, c.first_name, c.last_name
FROM transactions t
JOIN bank_accounts b ON t.account_id = b.account_id
JOIN customers c ON b.customer_id = c.customer_id
WHERE t.amount > 1000
AND t.created_at > '2023-01-01'
ORDER BY t.amount DESC;
```

## Key Components of Query Plans

1. **Scan Methods**:

   - **Sequential Scan**: Reads entire table (slowest for large tables)
   - **Index Scan**: Uses index to find rows, then fetches from table
   - **Index Only Scan**: Gets all data from index (fastest)
   - **Bitmap Scan**: Creates bitmap of pages to fetch, then retrieves them

2. **Join Methods**:

   - **Nested Loop**: Good for small tables or when few rows match
   - **Hash Join**: Good for larger tables without suitable indexes
   - **Merge Join**: Good for pre-sorted data

3. **Key Performance Metrics**:
   - **Cost**: Estimated processing units (higher = more expensive)
   - **Rows**: Estimated number of rows returned
   - **Width**: Estimated average row width in bytes
   - **Actual Time**: Real execution time (with EXPLAIN ANALYZE)
   - **Loops**: Number of iterations of this node

## Identifying Common Query Performance Issues

1. **Sequential Scans on Large Tables**:

   ```
   Seq Scan on transactions  (cost=0.00..45000.00 rows=...)
   ```

   **Solution**: Create indexes on filtered columns

2. **Nested Loop Joins with Large Row Counts**:

   ```
   Nested Loop  (cost=0.00..1500000.00 rows=100000 width=...)
   ```

   **Solution**: Ensure join columns are indexed, consider query rewriting

3. **High Filter Costs**:

   ```
   Filter: (amount > 1000::numeric)  (rows removed by filter=1000000)
   ```

   **Solution**: Add appropriate indexes or partial indexes

4. **Sort Operations on Large Data Sets**:

   ```
   Sort  (cost=25000.00..26000.00 rows=100000 width=...)
   ```

   **Solution**: Create index with appropriate sort order

5. **Hash Join with High Memory Usage**:
   ```
   Hash Join  (cost=15000.00..45000.00 rows=100000 width=...)
     Hash Cond: (t.account_id = b.account_id)
     ->  Seq Scan on transactions t  (...)
     ->  Hash  (cost=10000.00..10000.00 rows=100000 width=...)
           ->  Seq Scan on bank_accounts b  (...)
   ```
   **Solution**: Add indexes to join columns, increase work_mem

## Real-world Examples from Banking DB

**Example 1: Analyzing a slow customer transaction query**

```sql
EXPLAIN ANALYZE
SELECT c.first_name, c.last_name, t.amount, t.created_at, t.description
FROM customers c
JOIN bank_accounts b ON c.customer_id = b.customer_id
JOIN transactions t ON b.account_id = t.account_id
WHERE c.last_name LIKE 'Smith%'
AND t.amount > 500
ORDER BY t.created_at DESC;
```

**Potential improvements:**

```sql
-- Add index for last_name pattern search
CREATE INDEX idx_customers_lastname ON customers (last_name text_pattern_ops);

-- Add composite index for transaction filtering and sorting
CREATE INDEX idx_transactions_amount_date ON transactions (amount, created_at DESC);
```

**Example 2: Optimizing a transaction summary report**

```sql
EXPLAIN ANALYZE
SELECT
    date_trunc('month', t.created_at) AS month,
    t.transaction_type,
    SUM(t.amount) AS total_amount,
    COUNT(*) AS transaction_count
FROM transactions t
WHERE t.created_at BETWEEN '2023-01-01' AND '2023-12-31'
AND t.status = 'Completed'
GROUP BY date_trunc('month', t.created_at), t.transaction_type
ORDER BY month, transaction_type;
```

**Potential improvements:**

```sql
-- Add partial index for completed transactions
CREATE INDEX idx_transactions_completed ON transactions (created_at, transaction_type)
WHERE status = 'Completed';
```

# Query Optimization Techniques

1. **Rewriting JOIN Order**:

   ```sql
   -- Before: Slow query starting with customers
   SELECT * FROM customers c
   JOIN bank_accounts b ON c.customer_id = b.customer_id
   JOIN transactions t ON b.account_id = t.account_id
   WHERE t.amount > 10000;

   -- After: Faster query starting with transactions
   SELECT * FROM transactions t
   JOIN bank_accounts b ON t.account_id = b.account_id
   JOIN customers c ON b.customer_id = c.customer_id
   WHERE t.amount > 10000;
   ```

2. **Using CTEs for Clarity and Performance**:

   ```sql
   -- Using CTE for complex query
   WITH large_transactions AS (
     SELECT account_id, SUM(amount) as total_amount
     FROM transactions
     WHERE amount > 1000
     GROUP BY account_id
   )
   SELECT c.first_name, c.last_name, lt.total_amount
   FROM large_transactions lt
   JOIN bank_accounts b ON lt.account_id = b.account_id
   JOIN customers c ON b.customer_id = c.customer_id
   ORDER BY lt.total_amount DESC;
   ```

3. **Using LIMIT with ORDER BY**:

   ```sql
   -- Add LIMIT to reduce sorting overhead
   SELECT * FROM transactions
   ORDER BY created_at DESC
   LIMIT 100;
   ```

4. **Avoid Functions on Indexed Columns**:

   ```sql
   -- Bad: Function prevents index usage
   SELECT * FROM customers WHERE LOWER(email) = 'john.doe@example.com';

   -- Good: Store normalized data or use functional index
   CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));
   SELECT * FROM customers WHERE LOWER(email) = 'john.doe@example.com';
   ```

5. **Subquery Optimization**:
   ```sql
   -- Use EXISTS instead of IN for better performance
   SELECT * FROM customers c
   WHERE EXISTS (
       SELECT 1 FROM bank_accounts b
       WHERE b.customer_id = c.customer_id
       AND b.balance > 10000
   );
   ```
