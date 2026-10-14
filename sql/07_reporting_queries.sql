-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 07_reporting_queries.sql
-- Purpose: Business reporting and KPI queries
-- =====================================================

USE financial_etl;


-- =====================================================
-- 1. COMPLETED VS FAILED TRANSACTIONS
-- =====================================================

SELECT
    transaction_status,
    COUNT(*) AS transaction_count
FROM customer_transaction_report
GROUP BY transaction_status;


-- =====================================================
-- 2. TRANSACTION VOLUME BY TYPE
-- =====================================================

SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_transaction_volume,
    AVG(amount) AS average_transaction_amount
FROM customer_transaction_report
WHERE transaction_status = 'Completed'
GROUP BY transaction_type
ORDER BY total_transaction_volume DESC;


-- =====================================================
-- 3. CUSTOMER TRANSACTION VOLUME
-- =====================================================

SELECT
    customer_id,
    customer_name,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_transaction_volume
FROM customer_transaction_report
WHERE transaction_status = 'Completed'
GROUP BY customer_id, customer_name
ORDER BY total_transaction_volume DESC;


-- =====================================================
-- 4. HIGH VS NORMAL TRANSACTIONS
-- =====================================================

SELECT
    amount_category,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_transaction_volume
FROM customer_transaction_report
GROUP BY amount_category;


-- =====================================================
-- 5. HIGHEST TRANSACTION FOR EACH ACCOUNT
-- CTE + Window Function
-- =====================================================

WITH ranked_transactions AS
(
    SELECT
        account_id,
        customer_name,
        transaction_id,
        transaction_type,
        amount,

        ROW_NUMBER() OVER (
            PARTITION BY account_id
            ORDER BY amount DESC
        ) AS rn

    FROM customer_transaction_report
)

SELECT
    account_id,
    customer_name,
    transaction_id,
    transaction_type,
    amount
FROM ranked_transactions
WHERE rn = 1
ORDER BY amount DESC;