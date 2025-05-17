# 2. Full-Text Search & Array Types: Master the Advanced Ways to Design and Query Data

## Array Types in PostgreSQL

Array types allow you `to store multiple values of the same type in a single column`. This is **extremely useful for implementing `many-to-many relationships` without additional tables, `storing lists of values`, and implementing `tags or categories`**.

## Full-text Search

PostgreSQL's full-text search capabilities allow you to implement sophisticated search functionality across textual data, with features like:

- Language-aware text indexing
- Stemming (finding word variations)
- Ranking and relevance scoring
- Fuzzy matching

## Working with Array Types in Banking DB

Let's enhance your banking database with array types:

```sql
-- Adding more array fields to existing tables
ALTER TABLE customers ADD COLUMN notification_channels TEXT[] DEFAULT '{"email", "sms"}';
ALTER TABLE customers ADD COLUMN interest_categories TEXT[] DEFAULT '{}';
ALTER TABLE bank_accounts ADD COLUMN authorized_users UUID[] DEFAULT '{}';
ALTER TABLE transactions ADD COLUMN categories TEXT[] DEFAULT '{}';
```

## Array Operations and Queries

```sql
-- Insert with array values
INSERT INTO customers (
    first_name,
    last_name,
    email,
    tags,
    notification_channels,
    interest_categories
) VALUES (
    'Jane',
    'Smith',
    'jane@example.com',
    ARRAY['VIP', 'HighNetWorth', 'Investor'],
    ARRAY['email', 'push', 'phone'],
    ARRAY['stocks', 'bonds', 'retirement']
);

-- Find customers with specific tags (contains)
SELECT customer_id, first_name, last_name
FROM customers
WHERE 'VIP' = ANY(tags);

-- Find customers interested in both stocks and bonds (overlaps)
SELECT customer_id, first_name, last_name
FROM customers
WHERE interest_categories && ARRAY['stocks', 'bonds'];

-- Find customers with exact tag set
SELECT customer_id, first_name, last_name
FROM customers
WHERE tags = ARRAY['VIP', 'HighNetWorth', 'Investor'];

-- Find all VIP customers who want phone notifications
SELECT customer_id, first_name, last_name
FROM customers
WHERE 'VIP' = ANY(tags) AND 'phone' = ANY(notification_channels);

-- Add a tag to existing customer
UPDATE customers
SET tags = array_append(tags, 'PremiumService')
WHERE customer_id = '12345678-1234-1234-1234-123456789012';

-- Remove a notification channel
UPDATE customers
SET notification_channels = array_remove(notification_channels, 'sms')
WHERE customer_id = '12345678-1234-1234-1234-123456789012';

-- Count array elements
SELECT customer_id, first_name, last_name, array_length(tags, 1) AS tag_count
FROM customers
ORDER BY tag_count DESC;

-- Unnest array to rows (useful for analytics)
SELECT customer_id, first_name, unnest(interest_categories) AS interest
FROM customers
WHERE 'VIP' = ANY(tags);
```

## Implementing Full-text Search in Banking DB

Let's add full-text search capability to the transaction descriptions and customer information:

```sql
-- First, add tsvector columns to store preprocessed text
ALTER TABLE transactions ADD COLUMN description_tsv TSVECTOR;
ALTER TABLE customers ADD COLUMN customer_info_tsv TSVECTOR;

-- Create function to update tsvector columns
CREATE OR REPLACE FUNCTION update_transaction_tsv() RETURNS TRIGGER AS $$
BEGIN
  NEW.description_tsv = to_tsvector('english', NEW.description);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_customer_tsv() RETURNS TRIGGER AS $$
BEGIN
  NEW.customer_info_tsv = to_tsvector('english',
    NEW.first_name || ' ' ||
    NEW.last_name || ' ' ||
    NEW.email || ' ' ||
    coalesce((NEW.address->>0)::text, '') || ' ' ||
    array_to_string(NEW.tags, ' ')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update tsvector columns
CREATE TRIGGER tsvector_update_transaction BEFORE INSERT OR UPDATE
ON transactions FOR EACH ROW EXECUTE FUNCTION update_transaction_tsv();

CREATE TRIGGER tsvector_update_customer BEFORE INSERT OR UPDATE
ON customers FOR EACH ROW EXECUTE FUNCTION update_customer_tsv();

-- Create GIN indexes for fast full-text search
CREATE INDEX idx_transaction_description_tsv ON transactions USING GIN (description_tsv);
CREATE INDEX idx_customer_info_tsv ON customers USING GIN (customer_info_tsv);
```

## Full-text Search Queries

```sql
-- Simple text search for transactions containing 'mortgage payment'
SELECT transaction_id, description, amount
FROM transactions
WHERE description_tsv @@ to_tsquery('english', 'mortgage & payment');

-- Ranked search results
SELECT transaction_id, description, amount,
       ts_rank(description_tsv, query) AS rank
FROM transactions, to_tsquery('english', 'mortgage & payment') query
WHERE description_tsv @@ query
ORDER BY rank DESC
LIMIT 10;

-- Search with stemming (finds 'pay', 'payment', 'paying', etc.)
SELECT transaction_id, description, amount
FROM transactions
WHERE description_tsv @@ to_tsquery('english', 'pay:*');

-- Advanced search combining full-text and regular conditions
SELECT t.transaction_id, t.description, t.amount, b.account_number
FROM transactions t
JOIN bank_accounts b ON t.account_id = b.account_id
WHERE t.description_tsv @@ to_tsquery('english', 'transfer | deposit')
AND t.amount > 1000
AND t.created_at > now() - interval '30 days'
ORDER BY t.amount DESC;

-- Search customers in New York interested in investments
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE customer_info_tsv @@ to_tsquery('english', 'new & york')
AND 'investments' = ANY(interest_categories);
```

## Combining Arrays with JSONB for Advanced Data Modeling

```sql
-- Let's track customer financial goals
ALTER TABLE customers ADD COLUMN financial_goals JSONB[];

-- Add financial goals for a customer
UPDATE customers
SET financial_goals = ARRAY[
    '{"name": "Retirement", "target_amount": 500000, "target_date": "2045-01-01", "priority": "high"}'::jsonb,
    '{"name": "Home Purchase", "target_amount": 100000, "target_date": "2027-01-01", "priority": "medium"}'::jsonb,
    '{"name": "Emergency Fund", "target_amount": 30000, "target_date": "2026-01-01", "priority": "high"}'::jsonb
]
WHERE customer_id = '12345678-1234-1234-1234-123456789012';

-- Find customers with high-priority retirement goals over $400,000
SELECT customer_id, first_name, last_name
FROM customers,
     jsonb_array_elements(financial_goals) AS goal
WHERE goal->>'name' = 'Retirement'
  AND goal->>'priority' = 'high'
  AND (goal->>'target_amount')::numeric > 400000;
```

## Practical Use Cases for Banking DB

1. **Customer Tags Management**

   ```sql
   -- Add multiple tags at once
   UPDATE customers
   SET tags = array_cat(tags, ARRAY['HNWI', 'InvestmentFocus'])
   WHERE (address).city = 'New York' AND balance > 1000000;

   -- Find common tags between customers
   SELECT c1.customer_id, c2.customer_id,
          (SELECT array_agg(t) FROM unnest(c1.tags) t WHERE t = ANY(c2.tags)) AS common_tags
   FROM customers c1, customers c2
   WHERE c1.customer_id < c2.customer_id
   AND c1.tags && c2.tags;
   ```

2. **Transaction Categorization with Arrays and Full-text Search**

   ```sql
   -- Auto-categorize transactions based on description
   CREATE OR REPLACE FUNCTION categorize_transaction() RETURNS TRIGGER AS $$
   BEGIN
     IF NEW.description_tsv @@ to_tsquery('english', 'grocery | supermarket | food') THEN
       NEW.categories = array_append(NEW.categories, 'Groceries');
     END IF;

     IF NEW.description_tsv @@ to_tsquery('english', 'restaurant | dining | cafe') THEN
       NEW.categories = array_append(NEW.categories, 'Dining');
     END IF;

     IF NEW.description_tsv @@ to_tsquery('english', 'utility | electric | water | gas | internet') THEN
       NEW.categories = array_append(NEW.categories, 'Utilities');
     END IF;

     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   CREATE TRIGGER categorize_transaction BEFORE INSERT OR UPDATE
   ON transactions FOR EACH ROW EXECUTE FUNCTION categorize_transaction();
   ```

3. **Customer Spending Analytics with Arrays**
   ```sql
   -- Get spending by category for a customer
   SELECT unnest(t.categories) AS category, SUM(t.amount) AS total_spent
   FROM transactions t
   JOIN bank_accounts b ON t.account_id = b.account_id
   WHERE b.customer_id = '12345678-1234-1234-1234-123456789012'
   AND t.transaction_type = 'Withdrawal'
   AND t.created_at > now() - interval '3 months'
   GROUP BY category
   ORDER BY total_spent DESC;
   ```

## Best Practices for Using Arrays and Full-text Search

1. **Arrays**

   - Use appropriate indexes (GIN) for arrays when you frequently search within them
   - Be careful with large arrays as they can impact performance
   - Consider performance implications when sorting or joining on array fields

2. **Full-text Search**
   - Always use tsvector columns with triggers for better performance
   - Create appropriate GIN indexes for your search columns
   - Use language-specific dictionaries for better stemming
   - Consider using weights for different fields in composite searches
   - For complex searches, consider using pg_trgm extension for fuzzy matching
