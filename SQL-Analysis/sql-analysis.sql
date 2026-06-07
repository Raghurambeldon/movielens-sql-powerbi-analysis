
)create table movies (
movieid int primary key,
title varchar(200) ,
genres varchar(300)
);

create table links(
movieid int references movies(movieid),
imdbid bigint ,
tmdbid bigint
);


create table ratings(
userid int ,
movieid int references movies(movieid),
rating float,
timestamp bigint);


create table tags(
userid int ,
movieid int references movies(movieid),
tag varchar(400));


select * from movies limit 10;
select * from ratings limit 10;
select * from links limit 10;
select * from tags limit 10;


alter table ratings drop column timestamp;


select * from movies where not (movieid,title,genres) is not NULL;

select * from ratings where not (userid,movieid,rating) is not NULL;

select * from links where not (movieid,imdbid,tmdbid) is not NULL;

UPDATE links 
SET tmdbid = 0 
WHERE tmdbid IS NULL;

select * from tags where not (userid,movieid,tag) is not NULL;

select movieid,count(*) from movies 
group by movieid
having count(*)>1;


select * from movies limit 110;

UPDATE movies 
SET genres = split_part(genres, '|', 1)
WHERE genres LIKE '%|%'; 

update movies 
set genres = trim(genres);

alter table movies add column releaseyear int;

UPDATE movies
SET releaseyear = SUBSTRING(title FROM '\((\d{4})\)')::INT;



select count(*) from movies;
select count(*) from ratings;
select count(*) from tags;
SELECT COUNT(DISTINCT userid) FROM ratings;

select * from movies limit 10;

select m.genres,round(avg(r.rating)::numeric,2) as Avg_Rating from movies m 
join ratings r on m.movieid = r.movieid 
group by m.genres 
order by Avg_Rating desc
limit 10;

UPDATE movies
SET genres = 'Unknown'
WHERE genres = '(no genres listed)';


UPDATE movies
SET releaseyear = 0
WHERE releaseyear IS NULL;

--KPis
-- 1. Total Movies
SELECT COUNT(DISTINCT movieid) AS TotalMovies 
FROM movies;

-- 2. Total Users
SELECT COUNT(DISTINCT userid) AS TotalUsers 
FROM ratings;

-- 3. Top-Genre Based On Average Rating (With a 100-vote safety filter)
SELECT m.genres as Top_Genre
FROM movies m 
JOIN ratings r ON m.movieid = r.movieid 
GROUP BY 1 
HAVING COUNT(r.rating) >= 100  
ORDER BY AVG(r.rating) DESC 
LIMIT 1;

-- 4. Average-Rating
SELECT ROUND(AVG(rating)::NUMERIC, 2) AS GlobalAverageRating 
FROM ratings;


#Dashboard 


SELECT releaseyear, COUNT(title) AS movies_count 
FROM movies 
WHERE releaseyear > 0  and releaseyear>1950
GROUP BY releaseyear
ORDER BY releaseyear ASC; 


SELECT genres,COUNT(movieid) AS movies_count 
FROM movies
GROUP BY genres 
ORDER BY movies_count DESC
LIMIT 10;

SELECT m.movieid , m.title , count(t.tag) as tags
FROM movies m 
JOIN tags t 
ON m.movieid = t.movieid 
GROUP BY m.movieid,m.title 
ORDER BY tags DESC
LIMIT 10;

--D2

SELECT rating,COUNT(userid) 
FROM ratings 
GROUP BY rating
ORDER BY rating ASC;


SELECT m.movieid , m.title , count(r.rating) as reviews_count
FROM movies m 
JOIN ratings r
ON m.movieid =r.movieid 
GROUP BY m.movieid 
ORDER BY reviews_count DESC
LIMIT 10;


SELECT userid , count(rating) as total_ratings FROM ratings
GROUP BY userid 
ORDER BY total_ratings DESC
LIMIT 10;

SELECT tag, COUNT(tag) as tag_count FROM tags 
GROUP BY tag ORDER BY count(tag) DESC
LIMIT 10;


SELECT COUNT(imdbid) AS IMDB ,COUNT(tmdbid) AS TMDB
FROM links ;


SELECT m.genres, COUNT(t.tag) as tag_count FROM tags  t 
JOIN movies m on m.movieid = t.movieid
GROUP BY m.genres ORDER BY count(tag) DESC
LIMIT 10;

--Final 


-- ========================================================
-- KPIS & GENERAL VIEWS
-- ========================================================

-- 1. Global Metrics KPI
CREATE OR REPLACE VIEW v_kpi_global_metrics AS
SELECT 
    (SELECT COUNT(DISTINCT movieid) FROM movies) AS total_movies,
    (SELECT COUNT(DISTINCT userid) FROM ratings) AS total_users,
    (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM ratings) AS global_average_rating;

-- 2. Top Genre KPI
CREATE OR REPLACE VIEW v_kpi_top_genre AS
SELECT m.genres AS top_genre, AVG(r.rating) AS avg_rating
FROM movies m 
JOIN ratings r ON m.movieid = r.movieid 
GROUP BY m.genres 
HAVING COUNT(r.rating) >= 100  
ORDER BY avg_rating DESC 
LIMIT 1;


-- ========================================================
-- DASHBOARD 1: CATALOG OVERVIEW
-- ========================================================

-- a. Movies by Release Year
CREATE OR REPLACE VIEW v_d1_movies_by_year AS
SELECT releaseyear, COUNT(title) AS movies_count 
FROM movies 
WHERE releaseyear > 1950 
GROUP BY releaseyear;

-- b. Top 10 Genres by Movies Count
CREATE OR REPLACE VIEW v_d1_top_genres AS
SELECT genres, COUNT(movieid) AS movies_count 
FROM movies
GROUP BY genres 
ORDER BY movies_count DESC
LIMIT 10;

-- c. Top 10 Most Tagged Movies
CREATE OR REPLACE VIEW v_d1_top_tagged_movies AS
SELECT m.movieid, m.title, COUNT(t.tag) AS tags_count
FROM movies m 
JOIN tags t ON m.movieid = t.movieid 
GROUP BY m.movieid, m.title 
ORDER BY tags_count DESC
LIMIT 10;


-- ========================================================
-- DASHBOARD 2: USER ENGAGEMENT
-- ========================================================

-- a. Distribution of Rating Scores
CREATE OR REPLACE VIEW v_d2_rating_distribution AS
SELECT rating, COUNT(userid) AS total_reviews
FROM ratings 
GROUP BY rating;

-- b. Top 10 Most Reviewed Movies
CREATE OR REPLACE VIEW v_d2_top_reviewed_movies AS
SELECT m.movieid, m.title, COUNT(r.rating) AS reviews_count
FROM movies m 
JOIN ratings r ON m.movieid = r.movieid 
GROUP BY m.movieid, m.title 
ORDER BY reviews_count DESC
LIMIT 10;

-- c. Top 10 Power Users
CREATE OR REPLACE VIEW v_d2_top_power_users AS
SELECT userid, COUNT(rating) AS total_ratings 
FROM ratings
GROUP BY userid 
ORDER BY total_ratings DESC
LIMIT 10;


-- ========================================================
-- DASHBOARD 3: METADATA & TAGS
-- ========================================================

-- a. Top 10 Most Common Tags
CREATE OR REPLACE VIEW v_d3_top_tags AS
SELECT tag, COUNT(tag) AS tag_count 
FROM tags 
GROUP BY tag 
ORDER BY tag_count DESC
LIMIT 10;

-- b. External Platform Connection Status
CREATE OR REPLACE VIEW v_d3_metadata_links AS
SELECT COUNT(imdbid) AS imdb_count, COUNT(tmdbid) AS tmdb_count
FROM links;

-- c. Highly Tagged Genres
CREATE OR REPLACE VIEW v_d3_tagged_genres AS
SELECT m.genres, COUNT(t.tag) AS tag_count 
FROM tags t 
JOIN movies m ON m.movieid = t.movieid
GROUP BY m.genres 
ORDER BY tag_count DESC
LIMIT 10;
