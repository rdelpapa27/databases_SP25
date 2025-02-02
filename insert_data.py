import bz2
import pandas as pd
import pymysql
import io

DB_CONFIG = {
    'host': input("Enter MySQL host (default: localhost): ") or 'localhost',
    'user': input("Enter MySQL username (default: root): ") or 'root',
    'password': input("Enter MySQL password: "),
    'database': input("Enter MySQL database name (default: taxi_database): ") or 'taxi_database'
}

# Print the connection details (except password) to confirm
print(f"Connecting to MySQL database '{DB_CONFIG['database']}' as user '{DB_CONFIG['user']}"
      f"' on host '{DB_CONFIG['host']}'")


def load_bz2(filepath):
    try:
        with bz2.open(filepath, 'rb') as file:
            data = file.read().decode('utf-8')

        df = pd.read_csv(io.StringIO(data), header=None, names=[
            'medallion', 'hack_license', 'pickup_datetime', 'dropoff_datetime',
            'trip_time_in_secs', 'trip_distance', 'pickup_longitude', 'pickup_latitude',
            'dropoff_longitude', 'dropoff_latitude', 'payment_type', 'fare_amount',
            'surcharge', 'mta_tax', 'tip_amount', 'tolls_amount', 'total_amount'
        ])

        # Convert timestamp columns to proper datetime format
        df['pickup_datetime'] = pd.to_datetime(df['pickup_datetime'], format='%m/%d/%Y %H:%M', errors='coerce')
        df['dropoff_datetime'] = pd.to_datetime(df['dropoff_datetime'], format='%m/%d/%Y %H:%M', errors='coerce')

        # Convert numeric fields to appropriate types
        df['fare_amount'] = pd.to_numeric(df['fare_amount'], errors='coerce')
        df['trip_distance'] = pd.to_numeric(df['trip_distance'], errors='coerce')


        # Handle missing values
        df.fillna({
            'medallion': 'UNKNOWN',
            'hack_license': 'UNKNOWN',
            'payment_type': 'UNK',
            'fare_amount': 0.0,
            'trip_distance': 0.0,
        }, inplace=True)

        return df

    except Exception as e:
        print(f"Error reading file: {e}")
        return None

def insert_into_mysql(df, table_name):
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()

        sql = f"""INSERT INTO {table_name} (medallion, hack_license, pickup_datetime, dropoff_datetime, 
        trip_time_in_secs, trip_distance, pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude,
        payment_type, fare_amount, surcharge, mta_tax, tip_amount, tolls_amount, total_amount) 
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""

        # Bulk insert using executemany
        values_list = [
            (
                row['medallion'], row['hack_license'],
                row['pickup_datetime'].strftime('%Y-%m-%d %H:%M:%S') if pd.notna(
                    row['pickup_datetime']) else '2013-01-01 12:02:00',
                row['dropoff_datetime'].strftime('%Y-%m-%d %H:%M:%S') if pd.notna(
                    row['dropoff_datetime']) else '2013-01-01 12:02:00',
                row['trip_time_in_secs'], row['trip_distance'], row['pickup_longitude'], row['pickup_latitude'],
                row['dropoff_longitude'], row['dropoff_latitude'], row['payment_type'], row['fare_amount'],
                row['surcharge'], row['mta_tax'], row['tip_amount'], row['tolls_amount'], row['total_amount']
            ) for _, row in df.iterrows()
        ]

        cursor.executemany(sql, values_list)
        conn.commit()
        print("Data inserted successfully into MySQL database.")

    except pymysql.Error as err:
        print(f"Error inserting data: {err}")
    finally:
        cursor.close()
        conn.close()


file_path = input("Enter the full path to the .bz2 file that contains data: ")
#r'C:\Users\reese\Downloads\taxi-data-sorted-small.csv.bz2' is my file_path
table_name = 'taxi_data_table'

df = load_bz2(file_path)
if df is not None:
    insert_into_mysql(df, table_name)
