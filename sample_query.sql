-- Bank Account Insertions with randomly selected customer IDs
INSERT INTO bank_accounts (
    customer_id, 
    account_number, 
    account_type, 
    balance, 
    currency, 
    status, 
    opened_at, 
    closed_at, 
    overdraft_limit, 
    interest_rate, 
    terms_and_conditions, 
    transaction_limits, 
    features, 
    alerts_enabled,
    extra_meta
) VALUES
-- 1
('fbcc1147-e865-4c4e-a83e-767009875bf3', 'ACCT-20250101-0001', 'Checking', 2541.75, 'USD', 'Active', '2025-01-01 08:30:00+00', NULL, 500.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 2000, "weekly": 10000}', ARRAY['online_banking', 'mobile_app', 'bill_pay'], TRUE, 'preferred_customer=>true, relationship_manager=>Jane Smith'),
-- 2
('8161a5d5-896b-498f-b383-95d6981def8d', 'ACCT-20250101-0002', 'Saving', 15750.25, 'USD', 'Active', '2025-01-01 09:15:00+00', NULL, 0.00, 1.25, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers'], TRUE, 'premium_account=>true'),
-- 3
('baa49467-f1ea-45d2-9223-1b2876ceee25', 'ACCT-20250101-0003', 'Loan', -25000.00, 'USD', 'Active', '2025-01-01 10:45:00+00', NULL, 0.00, 4.75, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "60 months"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>vehicle, loan_purpose=>auto'),
-- 4
('ee9b160e-3249-426e-9692-f090dca22dbd', 'ACCT-20250101-0004', 'Checking', 1205.50, 'USD', 'Active', '2025-01-01 11:20:00+00', NULL, 100.00, 0.03, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 1000, "weekly": 5000}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true'),
-- 5
('30d2dc70-80d9-488e-a027-a68a4f524977', 'ACCT-20250102-0005', 'Saving', 42500.75, 'USD', 'Active', '2025-01-02 08:10:00+00', NULL, 0.00, 1.50, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 10000, "weekly": 30000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'vip_customer=>true'),
-- 6
('96f34e14-2ae0-416d-9a11-c3268f38a80f', 'ACCT-20250102-0006', 'Checking', 3700.25, 'USD', 'Active', '2025-01-02 09:30:00+00', NULL, 1000.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 3000, "weekly": 15000}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, NULL),
-- 7
('1164d3da-cf17-4b8f-9933-2e3450cacd59', 'ACCT-20250102-0007', 'Loan', -150000.00, 'USD', 'Active', '2025-01-02 10:15:00+00', NULL, 0.00, 3.25, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "30 years"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>property, loan_purpose=>mortgage'),
-- 8
('db8f78a7-7fe3-4aef-b769-d39736b8ee50', 'ACCT-20250102-0008', 'Saving', 7850.50, 'USD', 'Active', '2025-01-02 14:45:00+00', NULL, 0.00, 1.35, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers', 'goal_savings'], TRUE, NULL),
-- 9
('5dc25b5b-0e3b-41ef-a97e-8ac8597e66c6', 'ACCT-20250103-0009', 'Checking', 925.75, 'USD', 'Active', '2025-01-03 09:10:00+00', NULL, 250.00, 0.01, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 1000, "weekly": 5000}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true'),
-- 10
('f73ff58e-acc3-4bff-baf4-dc4ac68021e5', 'ACCT-20250103-0010', 'Saving', 28750.00, 'USD', 'Active', '2025-01-03 11:30:00+00', NULL, 0.00, 1.40, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 7500, "weekly": 25000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, NULL),
-- 11
('f64934d2-88d9-4d27-a1d3-0350cdb04c7c', 'ACCT-20250103-0011', 'Loan', -75000.00, 'USD', 'Active', '2025-01-03 13:45:00+00', NULL, 0.00, 5.75, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "5 years"}', NULL, ARRAY['autopay'], TRUE, 'collateral=>none, loan_purpose=>personal'),
-- 12
('b759d452-5f50-43a0-bb39-8260437db92f', 'ACCT-20250103-0012', 'Checking', 5420.25, 'USD', 'Active', '2025-01-03 15:20:00+00', NULL, 750.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 4000, "weekly": 20000}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, 'business_account=>true'),
-- 13
('7b5e4728-f23c-49b4-9ccd-48393253e5ef', 'ACCT-20250104-0013', 'Saving', 62300.75, 'USD', 'Active', '2025-01-04 08:30:00+00', NULL, 0.00, 1.60, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 10000, "weekly": 40000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'vip_customer=>true'),
-- 14
('26c32105-46de-4083-bf86-a17abd9c0de9', 'ACCT-20250104-0014', 'Checking', 2150.50, 'USD', 'Active', '2025-01-04 10:15:00+00', NULL, 300.00, 0.03, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 1500, "weekly": 7500}', ARRAY['debit_card', 'online_banking', 'mobile_app'], TRUE, NULL),
-- 15
('367ffd6b-2880-4690-9e11-70767f22d303', 'ACCT-20250104-0015', 'Loan', -200000.00, 'USD', 'Active', '2025-01-04 11:45:00+00', NULL, 0.00, 3.50, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "15 years"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>property, loan_purpose=>home_equity'),
-- 16
('dafe5b82-8017-4c8f-9130-efc75c5dbba0', 'ACCT-20250104-0016', 'Saving', 18250.25, 'USD', 'Active', '2025-01-04 14:30:00+00', NULL, 0.00, 1.25, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers'], TRUE, NULL),
-- 17
('63c4b437-a20f-4e93-827b-7b943d6c46e0', 'ACCT-20250105-0017', 'Checking', 4325.75, 'USD', 'Active', '2025-01-05 09:10:00+00', NULL, 500.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 3000, "weekly": 15000}', ARRAY['online_banking', 'mobile_app', 'bill_pay'], TRUE, NULL),
-- 18
('b9544b0e-f5ea-4737-acf1-38543dca0605', 'ACCT-20250105-0018', 'Saving', 37650.50, 'USD', 'Active', '2025-01-05 10:45:00+00', NULL, 0.00, 1.45, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 7500, "weekly": 30000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'premium_account=>true'),
-- 19
('10000bde-6ace-4145-9dec-c8fbb6ba83fe', 'ACCT-20250105-0019', 'Loan', -35000.00, 'USD', 'Active', '2025-01-05 13:15:00+00', NULL, 0.00, 6.25, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "3 years"}', NULL, ARRAY['autopay'], TRUE, 'collateral=>vehicle, loan_purpose=>auto'),
-- 20
('77e3b4bf-5dd9-40be-a89c-0c40b6969637', 'ACCT-20250105-0020', 'Checking', 1850.25, 'USD', 'Active', '2025-01-05 15:30:00+00', NULL, 250.00, 0.01, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 1000, "weekly": 5000}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true'),
-- 21
('dee88788-231a-4af6-9095-1d82c1c5946f', 'ACCT-20250106-0021', 'Saving', 48750.75, 'USD', 'Active', '2025-01-06 08:45:00+00', NULL, 0.00, 1.55, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 10000, "weekly": 40000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'vip_customer=>true'),
-- 22
('dc318057-52ad-4ccb-8465-5bb9d7139e2f', 'ACCT-20250106-0022', 'Checking', 3250.50, 'USD', 'Active', '2025-01-06 10:30:00+00', NULL, 500.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 2500, "weekly": 12500}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, NULL),
-- 23
('fc10e804-206a-4ba8-835f-481b36662a49', 'ACCT-20250106-0023', 'Loan', -125000.00, 'USD', 'Active', '2025-01-06 13:15:00+00', NULL, 0.00, 4.25, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "10 years"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>property, loan_purpose=>home_improvement'),
-- 24
('e0d78077-d69e-41fc-925b-40c46c539c3d', 'ACCT-20250106-0024', 'Saving', 12450.25, 'USD', 'Active', '2025-01-06 15:45:00+00', NULL, 0.00, 1.20, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers'], TRUE, NULL),
-- 25
('00c3d3bf-bea7-47d8-bf94-9abc69a8c9f1', 'ACCT-20250107-0025', 'Checking', 5750.75, 'USD', 'Active', '2025-01-07 09:10:00+00', NULL, 750.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 4000, "weekly": 20000}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, 'business_account=>true'),
-- 26
('495fd1cc-e6b2-4418-be46-579010edbad2', 'ACCT-20250107-0026', 'Saving', 32850.50, 'USD', 'Active', '2025-01-07 11:30:00+00', NULL, 0.00, 1.40, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 7500, "weekly": 30000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'premium_account=>true'),
-- 27
('776576cf-84bf-416f-ad37-43cf83d17951', 'ACCT-20250107-0027', 'Loan', -50000.00, 'USD', 'Active', '2025-01-07 13:45:00+00', NULL, 0.00, 5.50, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "4 years"}', NULL, ARRAY['autopay'], TRUE, 'collateral=>none, loan_purpose=>personal'),
-- 28
('b7f295ff-3748-4a3b-80c7-4153749e872a', 'ACCT-20250107-0028', 'Checking', 975.25, 'USD', 'Active', '2025-01-07 15:20:00+00', NULL, 100.00, 0.01, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 800, "weekly": 4000}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true'),
-- 29
('f83df9e0-67c1-48cf-a36c-8dd60914e8af', 'ACCT-20250108-0029', 'Saving', 57350.75, 'USD', 'Active', '2025-01-08 08:30:00+00', NULL, 0.00, 1.65, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 10000, "weekly": 40000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'vip_customer=>true'),
-- 30
('888c5ddd-4878-467e-a950-aed671b7d805', 'ACCT-20250108-0030', 'Checking', 4150.50, 'USD', 'Active', '2025-01-08 10:15:00+00', NULL, 500.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 3000, "weekly": 15000}', ARRAY['online_banking', 'mobile_app', 'bill_pay'], TRUE, NULL),
-- 31
('fbcc1147-e865-4c4e-a83e-767009875bf3', 'ACCT-20250108-0031', 'Loan', -175000.00, 'USD', 'Active', '2025-01-08 11:45:00+00', NULL, 0.00, 3.75, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "20 years"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>property, loan_purpose=>mortgage'),
-- 32
('8161a5d5-896b-498f-b383-95d6981def8d', 'ACCT-20250108-0032', 'Saving', 17250.25, 'USD', 'Active', '2025-01-08 14:30:00+00', NULL, 0.00, 1.30, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers'], TRUE, NULL),
-- 33
('baa49467-f1ea-45d2-9223-1b2876ceee25', 'ACCT-20250109-0033', 'Checking', 3575.75, 'USD', 'Active', '2025-01-09 09:10:00+00', NULL, 500.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 2500, "weekly": 12500}', ARRAY['online_banking', 'mobile_app', 'bill_pay'], TRUE, NULL),
-- 34
('ee9b160e-3249-426e-9692-f090dca22dbd', 'ACCT-20250109-0034', 'Saving', 41850.50, 'USD', 'Active', '2025-01-09 10:45:00+00', NULL, 0.00, 1.50, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 7500, "weekly": 30000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'premium_account=>true'),
-- 35
('30d2dc70-80d9-488e-a027-a68a4f524977', 'ACCT-20250109-0035', 'Loan', -40000.00, 'USD', 'Active', '2025-01-09 13:15:00+00', NULL, 0.00, 6.00, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "3 years"}', NULL, ARRAY['autopay'], TRUE, 'collateral=>vehicle, loan_purpose=>auto'),
-- 36
('96f34e14-2ae0-416d-9a11-c3268f38a80f', 'ACCT-20250109-0036', 'Checking', 1350.25, 'USD', 'Active', '2025-01-09 15:30:00+00', NULL, 200.00, 0.01, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 1000, "weekly": 5000}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true'),
-- 37
('1164d3da-cf17-4b8f-9933-2e3450cacd59', 'ACCT-20250110-0037', 'Saving', 52750.75, 'USD', 'Active', '2025-01-10 08:45:00+00', NULL, 0.00, 1.60, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 10000, "weekly": 40000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'vip_customer=>true'),
-- 38
('db8f78a7-7fe3-4aef-b769-d39736b8ee50', 'ACCT-20250110-0038', 'Checking', 4950.50, 'USD', 'Active', '2025-01-10 10:30:00+00', NULL, 750.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 3500, "weekly": 17500}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, 'business_account=>true'),
-- 39
('5dc25b5b-0e3b-41ef-a97e-8ac8597e66c6', 'ACCT-20250110-0039', 'Loan', -100000.00, 'USD', 'Active', '2025-01-10 13:15:00+00', NULL, 0.00, 4.50, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "7 years"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>none, loan_purpose=>debt_consolidation'),
-- 40
('f73ff58e-acc3-4bff-baf4-dc4ac68021e5', 'ACCT-20250110-0040', 'Saving', 14750.25, 'USD', 'Active', '2025-01-10 15:45:00+00', NULL, 0.00, 1.25, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers'], TRUE, NULL),
-- 41
('f64934d2-88d9-4d27-a1d3-0350cdb04c7c', 'ACCT-20250111-0041', 'Checking', 6150.75, 'USD', 'Active', '2025-01-11 09:10:00+00', NULL, 1000.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 4000, "weekly": 20000}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, 'business_account=>true'),
-- 42
('b759d452-5f50-43a0-bb39-8260437db92f', 'ACCT-20250111-0042', 'Saving', 29350.50, 'USD', 'Active', '2025-01-11 11:30:00+00', NULL, 0.00, 1.35, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 7500, "weekly": 30000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'premium_account=>true'),
-- 43
('7b5e4728-f23c-49b4-9ccd-48393253e5ef', 'ACCT-20250111-0043', 'Loan', -60000.00, 'USD', 'Active', '2025-01-11 13:45:00+00', NULL, 0.00, 5.25, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "5 years"}', NULL, ARRAY['autopay'], TRUE, 'collateral=>none, loan_purpose=>personal'),
-- 44
('26c32105-46de-4083-bf86-a17abd9c0de9', 'ACCT-20250111-0044', 'Checking', 1125.25, 'USD', 'Active', '2025-01-11 15:20:00+00', NULL, 150.00, 0.01, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 900, "weekly": 4500}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true'),
-- 45
('367ffd6b-2880-4690-9e11-70767f22d303', 'ACCT-20250112-0045', 'Saving', 61250.75, 'USD', 'Active', '2025-01-12 08:30:00+00', NULL, 0.00, 1.70, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 10000, "weekly": 50000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'vip_customer=>true'),
-- 46
('dafe5b82-8017-4c8f-9130-efc75c5dbba0', 'ACCT-20250112-0046', 'Checking', 3850.50, 'USD', 'Active', '2025-01-12 10:15:00+00', NULL, 500.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 3000, "weekly": 15000}', ARRAY['online_banking', 'mobile_app', 'bill_pay'], TRUE, NULL),
-- 47
('63c4b437-a20f-4e93-827b-7b943d6c46e0', 'ACCT-20250112-0047', 'Loan', -225000.00, 'USD', 'Active', '2025-01-12 11:45:00+00', NULL, 0.00, 3.25, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "30 years"}', NULL, ARRAY['autopay', 'early_payoff_allowed'], TRUE, 'collateral=>property, loan_purpose=>mortgage'),
-- 48
('b9544b0e-f5ea-4737-acf1-38543dca0605', 'ACCT-20250112-0048', 'Saving', 16250.25, 'USD', 'Active', '2025-01-12 14:30:00+00', NULL, 0.00, 1.25, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 5000, "weekly": 20000}', ARRAY['online_banking', 'automatic_transfers'], TRUE, NULL),
-- 49
('10000bde-6ace-4145-9dec-c8fbb6ba83fe', 'ACCT-20250113-0049', 'Checking', 4275.75, 'USD', 'Active', '2025-01-13 09:10:00+00', NULL, 750.00, 0.05, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 3000, "weekly": 15000}', ARRAY['online_banking', 'mobile_app', 'bill_pay', 'checks'], TRUE, NULL),
-- 50
('77e3b4bf-5dd9-40be-a89c-0c40b6969637', 'ACCT-20250113-0050', 'Saving', 39650.50, 'USD', 'Active', '2025-01-13 10:45:00+00', NULL, 0.00, 1.45, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 7500, "weekly": 30000}', ARRAY['online_banking', 'mobile_app', 'goal_savings'], TRUE, 'premium_account=>true'),
-- 51
('dee88788-231a-4af6-9095-1d82c1c5946f', 'ACCT-20250113-0051', 'Loan', -45000.00, 'USD', 'Active', '2025-01-13 13:15:00+00', NULL, 0.00, 5.75, '{"agreed_to_terms": true, "version": "1.3", "loan_term": "4 years"}', NULL, ARRAY['autopay'], TRUE, 'collateral=>vehicle, loan_purpose=>auto'),
-- 52
('dc318057-52ad-4ccb-8465-5bb9d7139e2f', 'ACCT-20250113-0052', 'Checking', 1725.25, 'USD', 'Active', '2025-01-13 15:30:00+00', NULL, 250.00, 0.01, '{"agreed_to_terms": true, "version": "1.2"}', '{"daily": 1000, "weekly": 5000}', ARRAY['debit_card', 'online_banking'], TRUE, 'student_account=>true');