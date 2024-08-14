CREATE TABLE IPL_DATA(
	id INT,
	city VARCHAR(50),
	date DATE,
	player_of_match VARCHAR(50),
	venue VARCHAR(50),
	neutral_venue INT,
	team1 VARCHAR(50),
	team2 VARCHAR(50),
	toss_winner VARCHAR(50),
	toss_decision VARCHAR(50),
	winner VARCHAR(50),
	result VARCHAR(50),
	result_margin INT,
	eliminator VARCHAR(10),
	method VARCHAR(10),
	umpire1 VARCHAR(50),
	umpire2 VARCHAR(50)
);
alter table ipl_data alter column venue type varchar(100);

SELECT * from ipl_data;
copy IPL_data from 'C:\Program Files\PostgreSQL\16\data\IPL Dataset\IPL_matches.csv' delimiter ',' csv header;


CREATE TABLE match_details (
    id INT,
    inning INT,
    over INT,
    ball INT,
    batsman VARCHAR(100),
    non_striker VARCHAR(100),
    bowler VARCHAR(100),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    is_wicket INT,
    dismissal_kind VARCHAR(100),
    player_dismissed VARCHAR(100),
    fielder VARCHAR(100),
    extras_type VARCHAR(100),
    batting_team VARCHAR(100),
    bowling_team VARCHAR(100)
);
SELECT * from match_details;

copy match_details from 'C:\Program Files\PostgreSQL\16\data\IPL Dataset\IPL_Ball.csv' delimiter ',' csv header;

--1*
SELECT 
    batsman,
    SUM(batsman_runs) AS total_runs,
    COUNT (ball) AS balls_faced,
    SUM(batsman_runs)*100*1.0/ count (ball) AS strike_rate
	
FROM 
    match_details
where not (extras_type= 'wide')
GROUP BY 
    batsman
HAVING 
    count (ball) >= 500
ORDER BY 
    strike_rate DESC
LIMIT 10;
--2*
SELECT 
    batsman,
    SUM(batsman_runs) AS total_runs,
	SUM (is_wicket) as wicket,
    (SUM(batsman_runs)*1.0/ sum(is_wicket)) as batsman_average
from match_details
group by batsman
	having COUNT(DISTINCT id)>28
order by batsman_average desc
LIMIT 10;

--3*
SELECT 
    batsman,
    sum(case 
	when batsman_runs= 4 then 4
	when batsman_runs= 6 then 6
	else 0
	end) as boundries_scored,
	sum(batsman_runs) as total_runs,
    (sum(case 
	when batsman_runs= 4 then 4
	when batsman_runs= 6 then 6
	else 0
	end) *100*1.0 /nullif( sum(batsman_runs),0)) as Boundary_Percentage

from match_details
group by batsman
having COUNT(DISTINCT id)>28
order by Boundary_Percentage desc
limit 10;

--4*
select
     bowler,
     count(*) as balls_bowled,
     sum (total_runs) as runs_conceded,
     sum(case when ball=6 then 1 else 0 end) as overs_bowled,  
     sum (total_runs)*1.0/nullif(sum(case when ball=6 then 1 else 0 end),0) as economy
from match_details
group by bowler
having count (ball)>=500
order by economy asc
limit 10;
    
--5*
select
     bowler,
     count(ball) as balls_bowled,
     sum(is_wicket) as wicket_taken,
     count(ball)*1.0 /nullif(sum(is_wicket),0) as Strike_Rate
from  match_details
group by bowler
having count (ball)>=500
order by Strike_Rate asc
limit 10;


--6*
SELECT 
     batsman,B1.batting_strike_rate, B2.Bowling_Strike_Rate
     FROM (SELECT batsman,SUM(batsman_runs)*100*1.0/ count (ball) AS batting_strike_rate FROM  match_details where not (extras_type= 'wide')
           GROUP BY batsman having count (ball)>=500) B1  

  INNER JOIN 
     (SELECT bowler, count(ball)*1.0 /nullif(sum(is_wicket),0) as Bowling_Strike_Rate from  match_details
       GROUP BY bowler having count (ball)>=300) B2 
	ON B1.batsman= B2.BOWLER
ORDER BY B1.batting_strike_rate DESC, B2.Bowling_Strike_Rate ASC
LIMIT 10;


--7*
SELECT batsman,
    SUM(batsman_runs) AS total_runs,
    COUNT (ball) AS balls_faced,
    CASE WHEN SUM(batsman_runs)*100*1.0/ count (ball) > 120 THEN SUM(batsman_runs)*100*1.0/ count (ball) ELSE 0 END AS strike_rate,
    CASE WHEN SUM(batsman_runs)*1.0/ sum(is_wicket) > 35 THEN SUM(batsman_runs)*1.0/ sum(is_wicket) ELSE 0 END as batsman_average,
	CASE WHEN dismissal_kind= 'caught' then count(dismissal_kind) else 0 end AS Catches_Taken
	from match_details


GROUP BY batsman, dismissal_kind
HAVING COUNT(BALL)>=500
ORDER BY strike_rate DESC

LIMIT 10;

.
--Additional Questions--
--1--
select city, count(city) as cities_count
from ipl_data
group by city;

--2*
CREATE TABLE deliveries_v02 as (select * from match_details);
SELECT * FROM deliveries_v02;
--3*
ALTER TABLE deliveries_v02 ADD COLUMN ball_result INT;
ALTER TABLE deliveries_v02 ALTER COLUMN ball_result TYPE VARCHAR;

UPDATE deliveries_v02
SET ball_result= CASE WHEN total_runs >=4 then 'Boundary'
                      WHEN total_runs = 0 then 'Dot'
                      else 'Others' end;

--3*
SELECT  ball_result,
count(ball_result) as number_of_Boundries_Dots
from deliveries_v02
group by  ball_result;

--4*
SELECT batting_team,
     count(ball_result ) as Boundaries_scored
from deliveries_v02
	where ball_result = 'Boundary'
group by batting_team
order by Boundaries_scored desc;

--5* 
SELECT batting_team,
     count( ball_result ) as Dots_bowled
from deliveries_v02
	where ball_result = 'Dot'
group by batting_team
order by Dots_bowled desc;

--6*
SELECT dismissal_kind, 
    count(dismissal_kind) AS total_number_of_dismissals
from deliveries_v02
where not dismissal_kind='NA'
GROUP BY dismissal_kind;
select * from deliveries_v02;
--7*
SELECT bowler,
     sum(extra_runs)as maximum_extra_runs
from deliveries_v02
Group BY bowler
ORDER BY maximum_extra_runs desc
LIMIT 5;

--8*
CREATE TABLE deliveries_v03 AS (SELECT d.*, i.venue as Venue, i.date as  match_date
	                            From deliveries_v02 d
	                            JOIN IPL_DATA i
	                            ON d.id=i.id);
	                            
 SELECT * FROM deliveries_v03;  

--9*
SELECT venue, sum(total_runs) as total_runs_scored_for_each_venue
from deliveries_v03
GROUP BY venue
order by total_runs_scored_for_each_venue desc;

--10*
SELECT venue, sum(total_runs) as total_runs ,EXTRACT (YEAR FROM MATCH_DATE ) as year
from deliveries_v03
	where venue = 'Eden Gardens'
GROUP BY venue, year
order by year desc;


