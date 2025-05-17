# **Data Types**

## 🧠 0. Introduction to SQL Data Types

In SQL, **data types define the kind of data** a column, variable, or expression can hold. Choosing the right data type:

- Saves storage space.
- Improves performance.
- Enforces data integrity.

SQL data types vary slightly across **RDBMS** (e.g., PostgreSQL, MySQL, SQL Server, Oracle), but standard types are defined in **SQL:2016** (latest major ISO standard).

---

## 📊 1. Main Categories of SQL Data Types

| Category                    | Description                              |
| --------------------------- | ---------------------------------------- |
| **Numeric**                 | Integer, fixed-point, and floating-point |
| **Character/String**        | Fixed or variable length text            |
| **Date/Time**               | Dates, times, intervals                  |
| **Boolean**                 | True/False                               |
| **Binary**                  | Raw binary data                          |
| **Enumerated/User-defined** | Custom types or enums                    |
| **JSON/XML**                | Semi-structured types                    |
| **Spatial/Geometric**       | GIS types (PostGIS, MySQL Spatial, etc.) |

---

## 🔢 2. Numeric Data Types

### A. Integer Types

| Type            | Storage | Range (signed)                  |
| --------------- | ------- | ------------------------------- |
| `TINYINT`       | 1 byte  | -128 to 127 (or 0 to 255)       |
| `SMALLINT`      | 2 bytes | -32,768 to 32,767               |
| `INT`/`INTEGER` | 4 bytes | -2,147,483,648 to 2,147,483,647 |
| `BIGINT`        | 8 bytes | ±9.2 quintillion                |

#### Notes:

- Use `UNSIGNED` (MySQL) to shift to 0 and double upper bound.
- Avoid `INT` when values fit in `SMALLINT` for better performance.

---

### B. Decimal/Fixed-Point Types

| Type           | Description                                         |
| -------------- | --------------------------------------------------- |
| `DECIMAL(p,s)` | Fixed precision. `p` = total digits, `s` = decimals |
| `NUMERIC(p,s)` | Same as `DECIMAL`, with stricter rounding rules     |

#### Example:

```sql
price DECIMAL(10, 2) -- Max: 99999999.99
```

Used in **financial and scientific** applications for precise values.

---

### C. Floating-Point Types

| Type                        | Description                      |
| --------------------------- | -------------------------------- |
| `FLOAT(p)`                  | Approx. `p` = precision in bits  |
| `REAL`                      | Often 4 bytes (like `FLOAT(24)`) |
| `DOUBLE`/`DOUBLE PRECISION` | 8 bytes (like `FLOAT(53)`)       |

**Caution**: Not exact; avoid for money.

---

## 📝 3. Character Data Types

| Type                | Description                                 |
| ------------------- | ------------------------------------------- |
| `CHAR(n)`           | Fixed-length string (padded with spaces)    |
| `VARCHAR(n)`        | Variable-length string up to `n` characters |
| `TEXT` (PostgreSQL) | Unlimited-length text (not SQL standard)    |

#### Comparisons:

| Type         | Storage Overhead | Performance             | Use Case            |
| ------------ | ---------------- | ----------------------- | ------------------- |
| `CHAR(n)`    | Predictable      | Fast in fixed-size rows | Codes (e.g., 'Y/N') |
| `VARCHAR(n)` | Dynamic          | Slightly slower         | Names, titles       |
| `TEXT`       | Fully dynamic    | Slower for indexed ops  | Long content        |

---

## 🗓️ 4. Date & Time Data Types

| Type        | Description                                |
| ----------- | ------------------------------------------ |
| `DATE`      | YYYY-MM-DD                                 |
| `TIME`      | HH\:MM\:SS (optionally with timezone)      |
| `TIMESTAMP` | Date + time (optionally with timezone)     |
| `INTERVAL`  | Time span (e.g., `1 day`, `2 hours`)       |
| `DATETIME`  | Used in MySQL; like `TIMESTAMP` without TZ |

### Best Practices:

- Use `TIMESTAMP WITH TIME ZONE` in distributed systems.
- Store times in **UTC**, display in local time via app logic.

---

## ✅ 5. Boolean Data Type

| Type      | Values                  |
| --------- | ----------------------- |
| `BOOLEAN` | `TRUE`, `FALSE`, `NULL` |

### Notes:

- In MySQL: often stored as `TINYINT(1)`.
- PostgreSQL supports `BOOLEAN` natively.

---

## 🧬 6. Binary Data Types

Used for storing **raw data** like images, encrypted data, or files.

| Type                 | Description                     |
| -------------------- | ------------------------------- |
| `BINARY(n)`          | Fixed-length binary             |
| `VARBINARY(n)`       | Variable-length binary          |
| `BLOB`               | Binary Large Object (up to GBs) |
| `BYTEA` (PostgreSQL) | Variable-length binary          |

**Use case**: Store **file metadata in DB**, actual binary in blob storage (e.g., S3).

---

## 🧾 7. Enumerated & Custom Types

### ENUM

Defined list of valid strings.

```sql
CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');
```

- Fast comparisons (internally stored as integers)
- Supported in PostgreSQL and MySQL
- Not portable across all DBs

### Custom/User-Defined Types

- PostgreSQL allows custom composite types.

---

## 🌐 8. JSON / XML Data Types

### JSON

| DBMS       | JSON Type       | Features                              |
| ---------- | --------------- | ------------------------------------- |
| PostgreSQL | `JSON`, `JSONB` | `JSONB` is binary format, indexable   |
| MySQL      | `JSON`          | Validates and stores in binary format |

```sql
data JSONB
```

### Use JSON when:

- Schema flexibility is required.
- Avoid over-normalizing.
- You use document-based querying.

---

## 🌍 9. Spatial & Geometric Types

For GIS applications.

- `POINT`, `LINESTRING`, `POLYGON`, etc.
- PostGIS (PostgreSQL), MySQL Spatial Extensions.

```sql
location GEOGRAPHY(POINT, 4326)
```

---

## 📏 10. Storage Size & Alignment

Understanding internal representation is **crucial for optimization**.

| Type            | Typical Size                           |
| --------------- | -------------------------------------- |
| `INT`           | 4 bytes                                |
| `BIGINT`        | 8 bytes                                |
| `DECIMAL(10,2)` | \~5-8 bytes                            |
| `VARCHAR(255)`  | 1–255 + length byte(s)                 |
| `TEXT`          | Dynamic (external TOAST in PostgreSQL) |

---

## 🛠️ 11. Constraints Related to Data Types

- **NOT NULL**
- **DEFAULT**
- **CHECK** (e.g., `CHECK (age > 0)`)
- **ENUM constraints**
- **UNIQUE / PRIMARY KEY** (must be deterministic and indexable)

---

## 🔮 12. Choosing the Right Data Type

| Data Type   | When to Use                           |
| ----------- | ------------------------------------- |
| `INT`       | IDs, counters                         |
| `BIGINT`    | Very large IDs                        |
| `DECIMAL`   | Monetary values                       |
| `FLOAT`     | Scientific calculations, measurements |
| `VARCHAR`   | Human-readable text                   |
| `BOOLEAN`   | Flags, toggles                        |
| `TIMESTAMP` | Logs, audit trails                    |
| `JSONB`     | Dynamic schemas                       |
| `ENUM`      | Finite list of categories             |

---

## 🧪 13. Advanced Tips for Production Systems

- Use **UUID** or `BIGINT` as primary keys for distributed systems.
- Use **domain types** (PostgreSQL) to wrap constraints around base types.
- Normalize fixed-length codes; denormalize for performance later if needed.
- Avoid large `TEXT` in hot tables; store in cold or blob storage.
- Be cautious with default values—especially `CURRENT_TIMESTAMP` for time zones.

---

## 📚 14. RDBMS-Specific Extensions

| DBMS           | Special Data Types                         |
| -------------- | ------------------------------------------ |
| **PostgreSQL** | `JSONB`, `ARRAY`, `UUID`, `INET`, `CIDR`   |
| **MySQL**      | `SET`, `ENUM`, `JSON`                      |
| **SQL Server** | `MONEY`, `UNIQUEIDENTIFIER`, `HIERARCHYID` |
| **Oracle**     | `CLOB`, `BLOB`, `INTERVAL`                 |

---

## 📦 15. Example: Schema Using Rich Data Types

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    birth_date DATE,
    profile JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT TRUE
);
```

---

## 🚀 Summary

| Concept                  | Key Point                                                 |
| ------------------------ | --------------------------------------------------------- |
| Data Type Choice         | Impacts performance, accuracy, and integrity              |
| Precision vs Performance | Use fixed types for precision, float for speed            |
| Text Types               | Use `VARCHAR` for variable, `TEXT` for large unstructured |
| Time Types               | Always store timestamps in UTC                            |
| JSON                     | Ideal for flexible schemas; use with caution              |
| ENUM/Custom Types        | Useful for clarity and correctness                        |
