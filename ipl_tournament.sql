#SELECT * FROM ipl_tournament.ipl_ball;
#SHOW DATABASES;
#SHOW CREATE TABLE ipl_tournament.ipl_ball; 

#CASE 1
#EXTRACTING THE WIDE BALLS
CREATE TABLE case_1
SELECT 
    batsman, 
	COUNT(ball) AS total_balls, 
	COUNT(CASE WHEN extras_type != 'wides' OR extras_type IS NULL THEN ball END) AS valid_balls_faced ,
	(SUM(total_runs) / COUNT(CASE WHEN extras_type != 'wides' OR extras_type IS NULL THEN ball END)) * 100 AS strike_rate  
FROM ipl_ball
GROUP BY batsman
HAVING valid_balls_faced >= 500
ORDER BY valid_balls_faced DESC
LIMIT 10;

#JOIN THE IPL_BALLS AND IPL_MATCHES
CREATE TABLE ipl_ball_merged AS
SELECT 
    ipl_ball.*,  
    ipl_matches.date,  
    YEAR(STR_TO_DATE(ipl_matches.date, '%d-%m-%Y')) AS season 
FROM ipl_ball   
JOIN ipl_matches  ON ipl_ball.id = ipl_matches.id; 

#SELECT * FROM ipl_tournament.ipl_ball_merged;

#CASE 2
#WITH PLAYER PLAYED MORE THEN 2 SEASON AND HAVING GOOD AVG
WITH player_season AS (
  SELECT batsman,
         COUNT(DISTINCT season) AS total_seasons
  FROM ipl_ball_merged
  GROUP BY batsman
  HAVING total_seasons > 2
)
SELECT 
    b.batsman, 
    b.season,
   p.total_seasons,  
    SUM(b.total_runs) AS total_runs,
    SUM(b.is_wicket) AS dismissals,
    (SUM(b.total_runs) / NULLIF(SUM(b.is_wicket), 0)) AS batting_avg
FROM ipl_ball_merged b
JOIN player_season p ON b.batsman = p.batsman 
GROUP BY b.batsman, b.season, p.total_seasons  
HAVING SUM(b.is_wicket) > 0  
ORDER BY batting_avg DESC
LIMIT 10;

#CASE 3
# HARD- HITTING PLAYER AND BOUNDRYSTATS
WITH BoundaryStats AS (
    SELECT 
        batsman, 
        SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS Fours,
        SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS Sixes,
        SUM(CASE WHEN batsman_runs IN (4, 6) THEN batsman_runs ELSE 0 END) AS Boundary_Runs,
        SUM(batsman_runs) AS Total_Runs
    FROM IPL_Ball
    GROUP BY batsman
    HAVING Total_Runs >= 1000
)
SELECT 
    batsman,Fours,Sixes,Boundary_Runs,Total_Runs,
    (Boundary_Runs * 100.0 / Total_Runs) AS Boundary_Percentage
FROM BoundaryStats
ORDER BY Boundary_Percentage DESC
LIMIT 10;

#CASE 4
# GOOD ECONOMY 
WITH BowlerStats AS (
    SELECT 
        bowler, 
        COUNT(*) AS Balls_Bowled, 
        SUM(total_runs) AS Runs_Conceded,
        COUNT(*) / 6.0 AS Overs_Bowled
    FROM ipl_ball
    GROUP BY bowler
    HAVING Balls_Bowled >= 500
)
SELECT 
    bowler,
    Balls_Bowled,
    Runs_Conceded,
    Overs_Bowled,
    (Runs_Conceded / Overs_Bowled) AS Economy_Rate
FROM BowlerStats
ORDER BY Economy_Rate ASC
LIMIT 10;

#CASE 5
# BEST STRIKE RATE 
WITH BowlerStats AS (
    SELECT 
        bowler, 
        COUNT(*) AS Balls_Bowled, 
        SUM(CASE WHEN dismissal_kind IS NOT NULL AND dismissal_kind != 'run out' THEN 1 ELSE 0 END) AS Wickets_Taken
    FROM ipl_ball
    GROUP BY bowler
    HAVING Balls_Bowled >= 500 AND Wickets_Taken > 0
)
SELECT 
    bowler,
    Balls_Bowled,
    Wickets_Taken,
    (Balls_Bowled / Wickets_Taken) AS Strike_Rate
FROM BowlerStats
ORDER BY Strike_Rate ASC
LIMIT 10;

#CASE 6
#BOWLING STRIKE RATE 
WITH BattingStats AS (
    SELECT 
        batsman AS player, 
        COUNT(*) AS Balls_Faced, 
        SUM(batsman_runs) AS Runs_Scored,
        (SUM(batsman_runs) / COUNT(*)) * 100 AS Batting_Strike_Rate
    FROM IPL_Ball
    GROUP BY batsman
    HAVING Balls_Faced >= 500
), 

BowlingStats AS (
    SELECT 
        bowler AS player, 
        COUNT(*) AS Balls_Bowled, 
        SUM(CASE 
            WHEN dismissal_kind IS NOT NULL AND dismissal_kind != 'run out' THEN 1 
            ELSE 0 
        END) AS Wickets_Taken,
        (COUNT(*) / NULLIF(SUM(CASE 
            WHEN dismissal_kind IS NOT NULL AND dismissal_kind != 'run out' THEN 1 
            ELSE 0 
        END), 0)) AS Bowling_Strike_Rate
    FROM ipl_ball
    GROUP BY bowler
    HAVING Balls_Bowled >= 300 AND Wickets_Taken > 0
)

SELECT 
    b.player, 
    b.Balls_Faced, 
    b.Runs_Scored, 
    b.Batting_Strike_Rate, 
    bw.Balls_Bowled, 
    bw.Wickets_Taken, 
    bw.Bowling_Strike_Rate
FROM BattingStats b
JOIN BowlingStats bw ON b.player = bw.player
ORDER BY (b.Batting_Strike_Rate + bw.Bowling_Strike_Rate) DESC
LIMIT 10;

