/* Build Silver Layer
Create Stored Procedure */
-- Programmability - Stored Procedures 에서 확인가능

GO
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=================================================';
		PRINT 'Loading Silver Layer';
		PRINT '=================================================';

		PRINT '-------------------------------------------------';
		PRINT 'Loading GO Tables';
		PRINT '-------------------------------------------------';

		-- Loading silver.go_gibo
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.go_gibo';
		TRUNCATE TABLE silver.go_gibo;
		PRINT '>> Inserting Data Into: silver.go_gibo';

		INSERT INTO silver.go_gibo(
		go_gamename,
		go_date,
		go_black_player,
		go_white_player,
		go_komi,
		go_result,
		go_timelimit,
		go_byo_yomi_count,
		go_byo_yomi_time,
		go_rule,
		go_black_player_country,
		go_white_player_country
		)

		SELECT
		go_gamename,
		go_date,
		go_black_player,
		go_white_player,
		go_komi,
		go_result,
		go_timelimit,
		go_byo_yomi_count,
		go_byo_yomi_time,
		go_rule,
		CASE
			WHEN LOWER(TRIM(go_black_player_country)) = 'kr' THEN 'Korea'
			WHEN LOWER(TRIM(go_black_player_country)) = 'jp' THEN 'Japan'
			WHEN LOWER(TRIM(go_black_player_country)) = 'ukr' THEN 'Ukraine'
			WHEN LOWER(TRIM(go_black_player_country)) = 'rm' THEN 'Romania'
			WHEN LOWER(TRIM(go_black_player_country)) = 'tp' THEN 'Taiwan'
			WHEN LOWER(TRIM(go_black_player_country)) = 'ch' THEN 'China'
			ELSE 'n/a'
		END AS go_black_player_country,
		CASE
			WHEN LOWER(REGEXP_REPLACE(go_white_player_country, '[^a-zA-Z]', '')) = 'tp' THEN 'Taiwan' -- 글자수보다 글자의 길이가 1많음 : 정규표현식을 통해 문자가 아닌부분 제거
			WHEN LOWER(REGEXP_REPLACE(go_white_player_country, '[^a-zA-Z]', '')) IN ('kr', 'ckr') THEN 'Korea' -- ckr은 kr을 잘못입력한값
			WHEN LOWER(REGEXP_REPLACE(go_white_player_country, '[^a-zA-Z]', ''))= 'jp' THEN 'Japan'
			WHEN LOWER(REGEXP_REPLACE(go_white_player_country, '[^a-zA-Z]', '')) = 'ch' THEN 'China'
			WHEN LOWER(REGEXP_REPLACE(go_white_player_country, '[^a-zA-Z]', '')) = 'usa' THEN 'USA'
			ELSE 'n/a'
		END AS go_white_player_country
		FROM(
		SELECT
			*,
			ROW_NUMBER() OVER(PARTITION BY go_gamename, go_date, go_black_player, go_white_player ORDER BY go_date DESC) AS flag
		FROM bronze.go_gibo
		WHERE go_gamename IS NOT NULL AND go_date IS NOT NULL AND go_black_player IS NOT NULL AND go_white_player IS NOT NULL
		)t
		WHERE flag = 1
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> --------------';

		-- Loading silver.go_tournament
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.go_player_info';
		TRUNCATE TABLE silver.go_player_info;
		PRINT '>> Inserting Data Into: silver.go_player_info';

		INSERT INTO silver.go_player_info(
		go_player_name,
		go_player_birthday,
		go_player_YOP,
		go_player_country
		)

		SELECT
			go_player_name,
			go_player_birthday,
			go_player_YOP,
			CASE	
				WHEN LOWER(REGEXP_REPLACE(go_player_country, '[^a-zA-Z]', '')) = 'korea' THEN 'Korea' -- 글자수보다 글자의 길이가 1많음 : 정규표현식을 통해 문자가 아닌부분 제거
				WHEN LOWER(REGEXP_REPLACE(go_player_country, '[^a-zA-Z]', '')) = 'china' THEN 'China'
				ELSE 'n/a'
			END AS go_player_country
		FROM bronze.go_player_info
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> --------------';

		-- Loading silver.go_tournament
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.go_tournament';
		TRUNCATE TABLE silver.go_tournament;
		PRINT '>> Inserting Data Into: silver.go_tournament';

		INSERT INTO silver.go_tournament(
		go_tournament_name,
		go_tournament_timelimit_second,
		go_tournament_method,
		go_tournament_genre,
		go_tournament_prize,
		go_tournament_prize_kr,
		go_tournament_unit,
		go_tournament_opencountry,
		go_tournament_type
		)

		SELECT
		go_tournament_name,
		go_tournament_timelimit, 
		go_tournament_method,
		CASE
			WHEN go_tournament_timelimit <= 60 THEN '초속기'
			WHEN go_tournament_timelimit > 60 AND go_tournament_timelimit <= 1200 THEN '속기'
			WHEN go_tournament_timelimit > 1200 AND go_tournament_timelimit < 3600 THEN '일반'
			ELSE '장고'
		END AS go_tournament_genre,
		go_tournament_prize,
		ROUND(t.go_tournament_prize * COALESCE(r.exchange_rate, 1), 0) AS go_tournament_prize_kr,
		CASE	
			WHEN LOWER(TRIM(go_tournament_unit)) = 'krw' THEN 'KRW'
			WHEN LOWER(TRIM(go_tournament_unit)) = 'cny' THEN 'CNY'
			WHEN LOWER(TRIM(go_tournament_unit)) = 'jpy' THEN 'JPY'
			WHEN LOWER(TRIM(go_tournament_unit)) = 'sgd' THEN 'SGD'
			WHEN LOWER(TRIM(go_tournament_unit)) = 'usd' THEN 'USD'
			ELSE 'n/a'
		END AS go_tournament_unit,
		CASE	
			WHEN LOWER(TRIM(go_tournament_opencountry)) = 'korea' THEN 'Korea'
			WHEN LOWER(TRIM(go_tournament_opencountry)) = 'china' THEN 'China'
			WHEN LOWER(TRIM(go_tournament_opencountry)) = 'japan' THEN 'Japan'
			WHEN LOWER(TRIM(go_tournament_opencountry)) = 'china-singapore' THEN 'China-Singapore'
			ELSE 'n/a'
		END AS go_tournament_opencountry,
		CASE	
			WHEN REGEXP_REPLACE(go_tournament_type, '[^가-힣]', '') = '국내' THEN 'National' -- 글자수보다 글자의 길이가 1많음 : 정규표현식을 통해 문자가 아닌부분 제거
			WHEN REGEXP_REPLACE(go_tournament_type, '[^가-힣]', '') = '세계' THEN 'International'
			ELSE 'n/a'
		END AS go_tournament_type
		FROM bronze.go_tournament AS t LEFT JOIN bronze.exchange_rate AS r
		ON t.go_tournament_unit = r.currency_code
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> --------------';

		PRINT '-------------------------------------------------';
		PRINT 'Loading exchange Tables';
		PRINT '-------------------------------------------------';
		-- Loading silver.exchange_rate
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.exchange_rate';
		TRUNCATE TABLE silver.exchange_rate;
		PRINT '>> Inserting Data Into: silver.exchange_rate';

		INSERT INTO silver.exchange_rate(
		currency_code,
		exchange_rate,
		updated_time
		)

		SELECT
			currency_code,
			exchange_rate,
			CAST(CAST(updated_time AS VARCHAR) AS DATE)
		FROM bronze.exchange_rate
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> --------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================';
		PRINT 'Loading Silver Layer is Completed';
		PRINT '    - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
		PRINT '=========================================';

		END TRY
		BEGIN CATCH
				PRINT '========================================='
				PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
				PRINT 'Error Message' + ERROR_MESSAGE();
				PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
				PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
				PRINT '========================================='
		END CATCH
END
GO

EXEC silver.load_silver
