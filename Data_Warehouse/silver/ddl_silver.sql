USE GO_DWH;

/* Build Sliver Layer
Create DDL for Tables */
-- gibo table의 마땅한 pk가 없으므로 조합을 통해 pk 생성(go_black_player + go_white_player + go_date + go_gamename)
IF OBJECT_ID('silver.go_gibo', 'U') IS NOT NULL
	DROP TABLE silver.go_gibo;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE silver.go_gibo(
	Gibo_ID INT IDENTITY(1,1), 
	go_gamename NVARCHAR(200) NOT NULL,
	go_date DATE NOT NULL,
	go_black_player NVARCHAR(50) NOT NULL,
	go_white_player NVARCHAR(50) NOT NULL,
	go_komi FLOAT,
	go_result NVARCHAR(50),
	go_timelimit FLOAT,
	go_byo_yomi_count INT,
	go_byo_yomi_time INT,
	go_rule NVARCHAR(50),
	go_black_player_country NVARCHAR(50),
	go_white_player_country NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE() -- 메타 데이터 컬럼(데이터 흐름추정, 최신성 보장, 데이터 품질 및 감사, 증분 적재관리 등을 위해 추가)
	CONSTRAINT UQ_Gibo_Composite UNIQUE(go_black_player, go_white_player, go_date, go_gamename),
	CONSTRAINT PK_Gibo_ID PRIMARY KEY (Gibo_ID)
);

SELECT
	*
FROM silver.go_gibo

IF OBJECT_ID('silver.go_player_info', 'U') IS NOT NULL
	DROP TABLE silver.go_player_info;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE silver.go_player_info(
	player_ID INT IDENTITY(1,1),
	go_player_name NVARCHAR(50),
	go_player_birthday DATE,
	go_player_YOP FLOAT,
	go_player_experience INT,
	go_player_age INT,
	go_player_country NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE() -- 메타 데이터 컬럼(데이터 흐름추정, 최신성 보장, 데이터 품질 및 감사, 증분 적재관리 등을 위해 추가)
);

SELECT
	*
FROM silver.go_player_info

IF OBJECT_ID('silver.go_tournament', 'U') IS NOT NULL
	DROP TABLE silver.go_tournament;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE silver.go_tournament(
	tournament_ID INT IDENTITY(1,1), 
	go_tournament_name NVARCHAR(1000),
	go_tournament_ext_name NVARCHAR(1000),
	go_tournament_timelimit_second INT,
	go_tournament_method NVARCHAR(50),
	go_tournament_genre NVARCHAR(50),
	go_tournament_prize FLOAT,
	go_tournament_prize_kr FLOAT,
	go_tournament_unit NVARCHAR(50),
	go_tournament_opencountry NVARCHAR(50),
	go_tournament_type NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE() -- 메타 데이터 컬럼(데이터 흐름추정, 최신성 보장, 데이터 품질 및 감사, 증분 적재관리 등을 위해 추가)
);

SELECT
	*
FROM silver.go_tournament

IF OBJECT_ID('silver.exchange_rate', 'U') IS NOT NULL
	DROP TABLE silver.exchange_rate;  -- 테이블을 다시 만들고 싶을때, 기존 테이블이 있으면 drop 시킴
CREATE TABLE silver.exchange_rate(
	exchange_rate_ID INT IDENTITY(1,1), 
	currency_code NVARCHAR(10),
	exchange_rate DECIMAL(10,2),
	updated_time DATE DEFAULT GETDATE(),
	dwh_create_date DATETIME2 DEFAULT GETDATE() -- 메타 데이터 컬럼(데이터 흐름추정, 최신성 보장, 데이터 품질 및 감사, 증분 적재관리 등을 위해 추가)
);

SELECT
	*
FROM silver.exchange_rate

/* Build Silver Layer
Clean & Load (silver.go_gibo) */
-- 테이블의 컬럼을 하나씩 보면서 다른테이블과 연결한것이 있거나 그 자체로 cleansing해야할것이 있다면 하면됨

-- Chcek For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	*
FROM bronze.go_gibo
ORDER BY go_date ASC;

SELECT
	go_gamename, 
	go_date, 
	go_black_player, 
	go_white_player,
	COUNT(*) AS cn
FROM bronze.go_gibo
GROUP BY go_gamename, go_date, go_black_player, go_white_player
HAVING COUNT(*) > 1 
ORDER BY go_date ASC  -- 실행하면 중복된 데이터가 나옴

-- 중복 데이터를 제거하기 위해 하나의 예시에 먼저 적용
SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY go_gamename, go_date, go_black_player, go_white_player ORDER BY go_date DESC) AS rn
FROM bronze.go_gibo
WHERE go_date = '2020-10-31' AND go_black_player = '楊鼎新' AND go_white_player = '柯潔'

SELECT
	COUNT(*)
FROM(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY go_gamename, go_date, go_black_player, go_white_player ORDER BY go_date DESC) AS rn
	FROM bronze.go_gibo
	WHERE go_gamename IS NOT NULL AND go_date IS NOT NULL AND go_black_player IS NOT NULL AND go_white_player IS NOT NULL
)t
WHERE rn = 1 -- 중복되지 않는데이터

SELECT
	COUNT(*)
FROM(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY go_gamename, go_date, go_black_player, go_white_player ORDER BY go_date DESC) AS rn
	FROM bronze.go_gibo
	WHERE go_gamename IS NOT NULL AND go_date IS NOT NULL AND go_black_player IS NOT NULL AND go_white_player IS NOT NULL
)t
WHERE rn != 1 -- 중복되는 데이터 
-- 두 데이터의 합이 전체데이터이 개수와 똑같음 -> 데이터의 중복을 잘 없앰, rn = 1인것만 사용

-- 최종적으로 복합 pk에 대해 중복을 제거하고 사용할 코드
SELECT
	*
FROM(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY go_gamename, go_date, go_black_player, go_white_player ORDER BY go_date DESC) AS flag
	FROM bronze.go_gibo
	WHERE go_gamename IS NOT NULL AND go_date IS NOT NULL AND go_black_player IS NOT NULL AND go_white_player IS NOT NULL
)t
WHERE flag = 1 -- 중복되지 않는데이터

SELECT
	COALESCE(go_date, 'n/a') AS go_player_birthday
FROM bronze.go_gibo
WHERE LEN(go_date) != 10 
OR go_date < '1900-01-01' 
OR go_date > '2100-01-01'    -- 실행결과 아무것도 출력되지 않음 : 조건만족

-- Quality Check
-- Check for unwanted spaces in string values
-- Chekc for unwanted Spaces
-- Expectation: No Results

SELECT
	go_black_player
FROM bronze.go_gibo
WHERE go_black_player != TRIM(go_black_player); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	go_white_player
FROM bronze.go_gibo
WHERE go_white_player != TRIM(go_white_player); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	go_result
FROM bronze.go_gibo
WHERE go_result != TRIM(go_result); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	go_gamename
FROM bronze.go_gibo
WHERE go_gamename != TRIM(go_gamename); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	go_rule
FROM bronze.go_gibo
WHERE go_rule != TRIM(go_rule); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	go_black_player_country
FROM bronze.go_gibo
WHERE go_black_player_country != TRIM(go_black_player_country); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	go_white_player_country
FROM bronze.go_gibo
WHERE go_white_player_country != TRIM(go_white_player_country); -- 실행결과 아무것도 출력되지 않음 : 조건만족

-- 결과값 수정하기 void : Draw로, W+F, W+를 W+R로
SELECT
	DISTINCT go_result
FROM bronze.go_gibo

-- TRIM할게 없으니 컬럼 그대로 사용
SELECT
	go_gamename,
	go_date,
	go_black_player,
	go_white_player,
	go_komi,
	go_result,
	go_timelimit,
	COALESCE(go_byo_yomi_count, 0) AS go_byo_yomi_count,
	COALESCE(go_byo_yomi_time, 0) AS go_byo_yomi_time,
	go_rule,
	go_black_player_country,
	go_white_player_country
FROM(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY go_gamename, go_date, go_black_player, go_white_player ORDER BY go_date DESC) AS flag
	FROM bronze.go_gibo
	WHERE go_gamename IS NOT NULL AND go_date IS NOT NULL AND go_black_player IS NOT NULL AND go_white_player IS NOT NULL
)t
WHERE flag = 1

-- Quality Check
-- Check the consistency of values in low cardinality columns (cst_material_status, cst_gndr)
-- Data Standardization & Consistency

SELECT
	DISTINCT go_black_player_country,
	LEN(go_black_player_country)
FROM bronze.go_gibo
-- 결과가 kr, ch 같은 약어로 나오지만 이 프로젝트에선 약어를 사용하지 않기로, NULL 값도 변경해주어야함 -> case문을 통해 full name으로 변경

SELECT
	DISTINCT go_white_player_country,
	LEN(go_white_player_country)
FROM bronze.go_gibo
-- 결과가 kr, ch 같은 약어로 나오지만 이 프로젝트에선 약어를 사용하지 않기로, NULL 값도 변경해주어야함 -> case문을 통해 full name으로 변경

SELECT
	DISTINCT go_rule
FROM bronze.go_gibo
-- 결과가 약어로 나오지 않기때문에 그대로 사용

SELECT
	DISTINCT go_result
FROM bronze.go_gibo
-- 여러 결과가 나오는데 그중 'W+'로만 나온 표현은 어떻게 이긴지 애매하기때문에 이 결과는 수정이 필요함, void의 경우는 무승부임

-- CASE문을 통해 변경
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

-- 최종적으로 cleansing된 bronze 테이블의 데이터를 빈 silver 테이블에 insert
-- Insert , select를 동시에 실행 해서 집어넣음

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
	CASE
		WHEN go_result = 'void' THEN 'Draw'
		WHEN go_result = 'W+F' THEN 'W+R'
		WHEN go_result = 'W+' THEN 'W+R'
		ELSE go_result
	END AS go_result,
	go_timelimit,
	COALESCE(go_byo_yomi_count, 0) AS go_byo_yomi_count,
	COALESCE(go_byo_yomi_time, 0) AS go_byo_yomi_time,
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

/* Build Silver Layer
Clean & Load (go_player_info) */

SELECT
	*
FROM bronze.go_player_info

-- Chcek For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	go_player_name
FROM bronze.go_player_info
GROUP BY go_player_name
HAVING COUNT(*) > 1 OR go_player_name IS NULL -- 실행결과 아무것도 출력되지 않음 : 조건만족

-- 날짜가 올바른지 확인해보기
SELECT
	COALESCE(go_player_birthday, 'n/a') AS go_player_birthday
FROM bronze.go_player_info
WHERE LEN(go_player_birthday) != 10 
OR go_player_birthday < '1900-01-01' 
OR go_player_birthday > '2100-01-01'        -- 실행결과 아무것도 출력되지 않음 : 조건만족

-- 선수의 경력, 나이 계산하기
SELECT
    CAST(go_player_YOP AS INT)-YEAR(go_player_birthday) AS player_experience,
	(YEAR(GETDATE())-YEAR(go_player_birthday) + 1)AS age
FROM bronze.go_player_info

-- Quality Check
-- Check for unwanted spaces in string values
-- Chekc for unwanted Spaces
-- Expectation: No Results

SELECT
	go_player_country
FROM bronze.go_player_info
WHERE go_player_country != TRIM(go_player_country); -- 실행결과 아무것도 출력되지 않음 : 조건만족

SELECT
	DISTINCT go_player_country,
	LEN(go_player_country)
FROM bronze.go_player_info
-- 결과가 full name으로 나오지만, 글자 길이가 글자수보다 1이 많음 -> case문을 통해 변경

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

-- 최종적으로 cleansing된 bronze 테이블의 데이터를 빈 silver 테이블에 insert
-- Insert , select를 동시에 실행 해서 집어넣음

INSERT INTO silver.go_player_info(
	go_player_name,
	go_player_birthday,
	go_player_YOP,
	go_player_experience,
	go_player_age,
	go_player_country
)

SELECT
	go_player_name,
	go_player_birthday,
	go_player_YOP,
	CAST(go_player_YOP AS INT)-YEAR(go_player_birthday) AS player_experience,
	(YEAR(GETDATE())-YEAR(go_player_birthday) + 1)AS age,
	CASE	
		WHEN LOWER(REGEXP_REPLACE(go_player_country, '[^a-zA-Z]', '')) = 'korea' THEN 'Korea' -- 글자수보다 글자의 길이가 1많음 : 정규표현식을 통해 문자가 아닌부분 제거
		WHEN LOWER(REGEXP_REPLACE(go_player_country, '[^a-zA-Z]', '')) = 'china' THEN 'China'
		ELSE 'n/a'
	END AS go_player_country
FROM bronze.go_player_info

-- Insert 한 후 처음했던 Quality Check해보기
-- Re-run the quality chekc querires from the bronze layer to verify the quality of data in silver layer

SELECT
	*
FROM silver.go_player_info
-- 추가로 더 해야함 일단 보류


/* Build Silver Layer
Clean & Load (go_tournament) */

SELECT
	*
FROM bronze.go_tournament

-- Chcek For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	go_tournament_name
FROM bronze.go_tournament
GROUP BY go_tournament_name
HAVING COUNT(*) > 1 OR go_tournament_name IS NULL -- 실행결과 아무것도 출력되지 않음 : 조건만족

-- 괄호안 부분만 추출하기
SELECT 
    SUBSTRING(
        go_tournament_name, 
        CHARINDEX('(', go_tournament_name) + 1, 
        CHARINDEX(')', go_tournament_name) - CHARINDEX('(', go_tournament_name) - 1
    ) AS extracted_text
FROM bronze.go_tournament

-- Quality Check
-- Check for unwanted spaces in string values
-- Chekc for unwanted Spaces
-- Expectation: No Results

SELECT
	DISTINCT go_tournament_method,
	LEN(go_tournament_method)      
FROM bronze.go_tournament 

SELECT
	DISTINCT go_tournament_unit,
	LEN(go_tournament_unit)
FROM bronze.go_tournament

SELECT
	DISTINCT go_tournament_opencountry,
	LEN(go_tournament_opencountry)
FROM bronze.go_tournament

SELECT
	DISTINCT go_tournament_type,
	LEN(go_tournament_type)      -- 길이가 다름, CASE문, 정규표현식으로 표현하기
FROM bronze.go_tournament



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

SELECT
	*
FROM bronze.go_tournament

SELECT
	*
FROM silver.go_tournament

-- insert 하기
INSERT INTO silver.go_tournament(
	go_tournament_name,
	go_tournament_ext_name,
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
	SUBSTRING(
        go_tournament_name, 
        CHARINDEX('(', go_tournament_name) + 1, 
        CHARINDEX(')', go_tournament_name) - CHARINDEX('(', go_tournament_name) - 1
    ) AS extracted_text,
	go_tournament_timelimit, 
	go_tournament_method,
	CASE
		WHEN go_tournament_timelimit <= 60 THEN '초속기'
		WHEN go_tournament_timelimit > 60 AND go_tournament_timelimit <= 1200 THEN '속기'
		WHEN go_tournament_timelimit > 1200 AND go_tournament_timelimit < 3600 THEN '일반'
		ELSE '장고'
    END AS go_tournament_genre,
	COALESCE(go_tournament_prize, 0),
	COALESCE(ROUND(t.go_tournament_prize * COALESCE(r.exchange_rate, 1), 0), 0)AS go_tournament_prize_kr,
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

/* Build Silver Layer
Clean & Load (go_tournament) */

SELECT
	*
FROM bronze.exchange_rate

-- Chcek For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	currency_code
FROM bronze.exchange_rate
GROUP BY currency_code
HAVING COUNT(*) > 1 OR currency_code IS NULL -- 실행결과 아무것도 출력되지 않음 : 조건만족

-- Quality Check
-- Check for unwanted spaces in string values
-- Chekc for unwanted Spaces
-- Expectation: No Results

SELECT
	DISTINCT currency_code,
	LEN(currency_code)      
FROM bronze.exchange_rate

-- 날짜 타입 변경
SELECT
	CAST(CAST(updated_time AS VARCHAR) AS DATE)
FROM bronze.exchange_rate

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

-- 최종 코드 : 데이터를 insert할때 중복되는것을 막기위해서 table을 truncate 한 후 넣음(각 테이블별로)

-- silver.go_gibo
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

-- silver.go_player_info
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

-- silver.go_tournament
PRINT '>> Truncating Table: silver.go_tournament';
TRUNCATE TABLE silver.go_tournament;
PRINT '>> Inserting Data Into: silver.go_tournamento';

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

-- silver.exchange_rate
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
