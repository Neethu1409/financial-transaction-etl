-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 06_data_quality.sql
-- Purpose: Validate ETL results using data quality
--          and source-to-target reconciliation checks
-- =====================================================

USE financial_etl;


-- =====================================================
-- 1. SOURCE-TO-TARGET RECORD COUNT
-- =====================================================

SELECT COUNT(*) AS source_count
FROM transactions;

SELECT COUNT(*) AS target_count
FROM customer_transaction_report;


-- =====================================================
-- 2. CHECK CRITICAL NULL VALUES
-- Expected result: 0 rows
-- =====================================================

SELECT *
FROM customer_transaction_report
WHERE transaction_id IS NULL
   OR customer_id IS NULL
   OR account_id IS NULL
   OR amount IS NULL;


-- =====================================================
-- 3. CHECK DUPLICATE TRANSACTIONS
-- Expected result: 0 rows
-- =====================================================

SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM customer_transaction_report
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- =====================================================
-- 4. SOURCE-TO-TARGET AMOUNT RECONCILIATION
-- =====================================================

SELECT
    SUM(amount) AS source_total_amount
FROM transactions;

SELECT
    SUM(amount) AS target_total_amount
FROM customer_transaction_report;


-- =====================================================
-- 5. FIND SOURCE RECORDS MISSING FROM TARGET
-- Expected result after successful ETL: 0 rows
-- =====================================================

SELECT
    t.transaction_id,
    t.account_id,
    t.amount,
    t.status
FROM transactions t
LEFT JOIN customer_transaction_report r
    ON t.transaction_id = r.transaction_id
WHERE r.transaction_id IS NULL;


-- =====================================================
-- 6. VALIDATE AMOUNT CATEGORY BUSINESS RULE
-- amount > 500  = High
-- amount <= 500 = Normal
-- Expected result: 0 rows
-- =====================================================

SELECT *
FROM customer_transaction_report
WHERE (amount > 500 AND amount_category <> 'High')
   OR (amount <= 500 AND amount_category <> 'Normal');


-- =====================================================
-- 7. VALIDATE PROCESSING RESULT
-- Completed = Success
-- Failed    = Unsuccessful
-- Expected result: 0 rows
-- =====================================================

SELECT *
FROM customer_transaction_report
WHERE
    (transaction_status = 'Completed'
        AND processing_result <> 'Success')
    OR
    (transaction_status = 'Failed'
        AND processing_result <> 'Unsuccessful');