USE master;

CREATE DATABASE GO_DWH;

USE GO_DWH;

GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

-- Create DDL for Tables
-- 데이터를 보고 관련된 컬럼, 룰로 지정한 테이블 이름을 고려해 테이블을만든다

IF OBJECT_ID('bronze.go_gibo', 'U') IS NOT NULL
	DROP TABLE bronze.go_gibo;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE bronze.go_gibo(
	go_black_player NVARCHAR(50),
	go_white_player NVARCHAR(50),
	go_komi FLOAT,
	go_result NVARCHAR(50),
	go_date DATE,
	go_gamename NVARCHAR(200),
	go_timelimit FLOAT,
	go_byo_yomi_count INT,
	go_byo_yomi_time INT,
	go_rule NVARCHAR(50),
	go_black_player_country NVARCHAR(50),
	go_white_player_country NVARCHAR(50)
);


-- Develop SQL Load Scripts
-- BULK INSERT 사용
-- CSV나 텍스트 같은 외부 데이터 파일의 대량 데이터를 테이블로 한 번에 아주 빠르게 밀어 넣는 기능
-- 데이터를 한 줄씩 넣는것이 아닌, 파일을 통째로 읽어 처리하기때문에 성능이 압도적으로 좋음

TRUNCATE TABLE bronze.go_gibo; -- BULK INSERT를 두번하면 데이터가 중복해서 2번들어가기 때문에 다시 실행하기 위해선 테이블을 비워주어야함
BULK INSERT bronze.go_gibo
FROM 'C:\Users\Public\Documents\go_games_bronze.csv'
WITH (
	FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a', -- 또는 '\n'
    FIRSTROW = 2,           -- 헤더 제외
    KEEPNULLS,              -- 빈 값(,,)을 NULL로 처리
    CODEPAGE = '65001',
	TABLOCK -- 속도향상, 한번의 lock을 통해 리소스 낭비를 막아줌
);

-- INSERT를 한 후 QUALITY CHECK를 해야함
-- CHECK that the data has not shifted and is in the correct columns
SELECT
	*
FROM bronze.go_gibo

SELECT
	COUNT(*)
FROM bronze.go_gibo


-- 선수 정보에 대한 테이블 생성
IF OBJECT_ID('bronze.go_player_info', 'U') IS NOT NULL
	DROP TABLE bronze.go_player_info;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE bronze.go_player_info(
	go_player_name NVARCHAR(50),
	go_player_birthday DATE,
	go_player_YOP FLOAT,
	go_player_country NVARCHAR(50)
);

TRUNCATE TABLE bronze.go_player_info; -- BULK INSERT를 두번하면 데이터가 중복해서 2번들어가기 때문에 다시 실행하기 위해선 테이블을 비워주어야함
BULK INSERT bronze.go_player_info
FROM 'C:\Users\Public\Documents\go_player_info_bronze.csv'
WITH (
	FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a', -- 또는 '\n'
    FIRSTROW = 2,           -- 헤더 제외
    KEEPNULLS,              -- 빈 값(,,)을 NULL로 처리
    CODEPAGE = '65001',
	DATAFILETYPE = 'char',
	TABLOCK -- 속도향상, 한번의 lock을 통해 리소스 낭비를 막아줌
);

-- INSERT를 한 후 QUALITY CHECK를 해야함
-- CHECK that the data has not shifted and is in the correct columns
SELECT
	*
FROM bronze.go_player_info

SELECT
	COUNT(*)
FROM bronze.go_player_info

-- 대회 정보에 대한 테이블 생성
IF OBJECT_ID('bronze.go_tournament', 'U') IS NOT NULL
	DROP TABLE bronze.go_tournament;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE bronze.go_tournament(
	go_tournament_name NVARCHAR(1000),
	go_tournament_timelimit INT,
	go_tournament_method NVARCHAR(50),
	go_tournament_prize FLOAT,
	go_tournament_unit NVARCHAR(50),
	go_tournament_opencountry NVARCHAR(50),
	go_tournament_type NVARCHAR(50)
);

TRUNCATE TABLE bronze.go_tournament; -- BULK INSERT를 두번하면 데이터가 중복해서 2번들어가기 때문에 다시 실행하기 위해선 테이블을 비워주어야함
BULK INSERT bronze.go_tournament
FROM 'C:\Users\Public\Documents\go_tournament_bronze.csv'
WITH (
	FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '0x0a', -- 또는 '\n'
    FIRSTROW = 2,           -- 헤더 제외
    KEEPNULLS,              -- 빈 값(,,)을 NULL로 처리
    CODEPAGE = '65001',
	DATAFILETYPE = 'char',
	TABLOCK -- 속도향상, 한번의 lock을 통해 리소스 낭비를 막아줌
);

SELECT
	*
FROM bronze.go_tournament

SELECT
	COUNT(*)
FROM bronze.go_tournament

-- 환율 정보에 대한 테이블 생성
IF OBJECT_ID('bronze.exchange_rate', 'U') IS NOT NULL
	DROP TABLE bronze.exchange_rate;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE bronze.exchange_rate(
	currency_code NVARCHAR(10),
	exchange_rate DECIMAL(10,2),
	updated_time DATETIME DEFAULT GETDATE()
);

SELECT
	*
FROM bronze.exchange_rate

SELECT
	DISTINCT go_tournament_unit
FROM bronze.go_tournament

-- Create Stored Procedure
-- Save frequnetly used SQL code in stored procedures in database

GO
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
	SET @batch_start_time = GETDATE();
		PRINT '=====================================';
		print 'Loading Bronze Layer';
		PRINT '=====================================';

		PRINT '-------------------------------------';
		PRINT 'Loading GO Tables';
		PRINT '-------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table : bronze.go_gibo';
		TRUNCATE TABLE bronze.go_gibo;

		PRINT '>> Inserting Data Into: bronze.go_gibo';
		BULK INSERT bronze.go_gibo
		FROM 'C:\Users\Public\Documents\go_games_bronze.csv'
		WITH (
			FIELDTERMINATOR = ',', 
			ROWTERMINATOR = '0x0a', 
			FIRSTROW = 2,           
			KEEPNULLS,              
			CODEPAGE = '65001',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.go_player_info';
		TRUNCATE TABLE bronze.go_player_info;

		PRINT '>> Inserting Data Into: bronze.go_player_info';
		BULK INSERT bronze.go_player_info
		FROM 'C:\Users\Public\Documents\go_player_info_bronze.csv'
		WITH (
			FIELDTERMINATOR = ',', 
			ROWTERMINATOR = '0x0a', -- 또는 '\n'
			FIRSTROW = 2,           -- 헤더 제외
			KEEPNULLS,              -- 빈 값(,,)을 NULL로 처리
			CODEPAGE = '65001',
			TABLOCK -- 속도향상, 한번의 lock을 통해 리소스 낭비를 막아줌
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.go_tournament';
		TRUNCATE TABLE bronze.go_tournament;

		PRINT '>> Inserting Data Into: bronze.go_tournament';
		BULK INSERT bronze.go_tournament
		FROM 'C:\Users\Public\Documents\go_tournament_bronze.csv'
		WITH (
			FIELDTERMINATOR = ',', 
			ROWTERMINATOR = '0x0a', 
			FIRSTROW = 2,           
			KEEPNULLS,              
			CODEPAGE = '65001',
			DATAFILETYPE = 'char',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------'

		SET @batch_end_time = GETDATE();
		PRINT '==================================';
		PRINT 'Loading Bronze Layer is completed';
		PRINT '    - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==================================';
	END TRY
	BEGIN CATCH
		PRINT '==================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==================================';
	END CATCH
END
GO

-- 실행시키면 Programmability -> Stored Procedures에서 볼 수 있음

EXEC bronze.load_bronze