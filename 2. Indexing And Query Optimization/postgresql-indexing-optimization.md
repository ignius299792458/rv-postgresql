# PostgreSQL Indexing & Query Optimization: In-Depth Guide

## 5. Comprehensive Indexing Strategy for Banking DB

Based on all the concepts discussed, here's a comprehensive indexing strategy for the banking database:

### Customers Table

```sql
-- B-Tree indexes for common lookups
CREATE INDEX idx_customers_name ON customers (last_name, first_name);
CREATE INDEX idx_customers_dob ON customers (date_of_birth);

-- GIN index for JSONB address searches
CREATE INDEX idx_customers_address_gin ON customers USING GIN (address);
CREATE INDEX idx_customers_address_city ON customers ((address->>'city'));
CREATE INDEX idx_customers_address_country ON customers ((address->>'country'));

-- GIN index for TEXT[] tags
CREATE INDEX idx_customers_tags_gin ON customers USING GIN (tags);

-- GIN index for HSTORE
CREATE INDEX idx_customers_preferences_gin ON customers USING GIN (preferences);

-- Trigram index for fuzzy name search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_customers_name_trigram ON customers
USING GIN ((first_name || ' ' || last_name) gin_trgm_ops);

-- Partial index for active customers
CREATE INDEX idx_customers_active ON customers (customer_id)
WHERE is_active = TRUE;

-- Functional index for case-insensitive email search
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));
```

### Bank Accounts Table

```sql
-- B-Tree indexes for common filters
CREATE INDEX idx_accounts_customer ON bank_accounts (customer_id);
CREATE INDEX idx_accounts_type_status ON bank_accounts (account_type, status);
CREATE INDEX idx_accounts_balance ON bank_accounts (balance);

-- Covering index for account listing
CREATE INDEX idx_accounts_customer_covering ON bank_accounts
(customer_id, account_number, account_type, balance, status);

-- Partial indexes for specific account types
CREATE INDEX idx_accounts_checking ON bank_accounts (customer_id, balance)
WHERE account_type = 'Checking';

CREATE INDEX idx_accounts_saving ON bank_accounts (customer_id, balance, interest_rate)
WHERE account_type = 'Saving';

-- GIN index for TEXT[] features
CREATE INDEX idx_accounts_features_gin ON bank_accounts USING GIN (features);

-- GIN index for JSONB transaction_limits
CREATE INDEX idx_accounts_limits_gin ON bank_accounts USING GIN (transaction_limits);
```

### Transactions Table

```sql
-- B-Tree indexes for common queries
CREATE INDEX idx_transactions_account ON transactions (account_id);
CREATE INDEX idx_transactions_type ON transactions (transaction_type);
CREATE INDEX idx_transactions_date ON transactions (created_at);
CREATE INDEX idx_transactions_account_date ON transactions (account_id, created_at);

-- Covering index for transaction listing
CREATE INDEX idx_transactions_listing ON transactions
(account_id, created_at, transaction_type, amount, status);

-- Partial indexes for transaction status
CREATE INDEX idx_transactions_pending ON transactions (created_at)
WHERE status = 'Pending';

CREATE INDEX idx_transactions_completed ON transactions (created_at, amount)
WHERE status = 'Completed';

-- GIN index for JSONB metadata
CREATE INDEX idx_transactions_metadata_gin ON transactions USING GIN (metadata);

-- GIN index for TEXT[] tags
CREATE INDEX idx_transactions_tags_gin ON transactions USING GIN (tags);

-- BRIN index for very large tables
CREATE INDEX idx_transactions_date_brin ON transactions USING BRIN (created_at)
WITH (pages_per_range = 128);

-- Full-text search index for description
CREATE INDEX idx_transactions_description_fulltext ON transactions
USING GIN (to_tsvector('english', description));

-- Functional index for transaction month (reporting)
CREATE INDEX idx_transactions_month ON transactions (date_trunc('month', created_at));
```

### Fund Transfers Table

```sql
-- B-Tree indexes for account relationships
CREATE INDEX idx_transfers_from ON fund_transfers (from_account);
CREATE INDEX idx_transfers_to ON fund_transfers (to_account);
CREATE INDEX idx_transfers_both ON fund_transfers (from_account, to_account);

-- Indexes for transfer filtering
CREATE INDEX idx_transfers_status ON fund_transfers (status);
CREATE INDEX idx_transfers_amount ON fund_transfers (amount);
CREATE INDEX idx_transfers_date ON fund_transfers (initiated_at);

-- Partial index for international transfers
CREATE INDEX idx_transfers_international ON fund_transfers (from_account, to_account, amount)
WHERE is_international = TRUE;

-- GIN index for JSONB audit_log
CREATE INDEX idx_transfers_audit_gin ON fund_transfers USING GIN (audit_log);

-- GIN index for TEXT[] tags
CREATE INDEX idx_transfers_tags_gin ON fund_transfers USING GIN (tags);
```

### Payments Table

```sql
-- B-Tree indexes for payment queries
CREATE INDEX idx_payments_account ON payments (payer_account);
CREATE INDEX idx_payments_dates ON payments (scheduled_at, paid_at);
CREATE INDEX idx_payments_status ON payments (status);

-- Multi-column index for payment filtering
CREATE INDEX idx_payments_account_dates ON payments (payer_account, scheduled_at, status);

-- Partial index for recurring payments
CREATE INDEX idx_payments_recurring ON payments (payer_account, scheduled_at)
WHERE recurring = TRUE;

-- Partial index for scheduled payments
CREATE INDEX idx_payments_scheduled ON payments (scheduled_at)
WHERE status = 'Scheduled';

-- GIN index for JSONB recurrence_rule
CREATE INDEX idx_payments_recurrence_gin ON payments USING GIN (recurrence_rule);

-- GIN index for TEXT[] tags
CREATE INDEX idx_payments_tags_gin ON payments USING GIN (tags);
```

## 6. Advanced Query Examples with Performance Analysis

### Complex Customer Analytics Query

```sql
EXPLAIN ANALYZE
WITH high_value_accounts AS (
    SELECT customer_id, SUM(balance) as total_balance
    FROM bank_accounts
    WHERE status = 'Active'
    GROUP BY customer_id
    HAVING SUM(balance) > 100000
),
customer_transactions AS (
    SELECT
        c.customer_id,
        COUNT(t.transaction_id) as transaction_count,
        AVG(t.amount) as avg_transaction_amount
    FROM customers c
    JOIN bank_accounts b ON c.customer_id = b.customer_id
    JOIN transactions t ON b.account_id = t.account_id
    WHERE t.created_at > current_date - interval '90 days'
    AND t.status = 'Completed'
    GROUP BY c.customer_id
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    hva.total_balance,
    ct.transaction_count,
    ct.avg_transaction_amount
FROM customers c
JOIN high_value_accounts hva ON c.customer_id = hva.customer_id
JOIN customer_transactions ct ON c.customer_id = ct.customer_id
WHERE c.is_active = TRUE
ORDER BY hva.total_balance DESC;
```

**Performance optimizations:**

- Ensure `bank_accounts(status, customer_id, balance)` has an index
- Add covering index
