import os
import psycopg2
from psycopg2 import OperationalError

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'db'),
            database=os.getenv('DB_NAME', 'flask_db'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASS', 'password'),
            connect_timeout=5
        )
        return conn
    except OperationalError as e:
        print(f"Error connecting to RDS: {e}")
        return None

def check_db_status():
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute('SELECT version();')
            db_version = cur.fetchone()
            cur.close()
            conn.close()
            return f"Connected! PostgreSQL version: {db_version[0]}"
        except Exception as e:
            return f"Query error: {e}"
    return "Connection failed! Check Security Groups/RDS status."
