from airflow.sdk import DAG, task
from datetime import datetime, timedelta
import pymysql
import os


def get_connection():
    return pymysql.connect(
        host="172.22.32.1",
        user="airflow_user",
        password=os.environ["FINANCIAL_DB_PASSWORD"],
        database="financial_etl",
        port=3306
    )


with DAG(
    dag_id="financial_transaction_etl",
    start_date=datetime(2026, 10, 18),
    schedule=None,
    catchup=False,
    default_args={
        "owner": "neethu",
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
    },
) as dag:

    @task
    def check_source():
        conn = get_connection()

        try:
            cursor = conn.cursor()

            cursor.execute(
                "SELECT COUNT(*) FROM transactions"
            )

            source_count = cursor.fetchone()[0]

            print(f"Source transaction count: {source_count}")

            if source_count == 0:
                raise ValueError("No source transactions found")

            return source_count

        finally:
            cursor.close()
            conn.close()


    @task
    def run_etl():
        conn = get_connection()

        try:
            cursor = conn.cursor()

            cursor.execute("CALL sp_transaction_etl()")

            conn.commit()

            print("Financial Transaction ETL completed successfully")

            return "ETL completed"

        finally:
            cursor.close()
            conn.close()


    @task
    def validate_target():
        conn = get_connection()

        try:
            cursor = conn.cursor()

            # Source record count
            cursor.execute(
                "SELECT COUNT(*) FROM transactions"
            )
            source_count = cursor.fetchone()[0]

            # Target record count
            cursor.execute(
                "SELECT COUNT(*) FROM customer_transaction_report"
            )
            target_count = cursor.fetchone()[0]

            # Source total amount
            cursor.execute(
                "SELECT COALESCE(SUM(amount), 0) FROM transactions"
            )
            source_amount = cursor.fetchone()[0]

            # Target total amount
            cursor.execute(
                "SELECT COALESCE(SUM(amount), 0) "
                "FROM customer_transaction_report"
            )
            target_amount = cursor.fetchone()[0]

            print(f"Source count: {source_count}")
            print(f"Target count: {target_count}")
            print(f"Source amount: {source_amount}")
            print(f"Target amount: {target_amount}")

            if source_count != target_count:
                raise ValueError(
                    f"Count reconciliation failed: "
                    f"source={source_count}, target={target_count}"
                )

            if source_amount != target_amount:
                raise ValueError(
                    f"Amount reconciliation failed: "
                    f"source={source_amount}, target={target_amount}"
                )

            print("Data reconciliation successful")

            return "Validation completed"

        finally:
            cursor.close()
            conn.close()


    check_source() >> run_etl() >> validate_target()
