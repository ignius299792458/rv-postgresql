# 🧬 1. JSON vs JSONB

Both `JSON` and `JSONB` allow storing hierarchical, schema-less data like objects or arrays. But there are **critical differences** in **storage, indexing, and performance**.

## JSON

- Stores data **as raw text**.
- Preserves **key order** and duplicates (useful for logs).
- Slower to query and cannot be indexed efficiently.

## JSONB

- **Binary representation** of JSON.
- **Removes whitespace**, **reorders keys**, **removes duplicates** (keeps last).
- **Supports GIN indexing** → much faster querying.
- Preferred for almost all production use.

## Example

```sql
-- JSON
CREATE TABLE events_json (
  id serial PRIMARY KEY,
  payload json
);

-- JSONB
CREATE TABLE events_jsonb (
  id serial PRIMARY KEY,
  payload jsonb
);
```

## Querying JSON/JSONB

```sql
-- Access a key (returns JSON)
SELECT payload->'user' FROM events_jsonb;

-- Access a key's value (as text)
SELECT payload->>'user' FROM events_jsonb;

-- Nested key
SELECT payload->'user'->>'name' FROM events_jsonb;
```

## Indexing JSONB

```sql
-- General key-value presence
CREATE INDEX idx_payload_data ON events_jsonb USING GIN (payload);

-- Specific key
CREATE INDEX idx_user_name ON events_jsonb ((payload->>'user_name'));
```

---

## JSONB Operators

| Operator   | Description                           |                |                   |
| ---------- | ------------------------------------- | -------------- | ----------------- |
| `->`       | Get JSON object by key (returns JSON) |                |                   |
| `->>`      | Get JSON value as text                |                |                   |
| `#>`       | Get nested JSON object                |                |                   |
| `#>>`      | Get nested JSON value as text         |                |                   |
| `@>`       | JSONB contains                        |                |                   |
| `<@`       | JSONB is contained by                 |                |                   |
| `?`        | Key exists                            |                |                   |
| \`?        | \`                                    | Any key exists |                   |
| `?&`       | All keys exist                        |                |                   |
| \`         |                                       | \`             | Concatenate JSONB |
| `-`        | Delete key                            |                |                   |
| `- text[]` | Delete path                           |                |                   |

🧠 **Use `@>` with GIN index** for high-performance key lookups.

```sql
-- Find rows where payload contains {"user": {"name": "Mahesh"}}
SELECT * FROM events_jsonb
WHERE payload @> '{"user": {"name": "Mahesh"}}';
```

---

# 🧃 2. PostgreSQL Arrays

PostgreSQL supports **multi-dimensional arrays** of any base type.

## Declaration

```sql
CREATE TABLE posts (
  id serial PRIMARY KEY,
  tags text[],
  ratings int[]
);
```

## Usage

```sql
-- Insert
INSERT INTO posts (tags, ratings) VALUES
  (ARRAY['db', 'postgres'], ARRAY[5, 4, 5]);

-- Accessing
SELECT tags[1], ratings[2] FROM posts;

-- Append
UPDATE posts SET tags = tags || 'newtag';
```

## Searching in Arrays

```sql
-- Check if array contains value
SELECT * FROM posts WHERE 'postgres' = ANY(tags);

-- Check if array contains ALL values
SELECT * FROM posts WHERE tags @> ARRAY['postgres', 'db'];
```

## Indexing Arrays

Use **GIN indexing** for containment queries:

```sql
CREATE INDEX idx_tags_gin ON posts USING GIN (tags);
```

🧠 Use `ANY()` and `@>` with arrays for performant queries. Avoid using too many large arrays; they can break normalization and increase bloat.

---

# 🏷️ 3. HSTORE: Key-Value Store for Flat Maps

HSTORE is PostgreSQL’s native key-value type. Think of it as a **flat hash map** of strings.

## Enable Extension

```sql
CREATE EXTENSION hstore;
```

## Declaration

```sql
CREATE TABLE product_specs (
  id serial PRIMARY KEY,
  specs hstore
);
```

## Insertion

```sql
INSERT INTO product_specs (specs)
VALUES ('color => red, size => M, weight => 5kg');
```

## Querying

```sql
SELECT specs->'color' FROM product_specs;
SELECT * FROM product_specs WHERE specs ? 'size';
SELECT * FROM product_specs WHERE specs @> 'color => red';
```

## Indexing HSTORE

```sql
CREATE INDEX specs_idx ON product_specs USING GIN (specs);
```

---

# 🧠 JSONB vs HSTORE vs Arrays — When to Use What

| Use Case                        | Best Fit | Why                                      |
| ------------------------------- | -------- | ---------------------------------------- |
| Structured but schema-less data | JSONB    | Hierarchical, rich structure             |
| Simple key-value pairs (flat)   | HSTORE   | Lighter than JSONB, faster for flat k-v  |
| Fixed types, multiple values    | ARRAY    | Simple, fast with `ANY`/`ALL`, type-safe |

---

# ⚖️ Performance Considerations

| Type   | Pros                           | Cons                            |
| ------ | ------------------------------ | ------------------------------- |
| JSON   | Human-readable                 | No indexing, slower             |
| JSONB  | Indexable, queryable, flexible | Slightly heavier write cost     |
| Arrays | Fast, type-safe                | Limited structure, harder joins |
| HSTORE | Fast flat k-v, indexable       | Flat only, no nesting           |

---

# 🔐 Best Practices (Principal-Level)

1. **Use JSONB with GIN index for flexible semi-structured data**.
2. **Avoid storing entire documents in JSONB unless needed** — keep core data in normalized columns.
3. For **flat metadata**, prefer `hstore` if you don’t need hierarchy.
4. Use `ARRAY` for **small, fixed-size lists** — avoid for unbounded or large sets.
5. Always **benchmark with `EXPLAIN (ANALYZE)`** — e.g., JSONB queries vs join-based normalization.

---

# 🛠️ Real-World Example: Event Tracking System

```sql
CREATE TABLE user_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  event_type text NOT NULL,
  event_data jsonb NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now()
);

-- Index on event type
CREATE INDEX idx_event_type ON user_events (event_type);

-- Index for key existence in event_data
CREATE INDEX idx_event_data ON user_events USING GIN (event_data);

-- Query: Find all "purchase" events with payment method "card"
SELECT * FROM user_events
WHERE event_type = 'purchase'
  AND event_data @> '{"payment_method": "card"}';
```
