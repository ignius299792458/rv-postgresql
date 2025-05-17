## 1. Materialized Views

Materialized views store the results of complex queries for faster access, refreshing only when explicitly requested. This is particularly valuable for banking analytics and reporting.

### Example: Customer Account Summary

```sql
CREATE MATERIALIZED VIEW customer_account_summary AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    COUNT(ba.account_id) AS total_accounts,
    SUM(ba.balance) AS total_balance,
    array_agg(DISTINCT ba.account_type) AS account_types,
    MAX(ba.opened_at) AS latest_account_opened
FROM
    customers c
JOIN
    bank_accounts ba ON c.customer_id = ba.customer_id
WHERE
    ba.status = 'Active'
GROUP BY
    c.customer_id, c.first_name, c.last_name;

-- Create an index on the materialized view for faster lookups
CREATE UNIQUE INDEX idx_customer_account_summary ON customer_account_summary(customer_id);
```

### Example: Transaction Analytics View

```sql
CREATE MATERIALIZED VIEW transaction_monthly_summary AS
SELECT
    ba.customer_id,
    DATE_TRUNC('month', t.created_at) AS month,
    t.transaction_type,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS total_amount
FROM
    transactions t
JOIN
    bank_accounts ba ON t.account_id = ba.account_id
WHERE
    t.status = 'Completed'
GROUP BY
    ba.customer_id, DATE_TRUNC('month', t.created_at), t.transaction_type;

-- Create an index for efficient customer lookup
CREATE INDEX idx_transaction_monthly_customer ON transaction_monthly_summary(customer_id);
```

### Refreshing Materialized Views

```sql
-- Refresh the data (complete refresh)
REFRESH MATERIALIZED VIEW customer_account_summary;

-- Concurrent refresh (doesn't block reads)
REFRESH MATERIALIZED VIEW CONCURRENTLY customer_account_summary;
```

### Benefits for Banking Applications:

- Faster dashboard loading with pre-calculated customer metrics
- Efficient reporting without impacting transaction processing
- Better performance for complex analytics queries
- Reduced CPU load during peak banking hours
