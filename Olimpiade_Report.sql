-- 120 years of Olympic history: athletes and results

-- 1. Jumlah Olimpiade
SELECT
	count(DISTINCT year) as 'Total Olimpiade' 
FROM atlit
ORDER BY year ASC

/* output
+-----------------+
| Total Olimpiade |
+-----------------+
|              35 |
+-----------------+
*/

-- 2. Jumlah Olimpiade berdasarkan City
SELECT
	DISTINCT Year, Season, City
FROM atlit
ORDER BY Year ASC
/*
+------+--------+------------------------+
| Year | Season | City                   |
+------+--------+------------------------+
| 1896 | Summer | Athina                 |
| 1900 | Summer | Paris                  |
....
| 2014 | Winter | Sochi                  |
| 2016 | Summer | Rio de Janeiro         |
+------+--------+------------------------+
*/

-- 3 Jumlah Partisipan terendah & tertinggi
with all_countries as
              (select games, nr.region
              from atlit oh
              join noc_regions nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(*) as total_countries
              from all_countries
              group by games)
      select DISTINCT
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
			
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
			
from tot_countries
order by 1;
/*
+------------------+-------------------+
| Lowest_Countries | Highest_Countries |
+------------------+-------------------+
|  - 12            | 2016 Summer - 204 |
+------------------+-------------------+
*/

-- 4. Negara yang Mengikuti Semua Event Olimpiade
SELECT 
	n.region, COUNT(DISTINCT games) AS no_of_years 
FROM atlit a
JOIN noc_regions n on a.noc = n.noc
GROUP BY team
Having Count(Distinct Games) = (Select Count(Distinct Games) From atlit)
ORDER BY no_of_years DESC
/*
+-------------+-------------+
| region      | no_of_years |
+-------------+-------------+
| France      |          51 |
| UK          |          51 |
| Switzerland |          51 |
| Italy       |          51 |
+-------------+-------------+
*/

-- 5. Olahraga yang diadakan ketika musim panas (summer)
 WITH t1 as(
-- jumlah olahraga
SELECT
    count(DISTINCT Games) as total_summer_games from atlit
    where season = 'summer'),
t2 as(
-- sport in every olim
SELECT
    DISTINCT games, sport from atlit
    WHERE season = 'summer'),
t3 as(
SELECT
    sport, count(*) as total_play from t2
GROUP BY sport
)
SELECT * from t3
JOIN t1 on t1.total_summer_games = t3.total_play;
/* output
+------------+------------+--------------------+
| sport      | total_play | total_summer_games |
+------------+------------+--------------------+
| Athletics  |         29 |                 29 |
| Cycling    |         29 |                 29 |
| Fencing    |         29 |                 29 |
| Gymnastics |         29 |                 29 |
| Swimming   |         29 |                 29 |
+------------+------------+--------------------+
*/

-- 6. Olahraga yang hanya dimainkan sekali saja
WITH 
t1 as
(
	SELECT DISTINCT sport, games from atlit),
t2 as
(
	SELECT sport, count(1) as played from t1
	GROUP BY sport)
select 
    t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.played = 1 
order by t1.sport;	
/* output
+---------------------+--------+-------------+
| sport               | played | games       |
+---------------------+--------+-------------+
| Aeronautics         |      1 | 1936 Summer |
| Basque Pelota       |      1 | 1900 Summer |
| Cricket             |      1 | 1900 Summer |
| Croquet             |      1 | 1900 Summer |
| Jeu De Paume        |      1 | 1908 Summer |
| Military Ski Patrol |      1 | 1924 Winter |
| Motorboating        |      1 | 1908 Summer |
| Racquets            |      1 | 1908 Summer |
| Roque               |      1 | 1904 Summer |
| Rugby Sevens        |      1 | 2016 Summer |
+---------------------+--------+-------------+
*/

-- 7. Total Pertandingan Setiap Olimpiade
WITH
t1 as(
	SELECT DISTINCT games, sport from atlit
	ORDER BY games),
t2 as(
SELECT
    games, count(sport) as total from t1
    GROUP BY games)
select
    DISTINCT t1.games, total from t2
JOIN t1 on t1.games = t2.games
ORDER BY total DESC
/* output
+-------------+-------+
| games       | total |
+-------------+-------+
| 2000 Summer |    34 |
| 2004 Summer |    34 |
| 2008 Summer |    34 |
| 2016 Summer |    34 |
| 2012 Summer |    32 |
| 1996 Summer |    31 |
| 1992 Summer |    29 |
...
| 1988 Summer |    27 |
+-------------+-------+
*/

-- 8. Peraih Medali Emas Tertua
with 
temp as
       (select name,sex,cast(case when age = 'NA' then '0' else age end as int) as age
        ,team,games,city,sport, event, medal from atlit),
ranking as
        (select *, rank() over(order by age desc) as rnk
         from temp
         where medal='Gold')
select * from ranking
where rnk = 1;
/* output
+-------------------+------+------+---------------+-------------+-----------+----------+--------------------------------------------------+-------+-----+
| name              | sex  | age  | team          | games       | city      | sport    | event                                            | medal | rnk |
+-------------------+------+------+---------------+-------------+-----------+----------+--------------------------------------------------+-------+-----+
| Charles Jacobus   | M    |   64 | United States | 1904 Summer | St. Louis | Roque    | Roque Men's Singles                              | Gold  |   1 |
| Oscar Gomer Swahn | M    |   64 | Sweden        | 1912 Summer | Stockholm | Shooting | Shooting Men's Running Target, Single Shot, Team | Gold  |   1 |
+-------------------+------+------+---------------+-------------+-----------+----------+--------------------------------------------------+-------+-----+
*/

-- 9. Ratio Jumlah Atlit Pria dan Wanita
with t1 as
        	(select sex, count(1)/74522 as jumlah
        	from atlit
        	group by sex),
        t2 as
        	(select *, row_number() over(order by jumlah) as rn
        	 from t1)
SELECT
    sex,jumlah/74522 as jumlah 
FROM t2
/*
+------+------------+
| sex  | jumlah     |
+------+------------+
| F    | 0.00001342 |
| M    | 0.00003540 |
+------+------------+
*/

-- 10. Atlit yang Mendapatkan Medali Emas Lebih dari 5
SELECT 
    name, count(*) as total
FROM atlit
WHERE Medal = 'gold'
GROUP BY name,team
HAVING total>5
ORDER BY total DESC
/* output
+-------------------------------------------------+-------+
| name                                            | total |
+-------------------------------------------------+-------+
| Michael Fred Phelps, II                         |    23 |
| Raymond Clarence "Ray" Ewry                     |    10 |
....
| Gerard Theodor Hubert Van Innis                 |     6 |
| Maria Valentina Vezzali                         |     6 |
+-------------------------------------------------+-------+
*/

-- 11. Atlit yang pernah mendapatkan semua jenis medali
SELECT
    name, count(*) as total FROM atlit
WHERE Medal in ('gold','silver','bronze')
GROUP BY name,team
HAVING total>5
ORDER BY total DESC
/*
+--------------------------------------------------------------------+-------+
| name                                                               | total |
+--------------------------------------------------------------------+-------+
| Michael Fred Phelps, II                                            |    28 |
| Larysa Semenivna Latynina (Diriy-)                                 |    18 |
...
| Leontine Martha Henrica Petronella "Leontien" Zijlaard-van Moorsel |     6 |
| Armin Zggeler                                                      |     6 |
| Zou Kai                                                            |     6 |
+--------------------------------------------------------------------+-------+
*/

-- 12. Negara yang Paling banyak mendapatkan mendali
WITH
t1 as(
    SELECT 
        Team, count(*) as jumlah from atlit
    WHERE Medal <> 'NA'
    GROUP BY Team
    ORDER BY jumlah
),
t2 as(
    SELECT 
        *, DENSE_RANK() over(ORDER BY jumlah DESC) as urutan 
        FROM t1
)
SELECT
    *
FROM t2
where urutan <5
/*
+---------------+--------+--------+
| Team          | jumlah | urutan |
+---------------+--------+--------+
| United States |   5219 |      1 |
| Soviet Union  |   2451 |      2 |
| Germany       |   1984 |      3 |
| Great Britain |   1673 |      4 |
+---------------+--------+--------+
*/