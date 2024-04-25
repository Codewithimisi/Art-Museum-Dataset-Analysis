create database art; 
use art;

-- 1) Retrieve all the paintings which are not displayed in any museums
SELECT*
FROM work
WHERE museum_id is NULL;


-- 2) Query the museums without any paintings
SELECT m.museum_id, m.name
FROM museum m
LEFT JOIN work w
ON m.museum_id=w.museum_id
WHERE work_id is NULL;


-- 3) How many paintings have an asking price of more than their regular price? 
SELECT COUNT(*) AS no_of_paintings
FROM product_size
WHERE sale_price>regular_price;

-- 4) Identify the paintings whose asking price is less than 50% of its regular price
SELECT*
FROM product_size
WHERE sale_price<(regular_price*0.5);

-- 5) Which canva size costs the most?
SELECT p.size_id, c.label, max(regular_price) as highest_price
FROM canvas_size c
JOIN product_size p
ON c.size_id=p.size_id
GROUP BY p.size_id, c.label
ORDER BY highest_price desc
limit 1;

-- 6) Fetch the top 10 most famous painting subject
SELECT subject, count(*) as num_subject
FROM subject
GROUP BY subject
ORDER BY num_subject desc
limit 10;


-- 7) Identify the museums with invalid city information in the given dataset and delete it
DELETE
FROM Museum
WHERE city REGEXP '^[0-9]'; -- an invalid city information in the dataset begins with a number hence city names beginning with number 0 to 9 are queried

-- 8) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
SELECT m.name, m.city
FROM museum m
JOIN museum_hours mh1 ON m.museum_id = mh1.museum_id
JOIN museum_hours mh2 ON m.museum_id = mh2.museum_id
WHERE mh1.day = 'Sunday' AND mh2.day = 'Monday';

-- 9) How many museums are open every single day?
SELECT COUNT(*) AS num_museums
FROM (
    SELECT museum_id, COUNT(DISTINCT day)
    FROM museum_hours
    GROUP BY museum_id
    HAVING COUNT(DISTINCT day) = 7) AS museums_open_everyday;


-- 10) Display the 3 least popular canva sizes  --Popularity is determined by the number of paintings in each size
SELECT size_id, count(work_id) as no_of_sizes
FROM product_size
GROUP BY size_id
ORDER BY no_of_sizes
LIMIT 3;

-- 11) Which are the top 5 most popular museum? 
SELECT w.museum_id, m.name, count(*) as no_of_paintings -- Popularity is defined based on most no of paintings in a museum
FROM work w
JOIN museum m
ON w.museum_id=m.museum_id
GROUP BY w.museum_id, m.name
ORDER BY no_of_paintings desc
LIMIT 5;

-- 12) Which museum is open for the longest during a day. Display museum name, state and hours open and which day?
 SELECT m.name, m.state, mh.day, 
       CONCAT(mh.open, ' - ', mh.close) AS hours_open,
       CONCAT(TIMESTAMPDIFF(HOUR, STR_TO_DATE(mh.open, '%h:%i:%p'),  STR_TO_DATE(mh.close, '%h:%i:%p')),'hrs') as duration
FROM museum m
JOIN museum_hours mh 
ON m.museum_id = mh.museum_id
ORDER BY duration DESC
LIMIT 1;


-- 13) What day has the longest opening hours for each museum? Retrieve details such as museum name, country, day, hours open, and the duration of opening hours.
WITH longest_period AS (
SELECT m.name, 
	   m.country, 
       mh.day, 
       CONCAT(mh.open, ' - ',mh.close) AS hours_open,
       concat(TIMESTAMPDIFF(HOUR, STR_TO_DATE(open, '%h:%i:%p'), STR_TO_DATE(close, '%h:%i:%p')),'hrs') as duration_of_opening_hours, 
       row_number() over (partition by m.name order by TIMESTAMPDIFF(HOUR, STR_TO_DATE(open, '%h:%i:%p'), STR_TO_DATE(close, '%h:%i:%p'))desc)as rownum
FROM museum_hours mh
JOIN museum m
ON m.museum_id=mh.museum_id
) 
SELECT name, country, day, hours_open, duration_of_opening_hours
FROM longest_period
where rownum=1;


-- 14) Who are the top 5 most popular artist? 
SELECT a.full_name as artist_name, w.artist_id, count(work_id) as no_of_paintings -- Popularity is defined based on most no of paintings done by an artist
FROM work w
JOIN artist a
ON w.artist_id=a.artist_id
GROUP BY a.full_name, w.artist_id
ORDER BY no_of_paintings DESC 
LIMIT 5;


-- 15) Which museum has the most no of most popular painting style?
SELECT m.name, COUNT(*) as num_popular_style
FROM museum m
JOIN work w 
ON m.museum_id = w.museum_id
WHERE w.style = (
    SELECT style
    FROM work
    GROUP BY style
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
GROUP BY m.name
ORDER BY num_popular_style desc
LIMIT 1;


-- 16) Identify the artists whose paintings are displayed in multiple countries
SELECT a.artist_id, a.full_name, count(distinct m.country) as number_of_countries
FROM artist a
JOIN work w
ON a.artist_id=w.artist_id
JOIN museum m
ON w.museum_id=m.museum_id
GROUP BY a.artist_id, a.full_name
HAVING count(distinct m.country)>1;


-- 17) Identify the artist and the museum where the most expensive and least expensive painting is placed. Display the artist name, sale_price, 
-- painting name, museum name, museum city and canvas label
WITH ranked_price AS(
SELECT a.full_name, 
       p.sale_price, 
       w.name as painting_name, 
       m.name as museum_name, 
       m.city, 
       c.label,
       row_number() over(order by regular_price desc) as most_expensive_painting,
       row_number() over(order by regular_price asc) as least_expensive_painting
FROM artist a
JOIN work w
ON a.artist_id=w.artist_id
JOIN museum m
ON w.museum_id=m.museum_id
JOIN product_size p
ON p.work_id=w.work_id
JOIN canvas_size c
ON c.size_id=p.size_id
)
SELECT full_name, 
       sale_price, 
       painting_name, 
       museum_name, 
       city, 
       label
FROM ranked_price
WHERE most_expensive_painting=1 OR least_expensive_painting=1;
       

-- 18) Which country has the 5th highest no of paintings?
WITH ranked_countries AS(
SELECT m.country, 
       count(w.work_id),
       row_number() over (order by count(w.work_id)desc) as rownum
FROM museum m
JOIN work w
ON m.museum_id=w.museum_id
GROUP BY m.country)
SELECT country
FROM ranked_countries
WHERE rownum=5;

       
-- 19) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
SELECT a.full_name as artist_name, a.nationality, count(w.work_id) as no_of_paintings
FROM artist a
JOIN work w
ON a.artist_id=w.artist_id
JOIN museum m
ON w.museum_id=m.museum_id
JOIN subject s
ON s.work_id=w.work_id
WHERE s.subject='Portraits' AND m.country not in ('USA')
GROUP BY a.full_name, a.nationality
ORDER BY no_of_paintings DESC
LIMIT 1;

	
