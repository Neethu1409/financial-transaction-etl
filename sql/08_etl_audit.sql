-- =====================================================
-- Financial Transaction ETL & Reporting Pipeline
-- File: 08_etl_audit.sql
-- Purpose: Demonstrate ETL audit logging
-- =====================================================

USE financial_etl;


-- =====================================================
-- 1. CREATE ETL AUDIT TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS etl_audit (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    pipeline_name VARCHAR(100),
    start_time DATETIME,
    end_time DATETIME,
    source_count INT,
    target_count INT,
    records_loaded INT,
    run_status VARCHAR(20),
    error_message VARCHAR(255)
);


-- =====================================================
-- 2. RECORD ETL START
-- =====================================================

INSERT INTO etl_audit
(
    pipeline_name,
    start_time,
    run_status
)
VALUES
(
    'transaction_etl',
    NOW(),
    'RUNNING'
);


-- =====================================================
-- 3. CAPTURE SOURCE COUNT
-- =====================================================

SET @current_run_id = LAST_INSERT_ID();

UPDATE etl_audit
SET source_count = (
    SELECT COUNT(*)
    FROM transactions
)
WHERE run_id = @current_run_id;


-- =====================================================
-- 4. IDENTIFY RECORDS NOT YET IN TARGET
-- =====================================================

SELECT
    t.transaction_id,
    t.account_id,
    t.transaction_date,
    t.transaction_type,
    t.amount
FROM transactions t
LEFT JOIN customer_transaction_report r
    ON t.transaction_id = r.transaction_id
WHERE r.transaction_id IS NULL;


-- =====================================================
-- 5. CAPTURE NUMBER OF RECORDS TO BE LOADED
-- =====================================================

UPDATE etl_audit
SET records_loaded = (
    SELECT COUNT(*)
    FROM transactions t
    LEFT JOIN customer_transaction_report r
        ON t.transaction_id = r.transaction_id
    WHERE r.transaction_id IS NULL
)
WHERE run_id = @current_run_id;


-- =====================================================
-- 6. CAPTURE TARGET COUNT
-- =====================================================

UPDATE etl_audit
SET target_count = (
    SELECT COUNT(*)
    FROM customer_transaction_report
)
WHERE run_id = @current_run_id;


-- =====================================================
-- 7. MARK AUDIT RUN SUCCESSFUL
-- =====================================================

UPDATE etl_audit
SET
    end_time = NOW(),
    run_status = 'SUCCESS',
    error_message = NULL
WHERE run_id = @current_run_id;


-- =====================================================
-- 8. VIEW AUDIT HISTORY
-- =====================================================

SELECT *
FROM etl_audit
ORDER BY run_id;