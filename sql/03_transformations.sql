-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 03_transformations.sql
-- Purpose: Demonstrate SQL transformations used
--          to prepare source data for reporting
-- =====================================================

USE financial_etl;


-- =====================================================
-- 1. JOIN CUSTOMER AND ACCOUNT DATA
-- =====================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    a.account_id,
    a.account_type,
    a.account_status,
    a.balance
FROM customers c
INNER JOIN accounts a
    ON c.customer_id = a.customer_id;


-- =====================================================
-- 2. FIND CUSTOMERS WITHOUT AN ACCOUNT
-- Demonstrates LEFT JOIN / unmatched record detection
-- =====================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
WHERE a.account_id IS NULL;


-- =====================================================
-- 3. COMBINE CUSTOMER, ACCOUNT AND TRANSACTION DATA
-- =====================================================

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_id,
    a.account_type,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.amount,
    t.status
FROM customers c
INNER JOIN accounts a
    ON c.customer_id = a.customer_id
INNER JOIN transactions t
    ON a.account_id = t.account_id;


-- =====================================================
-- 4. APPLY BUSINESS RULES USING CASE
-- =====================================================

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
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
    END AS amount_category,

    CASE
        WHEN t.status = 'Completed' THEN 'Success'
        ELSE 'Unsuccessful'
    END AS processing_result

FROM customers c
INNER JOIN accounts a
    ON c.customer_id = a.customer_id
INNER JOIN transactions t
    ON a.account_id = t.account_id;


-- =====================================================
-- 5. CTE - COMPLETED TRANSACTIONS
-- =====================================================

WITH completed_transactions AS
(
    SELECT *
    FROM transactions
    WHERE status = 'Completed'
)
SELECT *
FROM completed_transactions;


-- =====================================================
-- 6. CTE - ACCOUNT TRANSACTION TOTALS
-- =====================================================

WITH completed_transactions AS
(
    SELECT *
    FROM transactions
    WHERE status = 'Completed'
),
account_totals AS
(
    SELECT
        account_id,
        SUM(amount) AS total_amount
    FROM completed_transactions
    GROUP BY account_id
)
SELECT *
FROM account_totals;


-- =====================================================
-- 7. WINDOW FUNCTION - RANK TRANSACTIONS PER ACCOUNT
-- =====================================================

SELECT
    account_id,
    transaction_id,
    amount,

    ROW_NUMBER() OVER (
        PARTITION BY account_id
        ORDER BY amount DESC
    ) AS transaction_rank

FROM transactions;


-- =====================================================
-- 8. HIGHEST TRANSACTION FOR EACH ACCOUNT
-- CTE + Window Function
-- =====================================================

WITH ranked_transactions AS
(
    SELECT
        account_id,
        transaction_id,
        transaction_type,
        amount,

        ROW_NUMBER() OVER (
            PARTITION BY account_id
            ORDER BY amount DESC
        ) AS rn

    FROM transactions
)

SELECT *
FROM ranked_transactions
WHERE rn = 1;