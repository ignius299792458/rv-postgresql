# 3. Partial Indexes, Covering Indexes & Multi-column Indexes

## Partial Indexes

Partial indexes index only a subset of rows based on a WHERE condition, making them smaller and more efficient.

**Key benefits:**

- Smaller index size
- Faster updates
- Better selectivity
- Lower maintenance overhead

**Example in Banking DB:**

```sql
-- Partial index for active accounts only
CREATE INDEX idx_accounts_active ON bank_accounts (account_number)
WHERE status = 'Active';

-- Partial index for high-value transactions (often queried)
CREATE INDEX idx_transactions_highvalue ON transactions (account_id, created_at)
WHERE amount > 10000;

-- Partial index for pending transactions
CREATE INDEX idx_transactions_pending ON transactions (created_at)
WHERE status = 'Pending';
```

**Query examples using partial indexes:**

```sql
-- This will use the partial index
EXPLAIN ANALYZE
SELECT * FROM bank_accounts
WHERE status = 'Active' AND account_number LIKE 'SA%';

-- This will use the high-value transactions index
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE amount > 10000
ORDER BY created_at DESC;
```

## Covering Indexes (Index-Only Scans)

A covering index includes all columns needed by a query, allowing PostgreSQL to satisfy the query using only the index without accessing the table.

**Key benefits:**

- Eliminates table lookups
- Dramatically improves performance
- Reduces I/O operations

**Example in Banking DB:**

```sql
-- Covering index for common transaction listing query
CREATE INDEX idx_transactions_covering ON transactions
(account_id, created_at, amount, transaction_type, status);

-- Covering index for customer search
CREATE INDEX idx_customers_search ON customers
(last_name, first_name, email, customer_id);
```

**Query examples using covering indexes:**

```sql
-- This can use index-only scan with the covering index
EXPLAIN ANALYZE
SELECT account_id, created_at, amount, transaction_type, status
FROM transactions
WHERE account_id = '123e4567-e89b-12d3-a456-426614174000'
ORDER BY created_at DESC;

-- Customer search with index-only scan
EXPLAIN ANALYZE
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE last_name = 'Smith'
ORDER BY first_name;
```

## Multi-column Indexes

Multi-column indexes contain multiple columns and work best when query conditions match the index's column order.

**Key principles:**

- **Column order matters**: Most selective column should typically be first
- **Useful for**: Queries filtering on multiple columns
- **Equality before range**: Place equality conditions before range conditions

**Example in Banking DB:**

```sql
-- Multi-column index for transaction search (account_id equality, date range)
CREATE INDEX idx_transactions_account_date ON transactions (account_id, created_at);

-- Multi-column index for customer filtering
CREATE INDEX idx_customers_location_status ON customers
((address->>'city'), (address->>'country'), is_active);

-- Multi-column index for transfers search
CREATE INDEX idx_transfers_accounts ON fund_transfers
(from_account, to_account, status);
```

**Query examples using multi-column indexes:**

```sql
-- Uses multi-column index: account_id (equality) comes before created_at (range)
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE account_id = '123e4567-e89b-12d3-a456-426614174000'
AND created_at BETWEEN '2023-01-01' AND '2023-01-31';

-- Uses multi-column index for customer location
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE address->>'city' = 'New York'
AND address->>'country' = 'USA'
AND is_active = TRUE;
```

## Advanced Index Strategies

1. **Expression Indexes** for computed values:

   ```sql
   -- Index on lowercase email for case-insensitive searches
   CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));

   -- Index on transaction month for reporting queries
   CREATE INDEX idx_transactions_month ON transactions (date_trunc('month', created_at));
   ```

2. **Functional Indexes** for JSONB and complex types:

   ```sql
   -- Index for JSONB city searches
   CREATE INDEX idx_customers_city ON customers ((address->>'city'));

   -- Index for transaction categories in JSONB
   CREATE INDEX idx_transactions_category ON transactions ((metadata->>'category'));
   ```

3. **Custom Operator Class Indexes** for specialized comparisons:

   ```sql
   -- Install trigram extension
   CREATE EXTENSION IF NOT EXISTS pg_trgm;

   -- Trigram index for fuzzy name searches
   CREATE INDEX idx_customers_name_trigram ON customers
   USING gin ((first_name || ' ' || last_name) gin_trgm_ops);
   ```

4. **Combining Index Types** for complex queries:
   ```sql
   -- Partial covering index for recent high-value transactions
   CREATE INDEX idx_transactions_recent_highvalue ON transactions
   (account_id, created_at, amount, status)
   WHERE created_at > current_date - interval '30 days' AND amount > 5000;
   ```
