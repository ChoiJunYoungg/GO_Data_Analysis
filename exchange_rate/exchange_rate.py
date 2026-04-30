import requests
import pyodbc
from datetime import datetime

API_KEY = ''  
URL = f"https://v6.exchangerate-api.com/v6/{API_KEY}/latest/KRW"

CONN_STR = (
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost\SQLEXPRESS;'
    'DATABASE=GO_DWH;'   
    'Trusted_Connection=yes;'
    'Encrypt=yes;'           
    'TrustServerCertificate=yes;' 
)

def update_exchange_rates():
    try:
        response = requests.get(URL, timeout=10)
        response.raise_for_status()
        data = response.json()

        if data.get('result') == 'success':
            rates = data['conversion_rates'] 
            print(f"API 연결 성공 (기준일: {data.get('time_last_update_utc')})")
        else:
            print(f"API 오류: {data.get('error-type')}")
            return
        conn = pyodbc.connect(CONN_STR)
        cursor = conn.cursor()

        target_currencies = ['CNY', 'JPY', 'KRW', 'SGD', 'USD']

        for code in target_currencies:
            if code in rates:
                krw_rate = round(1 / rates[code], 4)
                
                query = """
                MERGE INTO bronze.exchange_rate AS Target
                USING (SELECT ? AS code, ? AS rate) AS Source
                ON Target.currency_code = Source.code
                WHEN MATCHED THEN
                    UPDATE SET exchange_rate = Source.rate, updated_time = GETDATE()
                WHEN NOT MATCHED THEN
                    INSERT (currency_code, exchange_rate, updated_time)
                    VALUES (Source.code, Source.rate, GETDATE());
                """
                cursor.execute(query, code, krw_rate)
        
        conn.commit()
        print(f"{datetime.now().strftime('%H:%M:%S')} - 성공")

    except Exception as e:
        print(f"오류 발생: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    update_exchange_rates()
