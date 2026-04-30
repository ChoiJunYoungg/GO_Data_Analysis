/* Building Gold Layer
*/

SELECT
	*
FROM silver.go_gibo

SELECT
	*
FROM silver.go_player_info

SELECT
	*
FROM silver.go_tournament

SELECT
	*
FROM silver.exchange_rate

-- silver.go_player_info 테이블에 선수의 나이와 경력 컬럼을 추가

-- go_gibo, go_player_info, go_tourament에서 gibo를 기준으로 go_player_info와 left join해서 선수의 나이컬럼 추가, 선수 경력 컬럼추가
-- gibo를 기준으로 go_tourament와 left join해서 상금 컬럼을 추가

SELECT
	g.Gibo_ID,
	g.go_gamename,
	t.go_tournament_prize_kr,
	g.go_date,
	g.go_black_player,
	g.go_white_player,
	g.go_komi,
	CASE
		WHEN g.go_result = 'Void' THEN 'Draw'
		WHEN g.go_result = 'W+F' THEN 'W+R'
		WHEN g.go_result = 'W+' THEN 'W+R'
		ELSE g.go_result
	END AS go_result,
	g.go_timelimit,
	g.go_byo_yomi_count,
	g.go_byo_yomi_time,
	g.go_rule,
	g.go_black_player_country,
	g.go_white_player_country,
	i.go_player_country,
	i2.go_player_country,
	g.dwh_create_date,
	i.go_player_birthday,
	i.go_player_experience,
	i.go_player_age,
	i2.go_player_birthday,
	i2.go_player_experience,
	i2.go_player_age
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')

SELECT
	*
FROM silver.go_gibo

SELECT
	*
FROM silver.go_tournament

SELECT
	Gibo_ID,
	COUNT(*)
FROM(
	SELECT
		g.Gibo_ID,
		g.go_gamename,
		t.go_tournament_prize_kr,
		g.go_date,
		g.go_black_player,
		g.go_white_player,
		g.go_komi,
		g.go_result,
		g.go_timelimit,
		g.go_byo_yomi_count,
		g.go_byo_yomi_time,
		g.go_rule,
		g.go_black_player_country,
		g.go_white_player_country,
		g.dwh_create_date,
		i.go_player_birthday
	FROM silver.go_gibo AS g 
	LEFT JOIN silver.go_player_info AS i
	ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
	LEFT JOIN silver.go_player_info AS i2 
	ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
	LEFT JOIN silver.go_tournament AS t
	ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
)t
GROUP BY Gibo_ID
HAVING COUNT(*) > 1  -- 아무결과가 없음 : 중복되는 데이터가 없음

SELECT
	DISTINCT g.go_gamename,
	t.go_tournament_prize_kr
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%') 
GROUP BY g.go_gamename, t.go_tournament_prize_kr
HAVING t.go_tournament_prize_kr IS NULL
-- NULL 값이 있는 부분을 대체해야함

SELECT
	DISTINCT g.go_gamename,
	g.go_timelimit,
	COALESCE(g.go_byo_yomi_count, 0) AS go_byo_yomi_count,
	COALESCE(g.go_byo_yomi_time, 0) AS go_byo_yomi_time
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
GROUP BY g.go_gamename, g.go_timelimit, g.go_byo_yomi_count,g.go_byo_yomi_time
-- NULL 값을 0으로, 값이 다른 부분을 대체해야함

-- 흑이 이겼을 때, 백이 이겼을때의 결과값을 알 수 있는 flag만들기

-- 흑이 이겼을때 
SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result LIKE 'B+[0-9]%'  -- 흑의 계가승 대국은 218개

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result LIKE 'B+R%'  -- 흑의 불계승 대국은 1044개

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result = 'B+T'  -- 흑의 시간승 대국은 10개

-- 총 1272국

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result LIKE '%B%' -- 흑의 총 대국 수 1272국 위의 결과와 일치


--백이 이겼을 때 

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result = 'W+T' -- 백의 시간승 대국은 8개

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result LIKE 'W+[0-9]%'  -- 백의 계가승 대국은 181개

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result = 'W+R' -- 백의 불계승 대국은 1190개

SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%') 
WHERE g.go_result LIKE '%W%' -- 백의 총 대국은 1381개 : 2개의 대국이 모자름

SELECT
	*
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%') 
WHERE g.go_result = 'W+F' -- W+F를 W+R로 바꿔야함

SELECT
	*
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%') 
WHERE g.go_result = 'W+' -- W+F를 W+R로 바꿔야함


-- 무승부 대국
SELECT
	COUNT(*)
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result = 'void' -- 무승부 대국은 1개 , void를 draw로 바꿔야함


-----------------------


SELECT
	DISTINCT SUM(B_win) OVER() AS sm1,
	SUM(B_timewin) OVER() AS sm2,
	SUM(W_win) OVER() AS sm3,
	SUM(W_timewin) OVER() AS sm4,
	cn
FROM(
	SELECT
		g.go_result,
		CASE
			WHEN g.go_result LIKE '%B%' THEN 1
			ELSE 0
			END AS B_win,
		CASE
			WHEN g.go_result LIKE '%B+T%' THEN 1
			ELSE 0
			END AS B_timewin,
		CASE
			WHEN g.go_result LIKE '%W%' THEN 1
			ELSE 0
			END AS W_win,
		CASE
			WHEN g.go_result LIKE '%W+T%' THEN 1
			ELSE 0
			END AS W_timewin,
		COUNT(*) OVER() AS cn
	FROM silver.go_gibo AS g 
	LEFT JOIN silver.go_player_info AS i
	ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
	LEFT JOIN silver.go_player_info AS i2 
	ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
	LEFT JOIN silver.go_tournament AS t
	ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
)t



SELECT
	*
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result = 'B+T'

SELECT
	*
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE g.go_result = 'W+T'





SELECT
	DISTINCT g.go_result
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')


SELECT
	g.Gibo_ID,
	g.go_gamename,
	t.go_tournament_prize_kr,
	g.go_date,
	g.go_black_player,
	g.go_white_player,
	g.go_komi,
	CASE
		WHEN g.go_result = 'Void' THEN 'Draw'
		WHEN g.go_result = 'W+F' THEN 'W+R'
		WHEN g.go_result = 'W+' THEN 'W+R'
		ELSE g.go_result
	END AS go_result,
	CASE
		WHEN g.go_result LIKE 'B+[0-9]%' THEN 1
		ELSE 0
		END AS B_cal_win,
	CASE
		WHEN g.go_result LIKE 'B+R%' THEN 1
		ELSE 0
		END AS B_resign_win,
	CASE
		WHEN g.go_result LIKE 'B+T' THEN 1
		ELSE 0
		END AS B_Time_win,
	CASE
		WHEN g.go_result LIKE 'W+[0-9]%' THEN 1
		ELSE 0
		END AS W_cal_win,
	CASE
		WHEN g.go_result LIKE 'W+R%' THEN 1
		ELSE 0
		END AS W_resign_win,
	CASE
		WHEN g.go_result LIKE 'W+T' THEN 1
		ELSE 0
		END AS W_Time_win,
	CASE
		WHEN g.go_result LIKE '%Draw%' THEN 1
		ELSE 0
		END AS Draw,
	g.go_timelimit,
	COALESCE(g.go_byo_yomi_count, 0) AS go_byo_yomi_count,
	COALESCE(g.go_byo_yomi_time, 0) AS go_byo_yomi_time,
	g.go_rule,
	g.go_black_player_country,
	g.go_white_player_country
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%')
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')


-- case 문의 대국 수 총 합이 전체 대국 수 와 맞는지 확인해보기
SELECT
	*
FROM silver.go_tournament

SELECT
	DISTINCT SUM(B_cal_win) OVER() AS sm1,
	SUM(B_resign_win) OVER() AS sm2,
	SUM(B_Time_win) OVER() AS sm3,
	SUM(W_cal_win) OVER() AS sm4,
	SUM(W_resign_win) OVER() AS sm5,
	SUM(W_Time_win) OVER() AS sm6,
	SUM(Draw) OVER() AS sm7,
	COUNT(*) OVER() AS cn
FROM(SELECT
	g.Gibo_ID,
	g.go_gamename,
	t.go_tournament_method,
	t.go_tournament_genre,
	t.go_tournament_opencountry,
	t.go_tournament_type,
	t.go_tournament_prize_kr,
	g.go_date,
	g.go_black_player,
	g.go_white_player,
	g.go_komi,
	go_result,
	CASE
		WHEN g.go_result LIKE 'B+[0-9]%' THEN 1
		ELSE 0
		END AS B_cal_win,
	CASE
		WHEN g.go_result LIKE 'B+R%' THEN 1
		ELSE 0
		END AS B_resign_win,
	CASE
		WHEN g.go_result LIKE 'B+T' THEN 1
		ELSE 0
		END AS B_Time_win,
	CASE
		WHEN g.go_result LIKE 'W+[0-9]%' THEN 1
		ELSE 0
		END AS W_cal_win,
	CASE
		WHEN g.go_result LIKE 'W+R%' THEN 1
		ELSE 0
		END AS W_resign_win,
	CASE
		WHEN g.go_result LIKE 'W+T' THEN 1
		ELSE 0
		END AS W_Time_win,
	CASE
		WHEN g.go_result LIKE '%Draw%' THEN 1
		ELSE 0
		END AS Draw,
	g.go_timelimit,
	go_byo_yomi_count,
	go_byo_yomi_time,
	g.go_rule,
	g.go_black_player_country,
	g.go_white_player_country,
	g.dwh_create_date
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%'))t


SELECT
	*
FROM silver.go_gibo

SELECT
	*
FROM silver.go_player_info

SELECT
	*
FROM silver.go_tournament

SELECT 
	DISTINCT g.go_gamename,
	t.go_tournament_prize_kr,
	t.go_tournament_ext_name
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', TRIM(t.go_tournament_ext_name), '%')
WHERE t.go_tournament_prize_kr IS NULL -- t.tournament_name과 g.go_gamename이 일부분만 일치해서 조인이 안됨, 일부분만겹치는 경우는 해결하지 못해 직접 추가함




SELECT -- 임시로 없앰 (price, method, genre, opencountry, type)
	DISTINCT go_gamename,
	go_tournament_method,
	go_tournament_genre,
	go_tournament_opencountry,
	go_tournament_type
FROM(
SELECT
	g.Gibo_ID,
	g.go_gamename,
	t.go_tournament_ext_name,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_method, '전만법')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_method, '피셔')
		ELSE t.go_tournament_method
	END AS go_tournament_method,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_genre, '일반')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_genre, '속기')
		ELSE t.go_tournament_genre
	END AS go_tournament_genre,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		ELSE t.go_tournament_opencountry
	END AS go_tournament_opencountry,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_type, 'National')
		ELSE t.go_tournament_type
	END AS go_tournament_type,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_prize_kr, 75000000)
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_prize_kr, 100000000)
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_prize_kr, 600000000)
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_prize_kr, 500000000)
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_prize_kr, 30000000)
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_prize_kr, 350000000)
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_prize_kr, 230000000)
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_prize_kr, 390000000)
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_prize_kr, 220000000)
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_prize_kr, 0)
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_prize_kr, 15000000)
		ELSE t.go_tournament_prize_kr
		END AS go_tournament_prize_kr,
	g.go_date,
	g.go_black_player,
	g.go_white_player,
	g.go_komi,
	go_result
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
WHERE t.go_tournament_prize_kr IS NULL OR t.go_tournament_genre IS NULL OR t.go_tournament_opencountry IS NULL OR t.go_tournament_type IS NULL
)t


-------------------------------------- tournament 테이블과 조인되지 않은 부분 수정
SELECT
	g.Gibo_ID,
	g.go_gamename AS gamename,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_method, '전만법')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_method, '피셔')
		ELSE t.go_tournament_method
	END AS t_method,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_genre, '일반')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_genre, '속기')
		ELSE t.go_tournament_genre
	END AS t_genre,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		ELSE t.go_tournament_opencountry
	END AS t_opencountry,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_type, 'National')
		ELSE t.go_tournament_type
	END AS t_type,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_prize_kr, 75000000)
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_prize_kr, 100000000)
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_prize_kr, 600000000)
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_prize_kr, 500000000)
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_prize_kr, 30000000)
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_prize_kr, 350000000)
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_prize_kr, 230000000)
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_prize_kr, 390000000)
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_prize_kr, 220000000)
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_prize_kr, 0)
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_prize_kr, 15000000)
		ELSE t.go_tournament_prize_kr
		END AS t_prize_kr,
	g.go_date AS go_date,
	g.go_black_player AS b_player,
	g.go_white_player AS w_player,
	g.go_komi AS komi,
	go_result AS result,
	CASE
		WHEN g.go_result LIKE 'B+[0-9]%' THEN 1
		ELSE 0
		END AS B_cal_win,
	CASE
		WHEN g.go_result LIKE 'B+R%' THEN 1
		ELSE 0
		END AS B_resign_win,
	CASE
		WHEN g.go_result LIKE 'B+T' THEN 1
		ELSE 0
		END AS B_Time_win,
	CASE
		WHEN g.go_result LIKE 'W+[0-9]%' THEN 1
		ELSE 0
		END AS W_cal_win,
	CASE
		WHEN g.go_result LIKE 'W+R%' THEN 1
		ELSE 0
		END AS W_resign_win,
	CASE
		WHEN g.go_result LIKE 'W+T' THEN 1
		ELSE 0
		END AS W_Time_win,
	CASE
		WHEN g.go_result LIKE '%Draw%' THEN 1
		ELSE 0
		END AS Draw,
	g.go_rule,
	g.go_black_player_country AS b_p_country,
	g.go_white_player_country AS w_p_country,
	i.go_player_age,
	i2.go_player_age,
	g.dwh_create_date
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%') 

SELECT
	*
FROM silver.go_player_info


-------------------------------------- player_info 테이블과 조인했을때 제대로 안된 부분이 하나 존재
SELECT
	*
FROM(
SELECT
	g.Gibo_ID,
	g.go_gamename AS gamename,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_method, '전만법')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_method, '피셔')
		ELSE t.go_tournament_method
	END AS t_method,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_genre, '일반')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_genre, '속기')
		ELSE t.go_tournament_genre
	END AS t_genre,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		ELSE t.go_tournament_opencountry
	END AS t_opencountry,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_type, 'National')
		ELSE t.go_tournament_type
	END AS t_type,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_prize_kr, 75000000)
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_prize_kr, 100000000)
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_prize_kr, 600000000)
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_prize_kr, 500000000)
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_prize_kr, 30000000)
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_prize_kr, 350000000)
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_prize_kr, 230000000)
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_prize_kr, 390000000)
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_prize_kr, 220000000)
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_prize_kr, 0)
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_prize_kr, 15000000)
		ELSE t.go_tournament_prize_kr
		END AS t_prize_kr,
	g.go_date AS go_date,
	g.go_black_player AS b_player,
	g.go_white_player AS w_player,
	g.go_komi AS komi,
	go_result AS result,
	CASE
		WHEN g.go_result LIKE 'B+[0-9]%' THEN 1
		ELSE 0
		END AS B_cal_win,
	CASE
		WHEN g.go_result LIKE 'B+R%' THEN 1
		ELSE 0
		END AS B_resign_win,
	CASE
		WHEN g.go_result LIKE 'B+T' THEN 1
		ELSE 0
		END AS B_Time_win,
	CASE
		WHEN g.go_result LIKE 'W+[0-9]%' THEN 1
		ELSE 0
		END AS W_cal_win,
	CASE
		WHEN g.go_result LIKE 'W+R%' THEN 1
		ELSE 0
		END AS W_resign_win,
	CASE
		WHEN g.go_result LIKE 'W+T' THEN 1
		ELSE 0
		END AS W_Time_win,
	CASE
		WHEN g.go_result LIKE '%Draw%' THEN 1
		ELSE 0
		END AS Draw,
	g.go_rule,
	g.go_black_player_country AS b_p_country,
	g.go_white_player_country AS w_p_country,
	i.go_player_age AS p_age1,
	i2.go_player_age AS p_age2,
	g.dwh_create_date
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%') 
)t
WHERE p_age1 IS NULL AND p_age2 IS NULL -- 제대로 join되지 않은 행이 1개 존재함

---------------------------------------------------------- 최종 수정
SELECT
	GIbo_ID,
	gamename,
	t_method,
	t_genre,
	t_opencountry,
	t_type,
	t_prize_kr,
	go_date,
	b_player,
	w_player,
	komi,
	result,
	B_cal_win,
	B_resign_win,
	B_Time_win,
	W_cal_win,
	W_resign_win,
	W_Time_win,
	Draw,
	go_rule,
	b_p_country,
	w_p_country,
	p_age1,
	p_age2,
	dwh_create_date
FROM(
SELECT
	g.Gibo_ID,
	g.go_gamename AS gamename,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_method, '전만법')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_method, '피셔')
		ELSE t.go_tournament_method
	END AS t_method,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_genre, '일반')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_genre, '속기')
		ELSE t.go_tournament_genre
	END AS t_genre,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		ELSE t.go_tournament_opencountry
	END AS t_opencountry,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_type, 'National')
		ELSE t.go_tournament_type
	END AS t_type,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_prize_kr, 75000000)
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_prize_kr, 100000000)
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_prize_kr, 600000000)
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_prize_kr, 500000000)
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_prize_kr, 30000000)
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_prize_kr, 350000000)
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_prize_kr, 230000000)
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_prize_kr, 390000000)
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_prize_kr, 220000000)
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_prize_kr, 0)
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_prize_kr, 15000000)
		ELSE t.go_tournament_prize_kr
		END AS t_prize_kr,
	g.go_date AS go_date,
	CASE
		WHEN g.go_black_player LIKE '卞相_' THEN '卞相壹'
		ELSE g.go_black_player
		END AS b_player,
	-- g.go_black_player AS b_player,
	g.go_white_player AS w_player,
	g.go_komi AS komi,
	go_result AS result,
	CASE
		WHEN g.go_result LIKE 'B+[0-9]%' THEN 1
		ELSE 0
		END AS B_cal_win,
	CASE
		WHEN g.go_result LIKE 'B+R%' THEN 1
		ELSE 0
		END AS B_resign_win,
	CASE
		WHEN g.go_result LIKE 'B+T' THEN 1
		ELSE 0
		END AS B_Time_win,
	CASE
		WHEN g.go_result LIKE 'W+[0-9]%' THEN 1
		ELSE 0
		END AS W_cal_win,
	CASE
		WHEN g.go_result LIKE 'W+R%' THEN 1
		ELSE 0
		END AS W_resign_win,
	CASE
		WHEN g.go_result LIKE 'W+T' THEN 1
		ELSE 0
		END AS W_Time_win,
	CASE
		WHEN g.go_result LIKE '%Draw%' THEN 1
		ELSE 0
		END AS Draw,
	g.go_rule,
	g.go_black_player_country AS b_p_country,
	g.go_white_player_country AS w_p_country,
	CASE
		WHEN g.go_black_player LIKE '卞相_' THEN COALESCE(i.go_player_age, 30)
		ELSE i.go_player_age
		END AS p_age1,
	i2.go_player_age AS p_age2,
	g.dwh_create_date
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%') 
)t

--- Create view

GO
CREATE VIEW gold.go_gibo AS
SELECT
	GIbo_ID,
	gamename,
	t_method,
	t_genre,
	t_opencountry,
	t_type,
	t_prize_kr,
	go_date,
	b_player,
	w_player,
	komi,
	result,
	B_cal_win,
	B_resign_win,
	B_Time_win,
	W_cal_win,
	W_resign_win,
	W_Time_win,
	Draw,
	go_rule,
	b_p_country,
	w_p_country,
	p_age1,
	p_age2,
	dwh_create_date
FROM(
SELECT
	g.Gibo_ID,
	g.go_gamename AS gamename,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_method, '전만법')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_method, '피셔')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_method, '고려시간')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_method, '초읽기')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_method, '피셔')
		ELSE t.go_tournament_method
	END AS t_method,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_genre, '일반')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_genre, '속기')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_genre, '초속기')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_genre, '장고')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_genre, '속기')
		ELSE t.go_tournament_genre
	END AS t_genre,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_opencountry, 'China')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_opencountry, 'Korea')
		ELSE t.go_tournament_opencountry
	END AS t_opencountry,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_type, 'National')
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_type, 'International')
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_type, 'National')
		ELSE t.go_tournament_type
	END AS t_type,
	CASE
		WHEN g.go_gamename LIKE '%ハナ銀行%' THEN COALESCE(t.go_tournament_prize_kr, 75000000)
		WHEN g.go_gamename LIKE '%手山%' THEN COALESCE(t.go_tournament_prize_kr, 100000000)
		WHEN g.go_gamename LIKE '%氏%' THEN COALESCE(t.go_tournament_prize_kr, 600000000)
		WHEN g.go_gamename LIKE '%農心杯%' THEN COALESCE(t.go_tournament_prize_kr, 500000000)
		WHEN g.go_gamename LIKE '%LG%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%三星%' THEN COALESCE(t.go_tournament_prize_kr, 300000000)
		WHEN g.go_gamename LIKE '%安東%' THEN COALESCE(t.go_tournament_prize_kr, 30000000)
		WHEN g.go_gamename LIKE '%北海新繹杯%' THEN COALESCE(t.go_tournament_prize_kr, 350000000)
		WHEN g.go_gamename LIKE '%浙江平湖%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%桐山杯日中%' THEN COALESCE(t.go_tournament_prize_kr, 44000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%夢百合杯%' THEN COALESCE(t.go_tournament_prize_kr, 400000000)
		WHEN g.go_gamename LIKE '%春蘭杯%' THEN COALESCE(t.go_tournament_prize_kr, 230000000)
		WHEN g.go_gamename LIKE '%衢州爛柯杯%' THEN COALESCE(t.go_tournament_prize_kr, 390000000)
		WHEN g.go_gamename LIKE '%運動%' THEN COALESCE(t.go_tournament_prize_kr, 220000000)
		WHEN g.go_gamename LIKE '%碁棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%棋棋王%' THEN COALESCE(t.go_tournament_prize_kr, 33000000)
		WHEN g.go_gamename LIKE '%アジア%' THEN COALESCE(t.go_tournament_prize_kr, 0)
		WHEN g.go_gamename LIKE '%乙級リ%' THEN COALESCE(t.go_tournament_prize_kr, 15000000)
		ELSE t.go_tournament_prize_kr
		END AS t_prize_kr,
	g.go_date AS go_date,
	CASE
		WHEN g.go_black_player LIKE '卞相_' THEN '卞相壹'
		ELSE g.go_black_player
		END AS b_player,
	-- g.go_black_player AS b_player,
	g.go_white_player AS w_player,
	g.go_komi AS komi,
	go_result AS result,
	CASE
		WHEN g.go_result LIKE 'B+[0-9]%' THEN 1
		ELSE 0
		END AS B_cal_win,
	CASE
		WHEN g.go_result LIKE 'B+R%' THEN 1
		ELSE 0
		END AS B_resign_win,
	CASE
		WHEN g.go_result LIKE 'B+T' THEN 1
		ELSE 0
		END AS B_Time_win,
	CASE
		WHEN g.go_result LIKE 'W+[0-9]%' THEN 1
		ELSE 0
		END AS W_cal_win,
	CASE
		WHEN g.go_result LIKE 'W+R%' THEN 1
		ELSE 0
		END AS W_resign_win,
	CASE
		WHEN g.go_result LIKE 'W+T' THEN 1
		ELSE 0
		END AS W_Time_win,
	CASE
		WHEN g.go_result LIKE '%Draw%' THEN 1
		ELSE 0
		END AS Draw,
	g.go_rule,
	g.go_black_player_country AS b_p_country,
	g.go_white_player_country AS w_p_country,
	CASE
		WHEN g.go_black_player LIKE '卞相_' THEN COALESCE(i.go_player_age, 30)
		ELSE i.go_player_age
		END AS p_age1,
	i2.go_player_age AS p_age2,
	g.dwh_create_date
FROM silver.go_gibo AS g 
LEFT JOIN silver.go_tournament AS t
ON g.go_gamename LIKE CONCAT('%', t.go_tournament_ext_name, '%')
LEFT JOIN silver.go_player_info AS i
ON i.go_player_name LIKE CONCAT('%(', g.go_black_player, ')%')
LEFT JOIN silver.go_player_info AS i2 
ON i2.go_player_name LIKE CONCAT('%(', g.go_white_player, ')%') 
)t
GO
