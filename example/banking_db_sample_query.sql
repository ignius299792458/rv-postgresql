--- insertion cmds

-- \d+ customers
--                                                          Table "public.customers"
--     Column     |           Type           | Collation | Nullable |      Default      | Storage  | Compression | Stats target | Description 
-- ---------------+--------------------------+-----------+----------+-------------------+----------+-------------+--------------+-------------
--  customer_id   | uuid                     |           | not null | gen_random_uuid() | plain    |             |              | 
--  first_name    | text                     |           | not null |                   | extended |             |              | 
--  last_name     | text                     |           | not null |                   | extended |             |              | 
--  email         | text                     |           | not null |                   | extended |             |              | 
--  phone         | text                     |           |          |                   | extended |             |              | 
--  date_of_birth | date                     |           |          |                   | plain    |             |              | 
--  gender        | text                     |           |          |                   | extended |             |              | 
--  address       | jsonb                    |           |          |                   | extended |             |              | 
--  preferences   | hstore                   |           |          |                   | extended |             |              | 
--  kyc_status    | boolean                  |           |          | false             | plain    |             |              | 
--  created_at    | timestamp with time zone |           |          | now()             | plain    |             |              | 
--  updated_at    | timestamp with time zone |           |          | now()             | plain    |             |              | 
--  is_active     | boolean                  |           |          | true              | plain    |             |              | 
--  tags          | text[]                   |           |          |                   | extended |             |              | 
--  account_flags | hstore                   |           |          |                   | extended |             |              | 
--  referred_by   | uuid                     |           |          |                   | plain    |             |              | 

insert into customers (first_name, last_name, email, phone, date_of_birth, gender, address, preferences, tags, account_flags, referred_by)
values
('John', 'Wick', 'nw@nw.winner', '+1111111111111', '1999-09-09', 'Male',  '{"zip":1000, "city":"New York", "street":"999 Beckham"}', '"currency"=>"USD", "language"=>"eu"',
ARRAY['premium', 'newsletters'], '"vip"=>"false", "verified"=>"true"', 'fbcc1147-e865-4c4e-a83e-767009875bf3');


-- \d+ bank_accounts
--                                                            Table "public.bank_accounts"
--         Column        |           Type           | Collation | Nullable |      Default      | Storage  | Compression | Stats target | Description 
-- ----------------------+--------------------------+-----------+----------+-------------------+----------+-------------+--------------+-------------
--  account_id           | uuid                     |           | not null | gen_random_uuid() | plain    |             |              | 
--  customer_id          | uuid                     |           | not null |                   | plain    |             |              | 
--  account_number       | text                     |           | not null |                   | extended |             |              | 
--  account_type         | text                     |           |          |                   | extended |             |              | 
--  balance              | numeric(18,2)            |           |          | 0.0               | main     |             |              | 
--  currency             | text                     |           |          | 'USD'::text       | extended |             |              | 
--  status               | text                     |           |          | 'Active'::text    | extended |             |              | 
--  opened_at            | timestamp with time zone |           |          | now()             | plain    |             |              | 
--  closed_at            | timestamp with time zone |           |          |                   | plain    |             |              | 
--  overdraft_limit      | numeric(10,2)            |           |          | 0                 | main     |             |              | 
--  interest_rate        | numeric(5,2)             |           |          |                   | main     |             |              | 
--  terms_and_conditions | jsonb                    |           |          |                   | extended |             |              | 
--  transaction_limits   | jsonb                    |           |          |                   | extended |             |              | 
--  features             | text[]                   |           |          |                   | extended |             |              | 
--  alerts_enabled       | boolean                  |           |          | true              | plain    |             |              | 
--  extra_meta           | hstore                   |           |          |                   | extended |             |              | 

insert into bank_accounts (customer_id, account_number, account_type, balance, currency, status, interest_rate, terms_and_conditions, transaction_limits, 
features, alerts_enabled, extra_meta) values
('8161a5d5-896b-498f-b383-95d6981def8d', '3453234245524532', 'Saving', '458924.90', 'USD', 'Active', 4.5, '{
  "url": "https://bank.com/terms/v1.2",
  "version": "v1.2"
}', '{
  "daily_limit": 5000,
  "monthly_limit": 100000
}', ARRAY['online-banking', 'mobile-banking', 'email', 'credit-card', 'master-card'], true, '"branch"=>"East Lisatown", "manager"=>"Joshua"');

-- \d+ bank_employees
--                                                                                   Table "public.bank_employees"
--               Column               |           Type           | Collation | Nullable |                       Default                       | Storage  | Compression | Stats target | Description
 
-- -----------------------------------+--------------------------+-----------+----------+-----------------------------------------------------+----------+-------------+--------------+------------
-- -
--  employee_id                       | uuid                     |           | not null | gen_random_uuid()                                   | plain    |             |              | 
--  first_name                        | text                     |           | not null |                                                     | extended |             |              | 
--  last_name                         | text                     |           | not null |                                                     | extended |             |              | 
--  official_email                    | text                     |           | not null |                                                     | extended |             |              | 
--  official_ph_no                    | text                     |           | not null |                                                     | extended |             |              | 
--  date_of_birth                     | date                     |           | not null |                                                     | plain    |             |              | 
--  gender                            | text                     |           |          |                                                     | extended |             |              | 
--  address                           | jsonb                    |           |          |                                                     | extended |             |              | 
--  preference                        | hstore                   |           |          |                                                     | extended |             |              | 
--  kye_status                        | boolean                  |           |          | false                                               | plain    |             |              | 
--  created_at                        | timestamp with time zone |           |          | now()                                               | plain    |             |              | 
--  updated_at                        | timestamp with time zone |           |          | now()                                               | plain    |             |              | 
--  is_active                         | boolean                  |           |          | true                                                | plain    |             |              | 
--  tags                              | text[]                   |           |          |                                                     | extended |             |              | 
--  secret_code                       | integer                  |           | not null | nextval('bank_employees_secret_code_seq'::regclass) | plain    |             |              | 
--  post                              | text                     |           | not null |                                                     | extended |             |              | 
--  privilege                         | text[]                   |           | not null |                                                     | extended |             |              | 
--  working_branch                    | text                     |           | not null |                                                     | extended |             |              | 
--  no_of_verified_customers_under_me | integer                  |           |          | 0                                                   | plain    |             |              | 

insert into bank_employees
(first_name, last_name, official_email, official_ph_no, date_of_birth, gender, address, preference, kye_status, tags, post, privilege, working_branch,
no_of_verified_customers_under_me)
values
('johni22', 'wick3', 'jh22@ex.com', '+13423242424234', '1979-04-02', 'Other', '{"zip":104204, "city":"Old WS", "street":"243 Dd 253 House"}', 
'"former"=>False, "record"=>"closed"', True, ARRAY['Manager', 'Exective'], 'Branch_Manager', ARRAY['TEMP_REVOKED'], 'TEXAS', 4530);




-- \d+ fund_transfers
--                                                         Table "public.fund_transfers"
--       Column      |           Type           | Collation | Nullable |      Default      | Storage  | Compression | Stats target | Description 
-- ------------------+--------------------------+-----------+----------+-------------------+----------+-------------+--------------+-------------
--  transfer_id      | uuid                     |           | not null | gen_random_uuid() | plain    |             |              | 
--  from_account     | uuid                     |           | not null |                   | plain    |             |              | 
--  to_account       | uuid                     |           | not null |                   | plain    |             |              | 
--  initiated_by     | uuid                     |           |          |                   | plain    |             |              | 
--  amount           | numeric(18,2)            |           | not null |                   | main     |             |              | 
--  status           | text                     |           |          |                   | extended |             |              | 
--  initiated_at     | timestamp with time zone |           |          | now()             | plain    |             |              | 
--  completed_at     | timestamp with time zone |           |          |                   | plain    |             |              | 
--  remarks          | text                     |           |          |                   | extended |             |              | 
--  transfer_mode    | text                     |           |          |                   | extended |             |              | 
--  metadata         | jsonb                    |           |          |                   | extended |             |              | 
--  approvals        | hstore                   |           |          |                   | extended |             |              | 
--  audit_log        | jsonb                    |           |          |                   | extended |             |              | 
--  tags             | text[]                   |           |          |                   | extended |             |              | 
--  is_international | boolean                  |           |          | false             | plain    |             |              | 
--  conversion_rate  | numeric(10,4)            |           |          |                   | main     |             |              | 
-- Indexes:
--     "fund_transfers_pkey" PRIMARY KEY, btree (transfer_id)
--     "idx_fund_transfers_metadata" gin (metadata)
-- Check constraints:
--     "fund_transfers_status_check" CHECK (status = ANY (ARRAY['Initiated'::text, 'Processing'::text, 'Completed'::text, 'Failed'::text]))
--     "fund_transfers_transfer_mode_check" CHECK (transfer_mode = ANY (ARRAY['Online'::text, 'In-Branch'::text, 'Mobile App'::text]))
-- Foreign-key constraints:
--     "fund_transfers_from_account_fkey" FOREIGN KEY (from_account) REFERENCES bank_accounts(account_id)
--     "fund_transfers_initiated_by_fkey" FOREIGN KEY (initiated_by) REFERENCES customers(customer_id)
--     "fund_transfers_to_account_fkey" FOREIGN KEY (to_account) REFERENCES bank_accounts(account_id)

insert into fund_transfers
(from_account, to_account, initiated_by, amount, status, completed_at, remarks, transfer_mode, metadata, approvals, conversion_rate) 
values
('d88d986f-daa0-457e-9a62-40ed5db9c42e', 'b2a43b23-19e0-430a-b6b3-f24665e36fd1', '1164d3da-cf17-4b8f-9933-2e3450cacd59', 124.44, 'Completed', '2025-05-15 13:40:37.805153+00', 
 'Just Deposition', 'Online', '{"type":"bank-to-bank", "external-banking":"true"}', '"approved"=>True, "by"=>"account_id_no"', 1.0);


--             customer_id              
-- --------------------------------------
--  fbcc1147-e865-4c4e-a83e-767009875bf3
--  8161a5d5-896b-498f-b383-95d6981def8d
--  baa49467-f1ea-45d2-9223-1b2876ceee25b
--  ee9b160e-3249-426e-9692-f090dca22dbd
--  30d2dc70-80d9-488e-a027-a68a4f524977
--  96f34e14-2ae0-416d-9a11-c3268f38a80f
--  db8f78a7-7fe3-4aef-b769-d39736b8ee50
--  5dc25b5b-0e3b-41ef-a97e-8ac8597e66c6
--  f73ff58e-acc3-4bff-baf4-dc4ac68021e5
--  f64934d2-88d9-4d27-a1d3-0350cdb04c7c
--  b759d452-5f50-43a0-bb39-8260437db92f
--  7b5e4728-f23c-49b4-9ccd-48393253e5ef
--  26c32105-46de-4083-bf86-a17abd9c0de9
--  367ffd6b-2880-4690-9e11-70767f22d303
--  dafe5b82-8017-4c8f-9130-efc75c5dbba0
--  63c4b437-a20f-4e93-827b-7b943d6c46e0
--  b9544b0e-f5ea-4737-acf1-38543dca0605