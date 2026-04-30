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
