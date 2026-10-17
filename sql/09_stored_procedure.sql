USE financial_etl;

DROP PROCEDURE IF EXISTS sp_transaction_etl;

DELIMITER //

CREATE PROCEDURE sp_transaction_etl()
BEGIN

    DECLARE v_run_id INT DEFAULT NULL;
    DECLARE v_source_count INT;
    DECLARE v_records_loaded INT;
    DECLARE v_target_count INT;


    -- =============================================
    -- EXCEPTION HANDLER
    -- Runs automatically if a SQL error occurs
    -- =============================================

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN

        -- Undo uncommitted ETL changes
        ROLLBACK;

        -- Record the failure
        UPDATE etl_audit
        SET
            end_time = NOW(),
            run_status = 'FAILED',
            error_message = 'ETL processing failed'
        WHERE run_id = v_run_id;

    END;


    -- =============================================
    -- STEP 1: Create Audit Record
    -- =============================================

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

    SET v_run_id = LAST_INSERT_ID();


    -- =============================================
    -- STEP 2: Start ETL Transaction
    -- =============================================

    START TRANSACTION;


    -- =============================================
    -- STEP 3: Count Source Records
    -- =============================================

    SELECT COUNT(*)
    INTO v_source_count
    FROM transactions;


    UPDATE etl_audit
    SET source_count = v_source_count
    WHERE run_id = v_run_id;


    -- =============================================
    -- STEP 4: Incremental ETL Load
    -- =============================================

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


    -- =============================================
    -- STEP 5: Capture Records Loaded
    -- =============================================

    SET v_records_loaded = ROW_COUNT();


    UPDATE etl_audit
    SET records_loaded = v_records_loaded
    WHERE run_id = v_run_id;


    -- =============================================
    -- STEP 6: Count Target Records
    -- =============================================

    SELECT COUNT(*)
    INTO v_target_count
    FROM customer_transaction_report;


    UPDATE etl_audit
    SET target_count = v_target_count
    WHERE run_id = v_run_id;


    -- =============================================
    -- STEP 7: Commit ETL Changes
    -- =============================================

    COMMIT;


    -- =============================================
    -- STEP 8: Mark Run Successful
    -- =============================================

    UPDATE etl_audit
    SET
        end_time = NOW(),
        run_status = 'SUCCESS',
        error_message = NULL
    WHERE run_id = v_run_id;

END //

DELIMITER ;

CALL sp_transaction_etl();

SELECT *
FROM etl_audit
ORDER BY run_id DESC;