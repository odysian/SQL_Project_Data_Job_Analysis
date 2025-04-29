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

