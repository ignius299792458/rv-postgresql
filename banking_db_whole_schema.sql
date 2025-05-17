-- PostgreSQL Schema: Banking DB with Complex Data Types

-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS hstore;

-- 1. Customers Table
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
    address JSONB,
    preferences HSTORE,
    kyc_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT TRUE,
    tags TEXT[],
    account_flags HSTORE,
    referred_by UUID REFERENCES customers(customer_id)
);

-- 2. Bank Accounts Table
CREATE TABLE bank_accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id),
    account_number TEXT UNIQUE NOT NULL,
    account_type TEXT CHECK (account_type IN ('Saving', 'Checking', 'Loan')),
    balance NUMERIC(18,2) DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    status TEXT DEFAULT 'Active',
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ,
    overdraft_limit NUMERIC(10,2) DEFAULT 0,
    interest_rate NUMERIC(5,2),
    terms_and_conditions JSONB,
    transaction_limits JSONB,
    features TEXT[],
    alerts_enabled BOOLEAN DEFAULT TRUE,
    extra_meta HSTORE
);

-- 3. Transactions Table
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES bank_accounts(account_id),
    transaction_type TEXT CHECK (transaction_type IN ('Deposit', 'Withdrawal', 'Transfer', 'Payment')),
    amount NUMERIC(18,2) NOT NULL,
    status TEXT CHECK (status IN ('Pending', 'Completed', 'Failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    description TEXT,
    reference_id TEXT,
    tags TEXT[],
    metadata JSONB,
    audit_trail JSONB,
    device_info HSTORE,
    location JSONB,
    executed_by UUID REFERENCES customers(customer_id),
    is_flagged BOOLEAN DEFAULT FALSE
);

-- 4. Fund Transfers Table
CREATE TABLE fund_transfers (
    transfer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_account UUID NOT NULL REFERENCES bank_accounts(account_id),
    to_account UUID NOT NULL REFERENCES bank_accounts(account_id),
    initiated_by UUID REFERENCES customers(customer_id),
    amount NUMERIC(18,2) NOT NULL,
    status TEXT CHECK (status IN ('Initiated', 'Processing', 'Completed', 'Failed')),
    initiated_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    remarks TEXT,
    transfer_mode TEXT CHECK (transfer_mode IN ('Online', 'In-Branch', 'Mobile App')),
    metadata JSONB,
    approvals HSTORE,
    audit_log JSONB,
    tags TEXT[],
    is_international BOOLEAN DEFAULT FALSE,
    conversion_rate NUMERIC(10,4)
);

-- 5. Payments Table
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payer_account UUID NOT NULL REFERENCES bank_accounts(account_id),
    payee_name TEXT NOT NULL,
    payee_account TEXT,
    amount NUMERIC(18,2) NOT NULL,
    purpose TEXT,
    status TEXT CHECK (status IN ('Scheduled', 'Paid', 'Failed')),
    scheduled_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    currency TEXT DEFAULT 'USD',
    recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule JSONB,
    tags TEXT[],
    contact_details JSONB,
    payment_gateway TEXT,
    gateway_response JSONB,
    error_details HSTORE,
    initiated_by UUID REFERENCES customers(customer_id)
);

-- Indexing strategy for JSONB & HSTORE fields
CREATE INDEX idx_customers_address ON customers USING GIN (address);
CREATE INDEX idx_customers_preferences ON customers USING GIN (preferences);
CREATE INDEX idx_transactions_metadata ON transactions USING GIN (metadata);
CREATE INDEX idx_transactions_audit_trail ON transactions USING GIN (audit_trail);
CREATE INDEX idx_fund_transfers_metadata ON fund_transfers USING GIN (metadata);
CREATE INDEX idx_payments_recurrence_rule ON payments USING GIN (recurrence_rule);
CREATE INDEX idx_payments_error_details ON payments USING GIN (error_details);
