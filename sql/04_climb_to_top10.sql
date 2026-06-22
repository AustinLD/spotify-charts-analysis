-- ============================================================
-- Analysis 4: The Climb to the Top 10
--
-- Question: of the songs that reached the top 10, how long did
-- the climb take, and where did they start? Slow burns and
-- instant hits are very different stories for a marketing team.
--
-- A conditional MIN OVER finds the first date each song hit the
-- top 10. FIRST_VALUE pulls its debut rank. DATEDIFF turns the
-- gap between debut and that first top-10 day into "days to
-- top 10."
--
-- Skills: conditional aggregate window (MIN CASE OVER),
-- FIRST_VALUE, DATEDIFF, CTEs
-- ============================================================

USE spotify;

-- ------------------------------------------------------------
-- Days from debut to first top-10 appearance
-- ------------------------------------------------------------
WITH flagged AS (
    SELECT
        song,
        `date`,
        `rank`,

        -- First day this song appeared on the chart.
        MIN(`date`) OVER (PARTITION BY song) AS debut_date,

        -- First day this song cracked the top 10 (NULL if it never did).
        MIN(CASE WHEN `rank` <= 10 THEN `date` END)
            OVER (PARTITION BY song) AS first_top10_date,

        -- Debut rank.
        FIRST_VALUE(`rank`) OVER (
            PARTITION BY song ORDER BY `date`
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS debut_rank
    FROM us_song_daily
),
runs AS (
    SELECT DISTINCT
        song,
        debut_rank,
        debut_date,
        first_top10_date
    FROM flagged
    WHERE first_top10_date IS NOT NULL
)
SELECT
    song,
    debut_rank,
    debut_date,
    first_top10_date,
    DATEDIFF(first_top10_date, debut_date) AS days_to_top10
FROM runs
ORDER BY days_to_top10 DESC      -- the slowest burns to the top 10
LIMIT 25;


-- ------------------------------------------------------------
-- Instant hits vs. slow burns: distribution of climb time
-- ------------------------------------------------------------
WITH flagged AS (
    SELECT
        song,
        MIN(`date`) AS debut_date,
        MIN(CASE WHEN `rank` <= 10 THEN `date` END) AS first_top10_date
    FROM us_song_daily
    GROUP BY song
    HAVING first_top10_date IS NOT NULL
),
classified AS (
    SELECT
        song,
        DATEDIFF(first_top10_date, debut_date) AS days_to_top10,
        CASE
            WHEN DATEDIFF(first_top10_date, debut_date) = 0  THEN 'Debuted in top 10'
            WHEN DATEDIFF(first_top10_date, debut_date) <= 7 THEN 'Within a week'
            WHEN DATEDIFF(first_top10_date, debut_date) <= 30 THEN 'Within a month'
            ELSE 'Slow burn (30+ days)'
        END AS climb_speed
    FROM flagged
)
SELECT
    climb_speed,
    COUNT(*)                                           AS songs,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1)   AS pct_of_top10_songs,
    ROUND(AVG(days_to_top10), 1)                       AS avg_days_to_top10
FROM classified
GROUP BY climb_speed
ORDER BY avg_days_to_top10;
