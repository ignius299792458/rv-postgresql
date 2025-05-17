## 3. Stored Procedures & Triggers

PL/pgSQL allows you to create custom functions, procedures, and triggers to enhance database functionality.

### Example: Account Transfer Procedure with Validation

```sql
CREATE OR REPLACE PROCEDURE transfer_funds(
    from_account_id UUID,
    to_account_id UUID,
    transfer_amount NUMERIC,
    transfer_description TEXT,
    out success BOOLEAN,
    out message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    from_account_balance NUMERIC;
    from_account_currency TEXT;
    to_account_currency TEXT;
    from_account_status TEXT;
    to_account_status TEXT;
    new_transfer_id UUID;
BEGIN
    success := FALSE;

    -- Check accounts exist and are active
    SELECT balance, currency, status INTO from_account_balance, from_account_currency, from_account_status
    FROM bank_accounts
    WHERE account_id = from_account_id;

    IF NOT FOUND THEN
        message := 'Source account not found';
        RETURN;
    END IF;

    SELECT currency, status INTO to_account_currency, to_account_status
    FROM bank_accounts
    WHERE account_id = to_account_id;

    IF NOT FOUND THEN
        message := 'Destination account not found';
        RETURN;
    END IF;

    -- Validate account statuses
    IF from_account_status != 'Active' THEN
        message := 'Source account is not active';
        RETURN;
    END IF;

    IF to_account_status != 'Active' THEN
        message := 'Destination account is not active';
        RETURN;
    END IF;

    -- Validate amount
    IF transfer_amount <= 0 THEN
        message := 'Transfer amount must be positive';
        RETURN;
    END IF;

    -- Check sufficient funds
    IF from_account_balance < transfer_amount THEN
        message := 'Insufficient funds';
        RETURN;
    END IF;

    -- Check same currency or handle conversion
    IF from_account_currency != to_account_currency THEN
        message := 'Currency mismatch - conversion not supported in this procedure';
        RETURN;
    END IF;

    -- Begin transaction
    BEGIN
        -- Deduct from source
        UPDATE bank_accounts
        SET balance = balance - transfer_amount
        WHERE account_id = from_account_id;

        -- Add to destination
        UPDATE bank_accounts
        SET balance = balance + transfer_amount
        WHERE account_id = to_account_id;

        -- Record transfer
        INSERT INTO fund_transfers (
            from_account,
            to_account,
            amount,
            status,
            remarks,
            transfer_mode
        )
        VALUES (
            from_account_id,
            to_account_id,
            transfer_amount,
            'Completed',
            transfer_description,
            'Online'
        )
        RETURNING transfer_id INTO new_transfer_id;

        -- Record transactions
        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            status,
            description,
            reference_id
        )
        VALUES (
            from_account_id,
            'Transfer',
            -transfer_amount,
            'Completed',
            'Transfer to account: ' || to_account_id,
            new_transfer_id::TEXT
        );

        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            status,
            description,
            reference_id
        )
        VALUES (
            to_account_id,
            'Transfer',
            transfer_amount,
            'Completed',
            'Transfer from account: ' || from_account_id,
            new_transfer_id::TEXT
        );

        success := TRUE;
        message := 'Transfer completed successfully';

        -- Commit happens automatically at the end of the procedure
    EXCEPTION WHEN OTHERS THEN
        -- An error occurred, transaction will be rolled back
        success := FALSE;
        message := 'Transfer failed: ' || SQLERRM;
    END;
END;
$$;
```

### Example: Automatic Transaction Flagging Trigger

```sql
-- Function for the trigger
CREATE OR REPLACE FUNCTION flag_suspicious_transactions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    daily_total NUMERIC;
    account_avg NUMERIC;
    transaction_count INTEGER;
BEGIN
    -- Check if this is a large transaction (over $10,000)
    IF NEW.amount >= 10000 THEN
        NEW.is_flagged := TRUE;
        NEW.metadata := jsonb_set(COALESCE(NEW.metadata, '{}'::jsonb), '{flag_reason}', '"Large transaction amount"'::jsonb);
    END IF;

    -- Calculate daily total for this account
    SELECT COALESCE(SUM(amount), 0) INTO daily_total
    FROM transactions
    WHERE account_id = NEW.account_id
      AND created_at >= CURRENT_DATE
      AND created_at < CURRENT_DATE + INTERVAL '1 day'
      AND transaction_id != NEW.transaction_id;

    -- Add current transaction
    daily_total := daily_total + NEW.amount;

    -- If daily total exceeds $25,000, flag the transaction
    IF daily_total >= 25000 THEN
        NEW.is_flagged := TRUE;
        NEW.metadata := jsonb_set(COALESCE(NEW.metadata, '{}'::jsonb), '{flag_reason}', '"Daily transaction limit exceeded"'::jsonb);
    END IF;

    -- Check for multiple transactions in short period
    SELECT COUNT(*) INTO transaction_count
    FROM transactions
    WHERE account_id = NEW.account_id
      AND created_at >= NOW() - INTERVAL '1 hour'
      AND transaction_id != NEW.transaction_id;

    IF transaction_count >= 5 THEN
        NEW.is_flagged := TRUE;
        NEW.metadata := jsonb_set(COALESCE(NEW.metadata, '{}'::jsonb), '{flag_reason}', '"Multiple transactions in short period"'::jsonb);
    END IF;

    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER flag_suspicious_transactions_trigger
BEFORE INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION flag_suspicious_transactions();
```

### Example: Automatic Account Status Update Trigger

```sql
-- Function to update account status based on balance
CREATE OR REPLACE FUNCTION update_account_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- If balance falls below zero and account doesn't have sufficient overdraft
    IF NEW.balance < 0 AND ABS(NEW.balance) > NEW.overdraft_limit THEN
        -- Set account to "Overdrawn" status
        NEW.status := 'Overdrawn';

        -- Add to account flags
        NEW.extra_meta := COALESCE(NEW.extra_meta, ''::hstore) || hstore('last_overdrawn', NOW()::text);
        NEW.extra_meta := NEW.extra_meta || hstore('overdrawn_amount', ABS(NEW.balance)::text);
    END IF;

    -- If balance was negative but now positive, restore active status
    IF OLD.balance < 0 AND NEW.balance >= 0 AND OLD.status = 'Overdrawn' THEN
        NEW.status := 'Active';
        NEW.extra_meta := COALESCE(NEW.extra_meta, ''::hstore) || hstore('last_overdrawn_recovered', NOW()::text);
    END IF;

    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER update_account_status_trigger
BEFORE UPDATE OF balance ON bank_accounts
FOR EACH ROW
WHEN (OLD.balance IS DISTINCT FROM NEW.balance)
EXECUTE FUNCTION update_account_status();
```

### Benefits for Banking Applications:

- Enforced business rules at the database level
- Improved data integrity and validation
- Automated financial processes
- Reduced risk of inconsistent states during transactions
- Centralized business logic accessible from any application
