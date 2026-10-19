# Financial Transaction ETL & Reporting Pipeline

## About This Project

I built this project to practice an end-to-end Data Engineering workflow using synthetic financial transaction data.

The project simulates customer, account, and transaction data and demonstrates how source data can be transformed into a reporting-ready dataset.

Instead of focusing only on individual SQL queries, the project covers the complete data flow:

Source Data → ETL → Reporting Table → Data Quality → Incremental Load → Audit Logging → Stored Procedure → Airflow Orchestration → Reconciliation → Reporting

All data used in this project is synthetic and created only for learning and portfolio purposes.

---

## Project Architecture

The project uses three main source tables:

- Customers
- Accounts
- Transactions

The overall flow is:

```text
Customers + Accounts + Transactions
              ↓
       MySQL Source Data
              ↓
      Apache Airflow DAG
              ↓
         check_source
              ↓
       Validate Source Data
              ↓
           run_etl
              ↓
   CALL sp_transaction_etl()
              ↓
       Join and Transform
              ↓
     Apply Business Rules
              ↓
    Incremental ETL Load
              ↓
 customer_transaction_report
              ↓
         Audit Logging
              ↓
       validate_target
              ↓
 Count + Amount Reconciliation
              ↓
       Business Reporting
```

---

## Source Data

### Customers

Stores basic customer information such as:

- Customer ID
- Name
- Email
- Phone
- State
- Created Date

### Accounts

Stores account information such as:

- Account ID
- Customer ID
- Account Type
- Account Status
- Balance
- Opened Date

A customer can have multiple accounts.

### Transactions

Stores transaction information such as:

- Transaction ID
- Account ID
- Transaction Date
- Transaction Type
- Amount
- Status
- Merchant Name

An account can have multiple transactions.

---

## ETL Process

### Extract

The pipeline reads data from the Customers, Accounts, and Transactions source tables.

### Transform

SQL joins and business rules are used to combine and transform the source data.

Transformations include:

- Joining customers with their accounts
- Joining accounts with transactions
- Combining first name and last name into customer name
- Categorizing transaction amounts
- Converting transaction status into a reporting-friendly processing result

Example business rules:

- Amount greater than 500 → High
- Amount less than or equal to 500 → Normal
- Completed transaction → Success
- Failed transaction → Unsuccessful

### Load

The transformed data is loaded into the `customer_transaction_report` table.

This table provides a combined reporting view of customer, account, and transaction information.

---

## Initial Load

For the initial load, the source contains 12 transactions.

The ETL process transforms and loads those records into the reporting table.

After the load, source and target record counts are validated.

Example:

```text
Source Count = 12
Target Count = 12
```

Record count comparison is only one part of validation, so additional data quality and reconciliation checks are also performed.

---

## Incremental Load

A second-day load is simulated with three new transactions.

Instead of loading all transactions again, the pipeline identifies transactions that do not already exist in the target reporting table.

The incremental logic compares the source `transaction_id` with the target `transaction_id`.

This allows the pipeline to load only new records while preventing duplicate transactions during reruns.

After the incremental load:

```text
Source Count = 15
Target Count = 15
```

If the pipeline is executed again without new source records, zero records are inserted.

This demonstrates idempotent processing because rerunning the load does not create duplicate transactions.

---

## Data Quality and Reconciliation

After loading the data, several validation checks are performed before considering the ETL successful.

These include:

- Source-to-target record count validation
- Critical NULL checks
- Duplicate transaction checks
- Source-to-target amount reconciliation
- Missing record validation
- Business rule validation

Matching source and target counts alone does not guarantee that the data is correct.

Transaction amounts are also reconciled, missing records are checked, and transformation rules are validated.

---

## ETL Audit Logging

An `etl_audit` table is used to track ETL pipeline executions.

The audit log captures:

- Pipeline name
- Start time
- End time
- Source record count
- Target record count
- Records loaded
- Run status
- Error message

Each ETL execution begins with a `RUNNING` status.

After successful processing, the audit record is updated to `SUCCESS`.

If a SQL exception occurs, exception handling updates the run status to `FAILED`.

Audit logging provides visibility into pipeline execution and supports monitoring, troubleshooting, and reconciliation.

---

## Stored Procedure and Transaction Handling

The ETL workflow is automated using a MySQL stored procedure named:

`sp_transaction_etl`

Instead of manually executing each SQL statement separately, the stored procedure groups the related ETL operations into one reusable database process.

The procedure performs:

- ETL audit initialization
- Source record count capture
- Incremental transaction loading
- Customer and account joins
- Business-rule transformations
- Loaded-record tracking using `ROW_COUNT()`
- Target record count capture
- Exception handling
- Transaction control using `COMMIT` and `ROLLBACK`
- SUCCESS / FAILED audit status tracking

The procedure can be executed using:

```sql
CALL sp_transaction_etl();
```

The ETL processing is executed within a database transaction.

If processing completes successfully:

```text
ETL Processing
      ↓
    COMMIT
      ↓
   SUCCESS
```

If a SQL exception occurs before the transaction is committed:

```text
ETL Processing
      ↓
 SQL Exception
      ↓
Exception Handler
      ↓
   ROLLBACK
      ↓
    FAILED
```

This helps prevent an ETL run from leaving unintended partial uncommitted changes.

---

## Apache Airflow Orchestration

Apache Airflow is used to orchestrate the ETL workflow.

The Airflow DAG is named:

`financial_transaction_etl`

The DAG contains three tasks:

```text
check_source
     ↓
run_etl
     ↓
validate_target
```

### 1. check_source

The first task connects to the MySQL database using PyMySQL.

It checks whether source transaction data is available by executing:

```sql
SELECT COUNT(*)
FROM transactions;
```

During testing, the task successfully identified:

```text
Source transaction count: 15
```

If no source transactions are available, the task raises an error.

### 2. run_etl

After the source check succeeds, Airflow executes the ETL stored procedure:

```sql
CALL sp_transaction_etl();
```

The stored procedure performs the incremental and idempotent ETL processing and updates the ETL audit information.

Airflow therefore handles the workflow orchestration while MySQL performs the SQL transformation and loading logic.

### 3. validate_target

After the ETL completes, Airflow performs source-to-target reconciliation.

The task validates:

```text
Source Count = Target Count
```

and:

```text
Source Total Amount = Target Total Amount
```

The completed test produced:

```text
Source Count  = 15
Target Count  = 15

Source Amount = 5610.50
Target Amount = 5610.50
```

If either validation fails, the task raises an error and Airflow marks the task as failed.

If both validations pass:

```text
Data reconciliation successful
```

---

## Airflow Retry and Failure Handling

The Airflow DAG is configured with:

```python
"retries": 2,
"retry_delay": timedelta(minutes=5)
```

This allows a failed task to be retried up to two times with a five-minute delay between attempts.

Task dependencies ensure that downstream processing does not continue until the required upstream task succeeds.

The current project uses manual DAG triggering for development and testing:

```python
schedule=None
```

Automated scheduling can be added as a future enhancement.

---

## Secure Database Connectivity

Airflow connects to MySQL using Python and PyMySQL.

The database password is not hardcoded in the DAG.

It is supplied through an environment variable:

```python
password=os.environ["FINANCIAL_DB_PASSWORD"]
```

This keeps the database password out of the source code and GitHub repository.

---

## Reporting

Once the data is loaded and validated, the reporting table can be used for business analysis.

Reporting queries include:

- Completed vs failed transaction counts
- Transaction volume by transaction type
- Average transaction amount
- Customer transaction volume
- High vs normal transaction categories
- Highest transaction for each account

CTEs and window functions such as `ROW_NUMBER()` are also used for analytical requirements.

---

## SQL Concepts Used

During this project I practiced:

- DDL and DML
- Primary Keys
- Foreign Keys
- INNER JOIN
- LEFT JOIN
- WHERE
- GROUP BY
- HAVING
- COUNT
- SUM
- AVG
- CASE WHEN
- CTEs
- Window Functions
- ROW_NUMBER()
- Stored Procedures
- Variables
- `ROW_COUNT()`
- Incremental Loading
- Idempotent Processing
- Data Quality Validation
- Source-to-Target Reconciliation
- ETL Audit Logging
- Exception Handling
- Transaction Control
- COMMIT
- ROLLBACK

---

## Airflow Concepts Used

During the orchestration portion of the project I practiced:

- DAG creation
- Airflow tasks
- Task dependencies
- TaskFlow API
- Manual DAG triggering
- Retry configuration
- Task logs
- Failure handling
- Python-to-MySQL connectivity
- Environment variables
- Stored procedure orchestration
- Post-load reconciliation

---

## Project Structure

```text
financial-transaction-etl/
│
├── README.md
├── .gitignore
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_transformations.sql
│   ├── 04_etl_load.sql
│   ├── 05_incremental_load.sql
│   ├── 06_data_quality.sql
│   ├── 07_reporting_queries.sql
│   ├── 08_etl_audit.sql
│   └── 09_stored_procedure.sql
│
└── airflow/
    └── financial_transaction_etl.py
```

---

## How to Run the Project

Run the SQL scripts in the following order:

1. `01_create_tables.sql` – Create source tables
2. `02_insert_sample_data.sql` – Insert synthetic sample data
3. `03_transformations.sql` – Practice transformation queries
4. `04_etl_load.sql` – Create and populate the reporting table
5. `05_incremental_load.sql` – Simulate and process new transactions
6. `06_data_quality.sql` – Perform data quality and reconciliation checks
7. `07_reporting_queries.sql` – Execute analytical reporting queries
8. `08_etl_audit.sql` – Demonstrate ETL execution auditing
9. `09_stored_procedure.sql` – Create the reusable ETL stored procedure

After creating the stored procedure, it can be tested directly using:

```sql
CALL sp_transaction_etl();
```

For Airflow orchestration, configure the `FINANCIAL_DB_PASSWORD` environment variable and run the `financial_transaction_etl` DAG.

The Airflow workflow executes:

```text
check_source
     ↓
run_etl
     ↓
validate_target
```

---

## Tools Used

- MySQL
- MySQL Workbench
- SQL
- Python
- PyMySQL
- Apache Airflow
- WSL2 / Ubuntu
- IntelliJ IDEA
- Git
- GitHub

---

## What I Learned

Through this project, I practiced how individual SQL and orchestration concepts work together in an end-to-end Data Engineering workflow.

I learned how to:

- Design relational source tables
- Connect related datasets using joins
- Transform source data using business rules
- Build a reporting-ready target table
- Implement initial and incremental loads
- Make incremental processing idempotent
- Perform data quality and reconciliation checks
- Track pipeline executions using audit logging
- Package ETL logic into a stored procedure
- Handle SQL exceptions
- Use transaction control to commit successful processing or roll back uncommitted changes
- Connect Python to MySQL using PyMySQL
- Build and execute an Apache Airflow DAG
- Define task dependencies
- Configure task retries
- Use Airflow to execute a MySQL stored procedure
- Perform post-load count and amount reconciliation
- Keep database passwords out of source code
- Manage project code using Git and GitHub

---

## Future Enhancements

Future versions of this project can include:

- Watermark-based incremental loading
- Automated Airflow scheduling
- Airflow Connections or a secrets-management solution
- Power BI dashboard development
- More detailed SQL exception diagnostics
- Pipeline alerts and notifications

---

## Project Purpose

This project was built for learning and portfolio purposes using synthetic data.

The project combines SQL, ETL, incremental processing, data quality, reconciliation, audit logging, stored procedures, transaction handling, Python database connectivity, and Apache Airflow orchestration into one end-to-end Data Engineering workflow.
