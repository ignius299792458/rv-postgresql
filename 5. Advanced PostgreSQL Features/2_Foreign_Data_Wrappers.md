## 2. Foreign Data Wrappers (FDW)

FDWs allow PostgreSQL to interact with external data sources as if they were PostgreSQL tables.

### Example: Integrating with Legacy Banking System (MySQL)

```sql
-- Install the MySQL foreign data wrapper
CREATE EXTENSION mysql_fdw;

-- Create server connection
CREATE SERVER legacy_mysql_server
FOREIGN DATA WRAPPER mysql_fdw
OPTIONS (host 'legacy-mysql-server.bank.internal', port '3306');

-- Create user mapping
CREATE USER MAPPING FOR postgres
SERVER legacy_mysql_server
OPTIONS (username 'bank_readonly', password 'secret_password');

-- Create foreign table for legacy customer data
CREATE FOREIGN TABLE legacy_customers (
    id INT,
    name TEXT,
    ssn TEXT,
    old_account_number TEXT,
    account_open_date DATE
)
SERVER legacy_mysql_server
OPTIONS (dbname 'legacy_banking', table_name 'customers');

-- Join with current system data
CREATE VIEW customer_complete_view AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.email,
    lc.ssn,
    lc.old_account_number AS legacy_account_number,
    lc.account_open_date AS legacy_account_opened
FROM
    customers c
LEFT JOIN
    legacy_customers lc ON c.last_name = split_part(lc.name, ' ', -1)
                       AND c.first_name = split_part(lc.name, ' ', 1);
```

### Example: MongoDB Integration for Customer Analytics

```sql
-- Install MongoDB foreign data wrapper
CREATE EXTENSION mongo_fdw;

-- Create server connection
CREATE SERVER mongodb_server
FOREIGN DATA WRAPPER mongo_fdw
OPTIONS (address 'analytics-mongodb.bank.internal', port '27017');

-- Create user mapping
CREATE USER MAPPING FOR postgres
SERVER mongodb_server
OPTIONS (username 'analytics_reader', password 'analytics_pass');

-- Create foreign table for customer behavior data
CREATE FOREIGN TABLE customer_behaviors (
    customer_uuid UUID,
    last_login TIMESTAMP,
    session_count INTEGER,
    average_session_time NUMERIC,
    common_transactions JSONB,
    risk_score NUMERIC
)
SERVER mongodb_server
OPTIONS (database 'banking_analytics', collection 'customer_behaviors');

-- Create an enriched customer view
CREATE VIEW customer_risk_profile AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.email,
    cb.risk_score,
    cb.last_login,
    cb.common_transactions,
    jsonb_array_length(cb.common_transactions) AS transaction_type_count
FROM
    customers c
LEFT JOIN
    customer_behaviors cb ON c.customer_id = cb.customer_uuid;
```

### Benefits for Banking Applications:

- Seamless integration with other banking systems
- Gradual migration from legacy systems
- Access to specialized database systems (analytics, document stores, etc.)
- Single point of access for disparate data sources
