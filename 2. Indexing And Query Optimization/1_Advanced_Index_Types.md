# 1. Advanced Index Types

1.  `B-Trees` indexes
2.  `Hash` indexes
3.  `GIN` indexes
4.  `GiST` indexes
5.  `BRIN` indexes
6.  `SP-GiST` indexes

PostgreSQL offers multiple specialized index types, each optimized for different data patterns and query requirements. Understanding when to use each type is crucial for database performance.

## `1. B-Tree Indexes`

B-Tree is PostgreSQL's default and most versatile index type, ideal for equality and range queries on sortable data.

**Characteristics:**

- **Balanced tree structure**: Maintains equal depth for all leaf nodes
- **Self-balancing**: Automatically reorganizes as data changes
- **Supports**: Equality (`=`), range (`<`, `<=`, `>`, `>=`), BETWEEN, IN, IS NULL, and pattern matching with LIKE (if pattern starts with a constant)

**When to use:**

- For columns frequently used in WHERE, JOIN, and ORDER BY clauses
- For uniqueness constraints
- For most general-purpose indexing needs

**Example in Banking DB:**

```sql
-- Basic B-Tree index on transaction amount (already exists on PRIMARY KEY and UNIQUE columns)
CREATE INDEX idx_transactions_amount ON transactions USING btree (amount);

-- Multi-column B-Tree index for queries that filter by account and date range
CREATE INDEX idx_transactions_account_date ON transactions USING btree (account_id, created_at);

-- Index to optimize sorting by transaction date
CREATE INDEX idx_transactions_date_desc ON transactions USING btree (created_at DESC);
```

**Query examples where B-Tree shines:**

```sql
-- Range query on transaction amount
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE amount BETWEEN 1000 AND 5000;

-- Range query on dates with account filter
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE account_id = '123e4567-e89b-12d3-a456-426614174000'
AND created_at BETWEEN '2023-01-01' AND '2023-01-31';

-- Query with ORDER BY that can use the index for sorting
EXPLAIN ANALYZE
SELECT * FROM transactions
ORDER BY created_at DESC
LIMIT 100;
```

## `2. Hash Indexes`

Hash indexes use a hash function to transform the indexed column into a bucket number, making them extremely fast for equality comparisons but useless for range queries.

**Characteristics:**

- **Fixed-size buckets**: Uses hash function to map values to buckets
- **Single operation lookup**: O(1) theoretical performance for equality
- **Supports**: Only equality operator (`=`)
- **Does not support**: Range queries, pattern matching, ORDER BY

**When to use:**

- Only for equality comparisons
- When space efficiency is important (can be smaller than B-Tree)
- When you don't need range queries or sorting

**Example in Banking DB:**

```sql
-- Hash index for exact status lookups
CREATE INDEX idx_transactions_status_hash ON transactions USING hash (status);

-- Hash index for payment gateway lookups
CREATE INDEX idx_payments_gateway_hash ON payments USING hash (payment_gateway);
```

**Query examples where Hash indexes shine:**

```sql
-- Equality search on transaction status
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE status = 'Completed';

-- Equality search on payment gateway
EXPLAIN ANALYZE
SELECT * FROM payments
WHERE payment_gateway = 'PayPal';
```

## `3. GIN (Generalized Inverted Index)`

GIN indexes are ideal for composite values where you need to search for elements within the composite structure, such as `arrays, JSONB, HSTORE, or full-text` search.

**Characteristics:**

- **Inverted structure**: Maps elements to the rows containing them
- **Good for many-to-many relationships**: Each indexed value can appear in many rows
- **Excellent for**: Arrays, JSONB, HSTORE, full-text search, and `@>` (contains) operators
- **Higher maintenance cost**: Slower to build and update than B-Tree

**When to use:**

- For searching within complex data types (arrays, JSONB, HSTORE)
- For full-text search with tsvector/tsquery
- When you need to query "does X contain Y" efficiently

**Example in Banking DB:**

```sql
-- GIN index for tags array (finding all transactions with specific tags)
CREATE INDEX idx_transactions_tags_gin ON transactions USING gin (tags);

-- GIN index for searching within JSONB metadata
CREATE INDEX idx_transactions_metadata_gin ON transactions USING gin (metadata jsonb_path_ops);

-- Full-text search index on transaction descriptions
CREATE INDEX idx_transactions_description_fulltext ON transactions
USING gin (to_tsvector('english', description));
```

**Query examples where GIN shines:**

```sql
-- Find transactions with specific tag
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE tags @> ARRAY['suspicious', 'reviewed'];

-- Find transactions with specific JSONB metadata property
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE metadata @> '{"device_type": "mobile"}';

-- Full-text search in transaction descriptions
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE to_tsvector('english', description) @@ to_tsquery('english', 'payment & online');
```

## `3. GiST (Generalized Search Tree)`

GiST provides a flexible framework for implementing various indexing strategies, particularly useful for `geometric data, text similarity, and range types`.

**Characteristics:**

- **Extensible framework**: Supports custom indexing strategies
- **Lossy**: May produce false positives requiring rechecking
- **Good for**: Geometric data types, ranges, text similarity (trigrams)
- **Balance between performance and flexibility**: More versatile than specialized indexes but potentially less efficient

**When to use:**

- For geometric operations (`PostGIS`)
- For range types (`daterange`, `numrange`, etc.)
- For fuzzy text matching (`pg_trgm`)
- When exact match isn't required (approximate `nearest-neighbor searches`)

**Example in Banking DB:**

```sql
-- Enable trigram extension for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- GiST index for fuzzy name matching
CREATE INDEX idx_customers_name_trigram ON customers
USING gist ((first_name || ' ' || last_name) gist_trgm_ops);

-- Range query index for transaction dates
CREATE INDEX idx_transactions_daterange ON transactions
USING gist (tstzrange(created_at, created_at + interval '1 day'));
```

**Query examples where GiST shines:**

```sql
-- Fuzzy search for customer names
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE (first_name || ' ' || last_name) % 'John Smyth';

-- Find transactions within a date range
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE tstzrange(created_at, created_at + interval '1 day') &&
      tstzrange('2023-01-01', '2023-01-03');
```

## `4. BRIN (Block Range Index)`

BRIN is `designed for very large tables where data is naturally ordered, providing a lightweight indexing solution with minimal overhead`.

**Characteristics:**

- **Minimal overhead**: Much smaller than other index types
- **Block-level metadata**: Stores summary info for block ranges
- **Works best**: On naturally ordered data (`timestamptz`, `sequential IDs`)
- **Lower precision**: Excludes blocks that can't contain matches

**When to use:**

- For very large tables (100M+ rows)
- When data is correlated with physical storage order
- When perfect precision isn't required
- When storage overhead is a concern

**Example in Banking DB:**

```sql
-- BRIN index for created_at timestamp (naturally ordered)
CREATE INDEX idx_transactions_created_at_brin ON transactions
USING brin (created_at) WITH (pages_per_range = 128);

-- BRIN index for transaction amounts (if large table with clustered data)
CREATE INDEX idx_transactions_amount_brin ON transactions
USING brin (amount) WITH (pages_per_range = 64);
```

**Query examples where BRIN shines:**

```sql
-- Find transactions in a large date range
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE created_at BETWEEN '2023-01-01' AND '2023-06-30';

-- Range query over large amount range
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE amount > 10000;
```

## `5. SP-GiST (Space-Partitioned Generalized Search Tree)`

SP-GiST is `optimized for non-balanced data structures` like `quad-trees`, `k-d trees`, and `radix trees`, making it excellent for specific types of data.

**Characteristics:**

- **Space-partitioning algorithms**: Divides search space into partitions
- **Good for**: Non-uniform data distributions
- **Optimized for**: Network addresses, points, ranges

**When to use:**

- For IP address ranges (inet type)
- For geometric point data
- For hierarchical structures

**Example in Banking DB:**

```sql
-- Create a column for IP addresses in transactions
ALTER TABLE transactions ADD COLUMN ip_address inet;

-- SP-GiST index for IP address queries
CREATE INDEX idx_transactions_ip_spgist ON transactions USING spgist (ip_address);
```

**Query examples where SP-GiST shines:**

```sql
-- Find transactions from a specific IP subnet
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE ip_address << '192.168.1.0/24';
```
