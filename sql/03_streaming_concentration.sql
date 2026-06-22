-- ============================================================
-- Analysis 3: Streaming Concentration
--
-- Question: how concentrated is streaming? Do a small share of
-- songs capture most of the streams? This is the Pareto check
-- every product team runs on engagement.
--
-- NTILE(100) splits all songs into 100 equal groups by total
-- streams, so each group is one percentile of the catalog. A
-- running SUM() OVER then builds the cumulative share curve.
--
-- Skills: NTILE, SUM() OVER (running total), window frame, CTEs
-- ============================================================

USE spotify;

-- ------------------------------------------------------------
-- Total streams per song, then percentile buckets
-- ------------------------------------------------------------
WITH song_totals AS (
    SELECT
        song,
        SUM(streams) AS total_streams
    FROM us_song_daily
    GROUP BY song
),
bucketed AS (
    SELECT
        song,
        total_streams,

        -- 1 = the top 1% of songs by streams, 100 = the bottom 1%.
        NTILE(100) OVER (ORDER BY total_streams DESC) AS pct_bucket,

        -- Grand total for share math.
        SUM(total_streams) OVER () AS grand_total,

        -- Running total of streams from the biggest song down.
        SUM(total_streams) OVER (
            ORDER BY total_streams DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_streams
    FROM song_totals
)
SELECT
    pct_bucket,
    COUNT(*)                                              AS songs,
    ROUND(SUM(total_streams) / MAX(grand_total) * 100, 2) AS pct_of_streams,
    ROUND(MAX(running_streams) / MAX(grand_total) * 100, 2) AS cumulative_pct
FROM bucketed
GROUP BY pct_bucket
ORDER BY pct_bucket
LIMIT 10;       -- the top 10 percentiles and their cumulative share

-- Expected cumulative share: top 1% ~21%, top 5% ~54%, top 10% ~71%.


-- ------------------------------------------------------------
-- The 15 most-streamed songs of the whole window
-- ------------------------------------------------------------
WITH song_totals AS (
    SELECT
        song,
        SUM(streams) AS total_streams
    FROM us_song_daily
    GROUP BY song
)
SELECT
    RANK() OVER (ORDER BY total_streams DESC) AS stream_rank,
    song,
    total_streams
FROM song_totals
ORDER BY total_streams DESC
LIMIT 15;
