-- Select job title, location and the date it was posted while removing the timestamp
SELECT 
    COUNT(job_id),
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM
    job_postings_fact
WHERE job_title_short = 'Data Analyst'
GROUP BY
    month
ORDER BY
    COUNT(job_id) DESC;

CREATE TABLE january_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1;

CREATE TABLE february_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

CREATE TABLE march_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

SELECT 
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst'
GROUP BY location_category;

SELECT COUNT(job_id),
    CASE
        WHEN salary_year_avg > 100000 THEN 'High Salary'
        WHEN salary_year_avg <= 100000 AND salary_year_avg > 60000 THEN 'Standard'
        WHEN salary_year_avg <= 60000 THEN 'Low'
    END AS salary_buckets
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst'
    AND job_id IS NOT NULL
    AND salary_year_avg IS NOT NULL
GROUP BY salary_buckets
ORDER BY COUNT(job_id) DESC;

WITH january_jobs1 AS (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
)


SELECT company_id,
    name AS company_name
FROM company_dim
WHERE company_id IN (
    SELECT
        company_id
    FROM
        job_postings_fact
    WHERE job_no_degree_mention = true
    ORDER BY
        company_id
);


WITH company_job_count AS (
    SELECT
        company_id,
        COUNT(*) AS total_jobs
    FROM
        job_postings_fact
    GROUP BY
        company_id
)

SELECT company_dim.name AS company_name,
    company_job_count.total_jobs
FROM company_dim
LEFT JOIN company_job_count ON company_job_count.company_id = company_dim.company_id
ORDER BY total_jobs DESC;



WITH skill_id_count AS (
    SELECT 
        skill_id,
        COUNT(skill_id) AS total_skills
    FROM skills_job_dim
    GROUP BY skill_id
)

SELECT skills, skill_id_count.total_skills
FROM skills_dim
LEFT JOIN skill_id_count ON skills_dim.skill_id = skill_id_count.skill_id
ORDER BY total_skills DESC
LIMIT 5;


SELECT 
    skills_dim.skills,
    skill_count.total_skills
FROM skills_dim
LEFT JOIN (
    SELECT 
        skill_id, COUNT(*) AS total_skills
    FROM skills_job_dim
    GROUP BY skill_id
) AS skill_count
ON skills_dim.skill_id = skill_count.skill_id
ORDER BY total_skills DESC
LIMIT 5;

SELECT 
    company_dim.name, 
    company_count.job_postings,
    CASE
        WHEN company_count.job_postings < 10 THEN 'Small'
        WHEN company_count.job_postings BETWEEN 10 AND 50 THEN 'Medium'
        ELSE 'Large'
    END AS company_size
FROM (SELECT company_id, COUNT(*) AS job_postings
    FROM job_postings_fact
    GROUP BY company_id
) AS company_count
LEFT JOIN company_dim
ON company_count.company_id = company_dim.company_id
ORDER BY company_count.job_postings DESC;

/* Find the count of the number of remote job postings per skill
    - Display the top 5 skills by their demand in remote jobs
    - include skill ID, name and count of postings requiring the skill
*/

-- WITH top_5_skills AS (
--     SELECT 
--         skill_id, 
--         COUNT(skill_id)
--     FROM skills_job_dim
--     GROUP BY skill_id
-- )


SELECT 
    s.skill_id, 
    s.skills, 
    COUNT(j.job_id) AS job_postings_per_skill
FROM job_postings_fact j
INNER JOIN skills_job_dim sj ON j.job_id = sj.job_id
INNER JOIN skills_dim s ON s.skill_id = sj.skill_id
WHERE job_work_from_home = True 
-- AND job_title_short = 'Data Analyst'
GROUP BY s.skills, s.skill_id
ORDER BY COUNT(j.job_id) DESC
LIMIT 5;

--------



WITH remote_job_skills AS (
    SELECT
        skill_id,
        COUNT(*) AS skill_count
    FROM skills_job_dim sj
    INNER JOIN job_postings_fact j ON j.job_id = sj.job_id
    WHERE job_work_from_home = True
    GROUP BY skill_id
)

SELECT 
    s.skills,
    skill_count
FROM remote_job_skills
INNER JOIN skills_dim s ON remote_job_skills.skill_id = s.skill_id
ORDER BY skill_count DESC
LIMIT 5;

SELECT job_title_short,
company_id,
job_location
FROM january_jobs

UNION ALL

SELECT job_title_short,
company_id,
job_location
FROM february_jobs

UNION ALL

SELECT job_title_short,
company_id,
job_location
FROM march_jobs;

SELECT *
FROM january_jobs;

SELECT j.job_id, skills, s.type, j.job_posted_date
FROM skills_dim s
INNER JOIN skills_job_dim sj ON sj.skill_id = s.skill_id
RIGHT JOIN january_jobs j ON sj.job_id = j.job_id

UNION

SELECT f.job_id, skills, s.type, f.job_posted_date
FROM skills_dim s
INNER JOIN skills_job_dim sj ON sj.skill_id = s.skill_id
RIGHT JOIN february_jobs f ON sj.job_id = f.job_id

UNION

SELECT m.job_id, skills, s.type, m.job_posted_date
FROM skills_dim s
INNER JOIN skills_job_dim sj ON sj.skill_id = s.skill_id
RIGHT JOIN march_jobs m ON sj.job_id = m.job_id
ORDER BY job_posted_date;


WITH q1_jobs AS (
    SELECT * FROM january_jobs
    UNION ALL
    SELECT * FROM february_jobs
    UNION ALL
    SELECT * FROM march_jobs
)

SELECT 
    q.job_id, 
    s.skill_id, 
    s.skills, 
    q.job_posted_date, 
    q.salary_year_avg 
FROM q1_jobs q
    LEFT JOIN skills_job_dim sj ON sj.job_id = q.job_id
    LEFT JOIN skills_dim s ON s.skill_id = sj.skill_id
WHERE salary_year_avg > 70000
ORDER BY q.job_posted_date, skill_id;

WITH q1_jobs AS (
    SELECT * FROM january_jobs
    UNION ALL
    SELECT * FROM february_jobs
    UNION ALL
    SELECT * FROM march_jobs
)

SELECT 
    job_id, 
    salary_year_avg,
    job_posted_date
FROM q1_jobs
WHERE salary_year_avg > 70000;

SELECT *
FROM (
    SELECT * FROM january_jobs
    UNION ALL
    SELECT * FROM february_jobs
    UNION ALL
    SELECT * FROM march_jobs
) AS q1_job_postings
WHERE salary_year_avg > 70000 AND job_title_short = 'Data Analyst'
ORDER BY salary_year_avg DESC;

/* 
Find the count of the number of remote job postings per skill
    -Display the top 5 skills by their demand in remote jobs
    -Include skill ID, name, and count of postings requiring the skill
*/

WITH remote_job_skills AS (
    SELECT 
        s.skill_id,
        COUNT(*) AS skill_count
    FROM skills_job_dim s
    INNER JOIN job_postings_fact j ON j.job_id = s.job_id
    WHERE j.job_work_from_home = True AND job_title_short = 'Data Analyst'
    GROUP BY s.skill_id
)

SELECT d.skill_id, d.skills AS skill_name, r.skill_count
FROM skills_dim d
INNER JOIN remote_job_skills r ON r.skill_id = d.skill_id
ORDER BY r.skill_count DESC
LIMIT 5;
