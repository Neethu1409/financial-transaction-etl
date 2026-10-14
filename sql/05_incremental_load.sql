-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 05_incremental_load.sql
-- Purpose: Simulate Day-2 source data and perform
--          incremental ETL loading
-- =====================================================

USE financial_etl;


-- =====================================================
-- 1. SIMULATE DAY-2 NEW TRANSACTIONS
-- INSERT IGNORE allows the sample source-data step
-- to be rerun without duplicate-key failure
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
(5013, 1001, '2025-06-06', 'Purchase', 350.00, 'Completed', 'Best Buy'),
(5014, 1003, '2025-06-06', 'Payment', 700.00, 'Completed', NULL),
(5015, 1006, '2025-06-06', 'Purchase', 80.00, 'Completed', 'Target');


-- =====================================================
-- 2. IDENTIFY NEW RECORDS
-- Records existing in source but not yet in target
-- =====================================================

SELECT
    t.*
FROM transactions t

LEFT JOIN customer_transaction_report r
    ON t.transaction_id = r.transaction_id

WHERE r.transaction_id IS NULL;


-- =====================================================
-- 3. INCREMENTAL ETL LOAD
-- Load only records that do not exist in target
-- =====================================================

INSERT INTO customer_transaction_report
(
    customer_id,
    customer_name,
    account_id,
    account_type,
    transaction_id,
    transaction_date,
    transaction_type,
    amount,
    transaction_status,
    amount_category,
    processing_result
)

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name),
    a.account_id,
    a.account_type,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.amount,
    t.status,

    CASE
        WHEN t.amount > 500 THEN 'High'
        ELSE 'Normal'
    END,

    CASE
        WHEN t.status = 'Completed' THEN 'Success'
        ELSE 'Unsuccessful'
    END

FROM transactions t

INNER JOIN accounts a
    ON t.account_id = a.account_id

INNER JOIN customers c
    ON a.customer_id = c.customer_id

LEFT JOIN customer_transaction_report r
    ON t.transaction_id = r.transaction_id

WHERE r.transaction_id IS NULL;


-- =====================================================
-- 4. SOURCE-TARGET VALIDATION
-- =====================================================

SELECT COUNT(*) AS source_count
FROM transactions;

SELECT COUNT(*) AS target_count
FROM customer_transaction_report;


-- =====================================================
-- 5. DUPLICATE VALIDATION
-- Expected result: 0 rows
-- =====================================================

SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM customer_transaction_report
GROUP BY transaction_id
HAVING COUNT(*) > 1;