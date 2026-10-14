-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 04_etl_load.sql
-- Purpose: Create reporting target and perform
--          initial ETL load
-- =====================================================

USE financial_etl;


-- =====================================================
-- 1. CREATE TARGET TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS customer_transaction_report (
    customer_id INT,
    customer_name VARCHAR(101),
    account_id INT,
    account_type VARCHAR(30),
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    transaction_type VARCHAR(30),
    amount DECIMAL(12,2),
    transaction_status VARCHAR(20),
    amount_category VARCHAR(20),
    processing_result VARCHAR(20)
);


-- =====================================================
-- 2. INITIAL ETL LOAD
-- Load only transactions not already in target
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
-- 3. VERIFY LOAD
-- =====================================================

SELECT COUNT(*) AS source_count
FROM transactions;

SELECT COUNT(*) AS target_count
FROM customer_transaction_report;

SELECT *
FROM customer_transaction_report;