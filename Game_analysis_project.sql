-- Game_analysis_project

# Data imported # using Database gaming

use gaming;

alter table player_details modify L1_Status varchar(30);
alter table player_details modify L2_Status varchar(30);
alter table player_details modify P_ID int primary key;


alter table level_details2 change timestamp start_datetime datetime;
alter table level_details2 modify Dev_Id varchar(10);
alter table level_details2 modify Difficulty varchar(15);
alter table level_details2 add primary key(P_ID,Dev_id,start_datetime);

-- player_Details (P_ID,PName,L1_status,L2_Status,L1_code,L2_Code)
-- level_details2 (P_ID,Dev_ID,start_time,stages_crossed,level,difficulty,kill_count,
-- headshots_count,score,lives_earned)


-- Q1.Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0

select p_id,dev_id,pname,difficulty from player_details
join level_details2 using(p_id)
where level=0;


-- Q2.Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--     3 stages are crossed

select l1_code,avg(kill_count) as avg_kill_count from player_details
join level_details2 using(p_id) where Lives_Earned=2 and Stages_crossed>=3 group by L1_Code;


-- Q3.Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.

select sum(stages_crossed) as total_stages_crossed,difficulty from level_details2
join player_details on player_details.P_ID=level_details2.P_ID
where Level=2 and Dev_ID like 'zm%'
group by Difficulty order by total_stages_crossed desc;


-- Q4.Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.

select p_id,count(distinct(start_datetime)) as total_unique_dates
from level_details2
group by P_ID having count(distinct(start_datetime))>=2;


-- Q5.Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.

select p_id,level,sum(kill_count) as total_kill_count from level_details2
inner join(
select avg(Kill_Count) as avg_kill_count from level_details2
where Difficulty='medium') as avg_table
on level_details2.Kill_Count> avg_kill_count
group by P_ID,Level;


-- Q6.Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.

select level,l1_code,sum(lives_earned) as sum_of_lives_earned from player_details
join level_details2 using(p_id)
group by Level,L1_Code
having Level!=0 order by Level asc;


-- Q7.Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well. 

select score ,dev_id,difficulty ,
row_number() over(partition by Dev_Id order by score)as score_rank
from level_details2 where (Dev_Id,Score)
 in(select Dev_Id,score from(
select dev_id,Score,row_number() 
over(partition by Dev_Id order by Score desc)as score_rank
from level_details2)as ranked_score where score_rank<=3);


-- Q8.Find first_login datetime for each device id.

select dev_id,min(start_datetime)as first_login from level_details2
group by dev_id;


-- Q9.Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.

select dev_id,score,difficulty,
rank() over(partition by difficulty order by score)as score_rank
from level_details2 where (Difficulty,Score)
in(select Difficulty,Score from(
select Difficulty,Score,
rank() over(partition by Difficulty order by Score) as score_rank
from level_details2)as ranked_score where score_rank<=5);


-- Q10.Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and first login datetime.

select p_id,dev_id,min(start_datetime)as first_login from level_details2
group by p_id,Dev_Id;


-- Q11.For each player and date, how many kill_count played so far by the player. 
-- That is, the total number of games played by the player until that date.
-- a) window function
-- b) without window function

-- window function:
select p_id,start_datetime,sum(kill_count) 
over(partition by p_id order by start_datetime) as total_kill_count
from level_details2;

-- without window function
select level_details2.p_id,level_details2.start_datetime,sum(level_details2.Kill_Count)as total_kill_count 
from level_details2  join(
select p_id,start_datetime,kill_count from level_details2)ld on ld.p_id=level_details2.p_id
and ld.start_datetime=level_details2.start_datetime group by level_details2.p_id,level_details2.start_datetime;


-- Q12.Find the cumulative sum of stages crossed over a start_datetime 

select start_datetime,stages_crossed,sum(stages_crossed)
 over(order by start_datetime)as cumulative_stages
from level_details2;


-- Q13.Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

WITH RankedScores AS (SELECT p_id, Dev_id, SUM(score) AS total_score,
RANK() OVER (PARTITION BY Dev_id ORDER BY SUM(score) DESC) AS Score_Rank
FROM level_details2 GROUP BY p_id, Dev_id)
SELECT p_id, Dev_id, total_score
FROM RankedScores
WHERE Score_Rank <= 3;


-- 14.Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`.

SELECT p_id, SUM(score) AS total_score
FROM level_details2 
GROUP BY p_id
HAVING total_score > (
SELECT AVG(sum_score) * 0.5
FROM (SELECT SUM(score) AS sum_score
FROM level_details2 GROUP BY p_id) AS avg_scores);


-- Q15.Create a function to return sum of Score for a given player_id.
 
DELIMITER $$
CREATE FUNCTION GetTotalScore(p_id INT) RETURNS INT
DETERMINISTIC NO SQL READS SQL DATA
BEGIN
   DECLARE total_score INT;
   DECLARE  p_id INT;
   SELECT SUM(score) INTO total_score
   FROM level_details2;
   select p_id into p_id from level_details2
   WHERE p_id = GetTotalScore.p_id;    
RETURN total_score;
END$$
DELIMITER ;





