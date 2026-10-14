-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 02_insert_sample_data.sql
-- Purpose: Load synthetic sample source data
-- =====================================================

USE financial_etl;


-- =====================================================
-- CUSTOMERS
-- INSERT IGNORE prevents duplicate primary-key errors
-- when sample records already exist
-- =====================================================

INSERT IGNORE INTO customers
(
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    state,
    created_date
)
VALUES
(101, 'Neethu', 'Priya', 'neethu@email.com', '555-1001', 'TX', '2025-01-10'),
(102, 'John', 'Smith', 'john@email.com', '555-1002', 'CA', '2025-02-15'),
(103, 'Sara', 'Lee', 'sara@email.com', '555-1003', 'TX', '2025-03-20'),
(104, 'David', 'Brown', 'david@email.com', NULL, 'NY', '2025-04-05'),
(105, 'Emily', 'Davis', 'emily@email.com', '555-1005', 'CA', '2025-05-12'),
(106, 'Robert', 'Wilson', 'robert@email.com', '555-1006', 'FL', '2025-06-01');


-- =====================================================
-- ACCOUNTS
-- =====================================================

INSERT IGNORE INTO accounts
(
    account_id,
    customer_id,
    account_type,
    account_status,
    balance,
    opened_date
)
VALUES
(1001, 101, 'Checking', 'Active', 4500.00, '2025-01-15'),
(1002, 101, 'Savings', 'Active', 12000.00, '2025-02-01'),
(1003, 102, 'Checking', 'Active', 3200.00, '2025-02-20'),
(1004, 103, 'Savings', 'Active', 8500.00, '2025-03-25'),
(1005, 104, 'Checking', 'Inactive', 500.00, '2025-04-10'),
(1006, 105, 'Checking', 'Active', 6700.00, '2025-05-15');


-- =====================================================
-- DAY 1 TRANSACTIONS
-- =====================================================

INSERT IGNORE INTO transactions
(
    transaction_id,
    account_id,
    transaction_date,
    transaction_type,
    amount,
    status,
    merchant_name
)
VALUES
(5001, 1001, '2025-06-01', 'Purchase', 120.00, 'Completed', 'Walmart'),
(5002, 1001, '2025-06-02', 'Purchase', 75.50, 'Completed', 'Amazon'),
(5003, 1001, '2025-06-03', 'Payment', 500.00, 'Completed', NULL),
(5004, 1002, '2025-06-01', 'Deposit', 1000.00, 'Completed', NULL),
(5005, 1002, '2025-06-04', 'Withdrawal', 200.00, 'Completed', 'ATM'),
(5006, 1003, '2025-06-02', 'Purchase', 250.00, 'Completed', 'Target'),
(5007, 1003, '2025-06-03', 'Purchase', 90.00, 'Failed', 'Amazon'),
(5008, 1004, '2025-06-01', 'Deposit', 1500.00, 'Completed', NULL),
(5009, 1004, '2025-06-05', 'Withdrawal', 300.00, 'Completed', 'ATM'),
(5010, 1005, '2025-06-02', 'Purchase', 45.00, 'Completed', 'Walmart'),
(5011, 1006, '2025-06-03', 'Purchase', 180.00, 'Completed', 'Costco'),
(5012, 1006, '2025-06-04', 'Purchase', 220.00, 'Completed', 'Amazon');


-- =====================================================
-- VERIFY SOURCE DATA
-- =====================================================

SELECT COUNT(*) AS customer_count
FROM customers;

SELECT COUNT(*) AS account_count
FROM accounts;

SELECT COUNT(*) AS transaction_count
FROM transactions;