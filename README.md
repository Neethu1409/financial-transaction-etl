# Financial Transaction ETL & Reporting Pipeline

## About This Project

I built this project to practice an end-to-end SQL-based Data Engineering workflow using financial transaction data.

The project simulates customer, account, and transaction data and shows how raw source data can be transformed into a reporting-ready dataset.

Instead of focusing only on individual SQL queries, I wanted to understand the complete flow:

Source Data → ETL → Reporting Table → Data Quality → Incremental Load → Reporting

All data used in this project is synthetic and created only for learning and portfolio purposes.

---

## Project Architecture

The project uses three source tables:

- Customers
- Accounts
- Transactions

The overall flow is:

Customers + Accounts + Transactions  
↓  
Extract source data  
↓  
Join and transform the data  
↓  
Apply business rules  
↓  
Load the reporting table  
↓  
Validate source and target data  
↓  
Process new transactions incrementally  
↓  
Run business reporting queries

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

I used SQL joins and business rules to combine and transform the source data.

Some of the transformations include:

- Joining customers with their accounts
- Joining accounts with transactions
- Combining first name and last name into customer name
- Categorizing transaction amounts
- Converting transaction status into a reporting-friendly processing result

For example:

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

After the load, I validate the source and target counts.

Example:

Source Count = 12  
Target Count = 12

The count check is only one part of validation, so additional data quality and reconciliation checks are also performed.

---

## Incremental Load

I also simulated a second day where three new transactions arrive.

Instead of loading all transactions again, the pipeline identifies only transactions that do not already exist in the target.

The incremental logic compares the source transaction ID with the target transaction ID.

This allows the target-loading step to process new records while avoiding duplicate transactions during reruns.

---

## Data Quality and Reconciliation

After loading the data, I perform several validation checks before considering the ETL successful.

These include:

- Source-to-target record count validation
- Critical NULL checks
- Duplicate transaction checks
- Source-to-target amount reconciliation
- Missing record validation
- Business rule validation

For example, matching source and target counts alone does not guarantee that the data is correct.

I also compare transaction amounts and verify that the transformation rules were applied correctly.

---

## Reporting

Once the data is loaded and validated, I use the reporting table for business analysis.

The reporting queries include:

- Completed vs failed transaction counts
- Transaction volume by transaction type
- Average transaction amount
- Customer transaction volume
- High vs normal transaction categories
- Highest transaction for each account

I also used CTEs and window functions such as `ROW_NUMBER()` for analytical requirements.

---

## ETL Audit Logging

I added an ETL audit table to track each pipeline execution.

The audit log captures:

- Pipeline name
- Start and end time
- Source record count
- Target record count
- Records processed during the run
- Run status
- Error message

Each ETL execution starts with a `RUNNING` status and is updated after processing and validation.

This provides visibility into pipeline execution and helps with monitoring, troubleshooting, and reconciliation.
---
## SQL Concepts Used

During this project I practiced:

- DDL and DML
- Primary and Foreign Keys
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
- ROW_NUMBER
- Incremental Loading
- Data Quality Validation
- Source-to-Target Reconciliation

---

## Project Structure

```text
financial-transaction-etl/
│
├── README.md
│
└── sql/
    ├── 01_create_tables.sql
    ├── 02_insert_sample_data.sql
    ├── 03_transformations.sql
    ├── 04_etl_load.sql
    ├── 05_incremental_load.sql
    ├── 06_data_quality.sql
    └── 07_reporting_queries.sql

## Future Enhancements

- Add ETL audit logging
- Implement stored procedures for reusable ETL processing
- Add watermark-based incremental loading
- Add pipeline scheduling
- Build a Power BI dashboard