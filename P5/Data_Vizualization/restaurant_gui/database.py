import pyodbc
import pandas as pd

def get_connection():
    #modify this acc to your database
    conn = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=KIRANSS;'
        'DATABASE=RestaurantDB;'
        'Trusted_Connection=yes;'
    )
    return conn


def run_query(query, params=None):
    conn = get_connection()
    df = pd.read_sql(query, conn, params=params)
    conn.close()
    return df

def execute_query(query, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query, params or ())
    conn.commit()
    conn.close()

# Test connection
def main():
    try:
        df = run_query("SELECT TOP 5 * FROM CUSTOMER")
        print(" Connection successful. Sample data from CUSTOMER table:")
        print(df)
    except Exception as e:
        print(" Failed to connect or query the database.")
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
