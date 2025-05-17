## 4. PostgreSQL Extensions

PostgreSQL's extensibility allows for specialized functionality through additional modules.

### Example: PostGIS for Geospatial Banking Data

```sql
-- Install PostGIS extension
CREATE EXTENSION postgis;

-- Add geospatial capabilities to tables
ALTER TABLE customers
ADD COLUMN location GEOGRAPHY(POINT);

-- Create spatial index
CREATE INDEX idx_customers_location ON customers USING GIST(location);

-- Add transaction locations
ALTER TABLE transactions
ADD COLUMN transaction_location GEOGRAPHY(POINT);

-- Function to find nearest ATM
CREATE OR REPLACE FUNCTION find_nearest_atms(
    customer_id UUID,
    max_distance_meters INTEGER DEFAULT 5000,
    limit_results INTEGER DEFAULT 5
)
RETURNS TABLE (
    atm_id INTEGER,
    atm_name TEXT,
    address TEXT,
    distance_meters NUMERIC
)
LANGUAGE SQL
AS $$
    WITH customer_location AS (
        SELECT location FROM customers WHERE customer_id = find_nearest_atms.customer_id
    )
    SELECT
        a.atm_id,
        a.atm_name,
        a.address,
        ST_Distance(a.location, c.location)::NUMERIC AS distance_meters
    FROM
        atms a,
        customer_location c
    WHERE
        ST_DWithin(a.location, c.location, find_nearest_atms.max_distance_meters)
    ORDER BY
        ST_Distance(a.location, c.location)
    LIMIT find_nearest_atms.limit_results;
$$;

-- Query to detect potentially fraudulent transactions based on location
CREATE VIEW potential_location_fraud AS
SELECT
    t1.transaction_id AS recent_transaction_id,
    t1.amount AS recent_amount,
    t1.created_at AS recent_time,
    t2.transaction_id AS previous_transaction_id,
    t2.amount AS previous_amount,
    t2.created_at AS previous_time,
    ST_Distance(t1.transaction_location, t2.transaction_location) / 1000 AS distance_km,
    ST_Distance(t1.transaction_location, t2.transaction_location) /
        (EXTRACT(EPOCH FROM (t1.created_at - t2.created_at)) / 3600) AS speed_kmh
FROM
    transactions t1
JOIN
    transactions t2 ON t1.account_id = t2.account_id
                   AND t1.created_at > t2.created_at
                   AND t1.created_at < t2.created_at + INTERVAL '24 hours'
WHERE
    -- Calculate if the customer would need to travel faster than 800 km/h between transactions
    -- (approximate speed of commercial aircraft)
    ST_Distance(t1.transaction_location, t2.transaction_location) /
        (EXTRACT(EPOCH FROM (t1.created_at - t2.created_at)) / 3600) > 800
ORDER BY
    t1.account_id, t1.created_at DESC;
```

### Example: TimescaleDB for Time-Series Banking Data

```sql
-- Install TimescaleDB extension
CREATE EXTENSION timescaledb;

-- Create a hypertable for more granular transaction data
CREATE TABLE transaction_metrics (
    time TIMESTAMPTZ NOT NULL,
    account_id UUID NOT NULL,
    transaction_type TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    running_balance NUMERIC NOT NULL,
    channel TEXT,
    category TEXT,
    merchant TEXT
);

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('transaction_metrics', 'time');

-- Create a continuous aggregate for daily account metrics
CREATE MATERIALIZED VIEW daily_account_metrics
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    account_id,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS total_inflow,
    SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) AS total_outflow,
    MIN(running_balance) AS min_balance,
    MAX(running_balance) AS max_balance,
    LAST(running_balance, time) AS end_balance
FROM
    transaction_metrics
GROUP BY
    time_bucket('1 day', time), account_id;

-- Set refresh policy (refresh every day at 3am)
SELECT add_continuous_aggregate_policy('daily_account_metrics',
    start_offset => INTERVAL '3 months',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 day');

-- Function to analyze spending patterns
CREATE OR REPLACE FUNCTION analyze_spending_patterns(
    account_id UUID,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ
)
RETURNS TABLE (
    category TEXT,
    total_spent NUMERIC,
    transaction_count BIGINT,
    average_transaction NUMERIC,
    percentage_of_spending NUMERIC
)
LANGUAGE SQL
AS $$
    WITH total_spending AS (
        SELECT SUM(ABS(amount)) AS total
        FROM transaction_metrics
        WHERE
            account_id = analyze_spending_patterns.account_id AND
            time >= start_date AND
            time <= end_date AND
            amount < 0
    )
    SELECT
        category,
        SUM(ABS(amount)) AS total_spent,
        COUNT(*) AS transaction_count,
        SUM(ABS(amount)) / COUNT(*) AS average_transaction,
        (SUM(ABS(amount)) / total_spending.total) * 100 AS percentage_of_spending
    FROM
        transaction_metrics, total_spending
    WHERE
        account_id = analyze_spending_patterns.account_id AND
        time >= start_date AND
        time <= end_date AND
        amount < 0
    GROUP BY
        category, total_spending.total
    ORDER BY
        total_spent DESC;
$$;
```

### Example: pg_cron for Scheduled Banking Operations

```sql
-- Install pg_cron extension
CREATE EXTENSION pg_cron;

-- Schedule daily interest calculation (runs at 1am)
SELECT cron.schedule('daily-interest-calc', '0 1 * * *', $$
    -- Apply daily interest to savings accounts
    UPDATE bank_accounts
    SET balance = balance * (1 + (interest_rate / 36500))
    WHERE account_type = 'Saving' AND status = 'Active' AND interest_rate > 0;

    -- Log the interest application
    INSERT INTO transactions (
        account_id,
        transaction_type,
        amount,
        status,
        description
    )
    SELECT
        account_id,
        'Deposit',
        balance * (interest_rate / 36500),
        'Completed',
        'Daily interest credit'
    FROM
        bank_accounts
    WHERE
        account_type = 'Saving'
        AND status = 'Active'
        AND interest_rate > 0;
$$);

-- Schedule monthly account statements (runs on 1st of each month)
SELECT cron.schedule('monthly-statements', '0 2 1 * *', $$
    -- Insert monthly statement generation job
    INSERT INTO statement_jobs (run_date, status)
    VALUES (now(), 'Pending');
$$);

-- Schedule daily inactive account check (runs at 3am)
SELECT cron.schedule('inactive-account-check', '0 3 * * *', $$
    -- Flag accounts with no activity for 12 months
    UPDATE bank_accounts
    SET
        status = 'Dormant',
        extra_meta = extra_meta || hstore('dormant_since', now()::text)
    WHERE
        account_id NOT IN (
            SELECT DISTINCT account_id
            FROM transactions
            WHERE created_at > now() - INTERVAL '12 months'
        )
        AND status = 'Active';
$$);
```

### Example: pgAudit for Enhanced Banking Compliance

```sql
-- Install pgAudit extension
CREATE EXTENSION pgaudit;

-- Configure pgAudit to log DDL, ROLE, READ and WRITE operations
ALTER SYSTEM SET pgaudit.log = 'ddl, role, read, write';
ALTER SYSTEM SET pgaudit.log_catalog = off;
ALTER SYSTEM SET pgaudit.log_relation = on;
ALTER SYSTEM SET pgaudit.log_statement_once = off;

-- Create audit log table
CREATE TABLE banking_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    log_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    user_name TEXT,
    database_name TEXT,
    process_id INTEGER,
    remote_host TEXT,
    session_id TEXT,
    session_start_time TIMESTAMP WITH TIME ZONE,
    command_tag TEXT,
    session_line_num BIGINT,
    command_text TEXT,
    relation_name TEXT,
    object_type TEXT,
    statement_type TEXT
);

-- Function to capture audit logs
CREATE OR REPLACE FUNCTION capture_audit_logs()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO banking_audit_logs (
        user_name,
        database_name,
        process_id,
        remote_host,
        session_id,
        session_start_time,
        command_tag,
        session_line_num,
        command_text,
        relation_name,
        object_type,
        statement_type
    )
    SELECT
        current_user,
        current_database(),
        pg_backend_pid(),
        inet_client_addr(),
        pg_catalog.to_hex(unique_session_id),
        backend_start,
        command_tag,
        message_line_num,
        command_text,
        object_identity,
        object_type,
        statement_type
    FROM
        pg_catalog.pg_stat_activity,
        pgaudit.logged_relations;
END;
$$;

-- Create event trigger for DDL operations
CREATE EVENT TRIGGER banking_audit_capture ON ddl_command_end
EXECUTE FUNCTION capture_audit_logs();
```

### Benefits for Banking Applications:

- Enhanced security and compliance tracking
- Scheduled maintenance and operational tasks
- Advanced spatial analysis for fraud detection and branch planning
- Efficient time-series data analysis for financial trends
- Specialized capabilities tailored to banking requirements
