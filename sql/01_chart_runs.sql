-- ============================================================
-- Analysis 1: Chart Runs
--
-- Question: for each song, where did it debut, how high did it
-- peak, and how long did it last on the US Top 200?
--
-- This collapses a song's daily rows into one row describing its
-- whole chart run, using window functions instead of a GROUP BY
-- so we can pull the debut rank (first day) and peak rank in the
-- same pass.
--
-- Skills: FIRST_VALUE, MIN OVER, COUNT OVER, ROW_NUMBER, CTEs
-- ============================================================

USE spotify;

-- ------------------------------------------------------------
-- Per-song chart run: debut, peak, length
-- ------------------------------------------------------------
WITH labeled AS (
    SELECT
        song,
        title,
        artist,
        `date`,
        `rank`,

        -- Sequence each day of the run so we can keep just the first row.
        ROW_NUMBER() OVER (PARTITION BY song ORDER BY `date`) AS day_seq,

        -- Rank on the song's first charting day (its debut).
        FIRST_VALUE(`rank`) OVER (
            PARTITION BY song ORDER BY `date`
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS debut_rank,

        -- Best rank the song ever reached.
        MIN(`rank`) OVER (PARTITION BY song) AS peak_rank,

        -- Number of days the song spent on the chart.
        COUNT(*) OVER (PARTITION BY song) AS days_on_chart,

        -- Total streams across the whole run.
        SUM(streams) OVER (PARTITION BY song) AS total_streams
    FROM us_song_daily
)
SELECT
    song,
    debut_rank,
    peak_rank,
    days_on_chart,
    total_streams
FROM labeled
WHERE day_seq = 1               -- one row per song
ORDER BY days_on_chart DESC
LIMIT 25;                        -- the 25 longest-lived songs


-- ------------------------------------------------------------
-- Summary: how rare is staying power, and how rare is the top 10?
-- ------------------------------------------------------------
WITH runs AS (
    SELECT
        song,
        MIN(`rank`)   AS peak_rank,
        COUNT(*)      AS days_on_chart
    FROM us_song_daily
    GROUP BY song
)
SELECT
    COUNT(*)                                                          AS total_songs,
    ROUND(AVG(CASE WHEN peak_rank <= 10 THEN 1 ELSE 0 END) * 100, 1)  AS pct_reached_top10,
    ROUND(AVG(CASE WHEN days_on_chart <= 7 THEN 1 ELSE 0 END) * 100, 1) AS pct_one_week_or_less,
    ROUND(AVG(days_on_chart), 1)                                      AS avg_days_on_chart,
    MAX(days_on_chart)                                                AS longest_run
FROM runs;

-- Expected: ~7,878 songs; ~11.1% reached the top 10; ~55% lasted a week or less.
