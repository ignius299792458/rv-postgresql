## 4. VACUUM & Autovacuum

PostgreSQL's MVCC (Multi-Version Concurrency Control) system creates multiple versions of rows during updates and deletes. VACUUM is essential for reclaiming space and maintaining index health.

### How MVCC Works

1. **UPDATE/DELETE doesn't immediately remove data**:

   - Old versions remain until no transaction needs them
   - These are called "dead tuples" or "dead rows"

2. **Problems caused by dead tuples**:
   - Increased table and index size
   - Slower sequential scans
   - Index bloat
   - Transaction ID wraparound

### Manual VACUUM Commands

```sql
-- Basic VACUUM (doesn't reclaim space to OS)
VACUUM transactions;

-- VACUUM FULL (reclaims space but locks table)
VACUUM FULL transactions;

-- VACUUM ANALYZE (updates statistics too)
VACUUM ANALYZE transactions;

-- ANALYZE only (updates statistics without vacuum)
ANALYZE transactions;
```

### Autovacuum Configuration

PostgreSQL's autovacuum daemon automatically performs VACUUM and ANALYZE operations based on configuration settings.

**Key autovacuum parameters:**

```sql
-- View current autovacuum settings
SHOW autovacuum;
SHOW autovacuum_vacuum_threshold;
SHOW autovacuum_vacuum_scale_factor;
SHOW autovacuum_analyze_threshold;
SHOW autovacuum_analyze_scale_factor;
SHOW autovacuum_vacuum_cost_delay;
SHOW autovacuum_vacuum_cost_limit;

-- Table-specific autovacuum settings
ALTER TABLE transactions SET (
  autovacuum_vacuum_threshold = 1000,
  autovacuum_vacuum_scale_factor = 0.1,
  autovacuum_analyze_threshold = 500,
  autovacuum_analyze_scale_factor = 0.05
);
```

### Monitoring VACUUM Activity

```sql
-- Check for tables needing vacuum
SELECT
  schemaname,
  relname,
  n_dead_tup,
  n_live_tup,
  n_dead_tup::float / (n_live_tup + n_dead_tup) * 100 AS dead_percentage
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY dead_percentage DESC;

-- Check last vacuum and analyze times
SELECT
  schemaname,
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables;
```

### VACUUM Best Practices for Banking DB

1. **Aggressive autovacuum for transaction tables**:

   ```sql
   -- Set more aggressive autovacuum for high-churn tables
   ALTER TABLE transactions SET (
     autovacuum_vacuum_scale_factor = 0.05,
     autovacuum_vacuum_threshold = 100
   );

   ALTER TABLE fund_transfers SET (
     autovacuum_vacuum_scale_factor = 0.05,
     autovacuum_vacuum_threshold = 100
   );
   ```

2. **Less aggressive for reference tables**:

   ```sql
   -- Set less aggressive autovacuum for stable tables
   ALTER TABLE customers SET (
     autovacuum_vacuum_scale_factor = 0.2,
     autovacuum_vacuum_threshold = 1000
   );
   ```

3. **Schedule manual VACUUM ANALYZE**:
   ```sql
   -- Create a scheduled function for off-peak VACUUM ANALYZE
   CREATE OR REPLACE FUNCTION perform_vacuum_analyze() RETURNS void AS $$
   BEGIN
     VACUUM ANALYZE transactions;
     VACUUM ANALYZE fund_transfers;
     VACUUM ANALYZE payments;
   END;
   $$ LANGUAGE plpgsql;
   ```
