# 1. Composite Types & Domains: Using Custom Types for Reusable Schema Components

## What are Composite Types?

Composite types in PostgreSQL allow you to `define custom data structures that bundle multiple fields together`. Think of them as creating your own data types that combine multiple attributes into a single unit, similar to structs in C or record types in other languages.

## What are Domains?

`Domains are user-defined data types with constraints`. They're essentially basic types with additional validation rules, making them perfect for standardizing specific data formats across your database.

## Benefits of Using Composite Types and Domains

1. **Code Reusability**: Define a structure once and use it in multiple tables
2. **Data Integrity**: Enforce consistent data formats across your database
3. **Simplified Queries**: Group related fields logically
4. **Maintainability**: Change the structure in one place instead of updating multiple tables

## Example Implementation for Banking DB

Let's enhance your banking schema with composite types and domains:

```sql
-- Address composite type for consistent address formatting
CREATE TYPE address_type AS (
    street TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT
);

-- Money domain with currency validation
CREATE DOMAIN money_amount AS NUMERIC(18,2)
    CHECK (VALUE >= 0);

-- Email domain with email format validation
CREATE DOMAIN email_address AS TEXT
    CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

-- Phone number domain with format validation
CREATE DOMAIN phone_number AS TEXT
    CHECK (VALUE ~ '^\+?[0-9]{10,15}$');

-- Account number domain with specific format
CREATE DOMAIN bank_account_number AS TEXT
    CHECK (VALUE ~ '^[A-Z]{2}[0-9]{16}$');

-- Customer status type
CREATE TYPE customer_status AS ENUM ('Active', 'Inactive', 'Suspended', 'Closed');

-- Transaction status with lifecycle states
CREATE TYPE transaction_status AS ENUM ('Initiated', 'Pending', 'Processing', 'Completed', 'Failed', 'Reversed');

-- Customer contact information composite type
CREATE TYPE contact_info AS (
    email email_address,
    phone phone_number,
    alternative_phone phone_number,
    preferred_contact TEXT
);
```

Now, let's modify your banking schema to use these custom types:

```sql
-- Modified Customers Table with composite types and domains
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    contact contact_info,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
    address address_type,
    preferences HSTORE,
    kyc_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    status customer_status DEFAULT 'Active',
    tags TEXT[],
    account_flags HSTORE,
    referred_by UUID REFERENCES customers(customer_id)
);

-- Modified Bank Accounts Table
CREATE TABLE bank_accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id),
    account_number bank_account_number NOT NULL,
    account_type TEXT CHECK (account_type IN ('Saving', 'Checking', 'Loan')),
    balance money_amount DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    status TEXT DEFAULT 'Active',
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ,
    overdraft_limit money_amount DEFAULT 0,
    interest_rate NUMERIC(5,2),
    terms_and_conditions JSONB,
    transaction_limits JSONB,
    features TEXT[],
    alerts_enabled BOOLEAN DEFAULT TRUE,
    extra_meta HSTORE
);
```

## Working with Composite Types

To access fields in a composite type:

```sql
-- Insert a customer with composite type fields
INSERT INTO customers (
    first_name,
    last_name,
    contact,
    address
) VALUES (
    'John',
    'Doe',
    ROW('john.doe@example.com', '+12025550179', NULL, 'email')::contact_info,
    ROW('123 Main St', 'New York', 'NY', '10001', 'USA')::address_type
);

-- Query accessing composite type fields
SELECT
    first_name,
    last_name,
    (contact).email,
    (contact).preferred_contact,
    (address).city,
    (address).country
FROM customers
WHERE (address).postal_code = '10001';
```

## Creating Table Hierarchies with Inheritance

PostgreSQL also supports table inheritance, which is useful for specialized account types:

```sql
-- Base account features
CREATE TABLE base_bank_account (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id),
    account_number bank_account_number NOT NULL,
    balance money_amount DEFAULT 0.0,
    status customer_status DEFAULT 'Active',
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

-- Savings account specific features
CREATE TABLE savings_account (
    interest_rate NUMERIC(5,2) NOT NULL,
    minimum_balance money_amount DEFAULT 0,
    withdrawal_limit INTEGER
) INHERITS (base_bank_account);

-- Checking account specific features
CREATE TABLE checking_account (
    overdraft_limit money_amount DEFAULT 0,
    monthly_fee money_amount DEFAULT 0
) INHERITS (base_bank_account);

-- Loan account specific features
CREATE TABLE loan_account (
    principal_amount money_amount NOT NULL,
    interest_rate NUMERIC(5,2) NOT NULL,
    term_months INTEGER NOT NULL,
    payment_day INTEGER CHECK (payment_day BETWEEN 1 AND 31),
    collateral JSONB
) INHERITS (base_bank_account);
```

By implementing these advanced PostgreSQL features, your banking application gains powerful querying capabilities, improved data organization, and better search functionality - all while maintaining a clean, maintainable schema design.
