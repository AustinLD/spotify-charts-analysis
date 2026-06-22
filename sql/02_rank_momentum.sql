-- ============================================================
-- Analysis 2: Rank Momentum
--
-- Question: which songs are moving, and how fast? This measures
-- day-over-day and week-over-week rank changes and streaming
-- velocity, the signals a playlist or marketing team watches.
--
-- LAG pulls a song's rank and streams from earlier rows in its
-- own timeline. Because chart coverage is daily and near-complete
-- (only a handful of missing days in five years), LAG(..., 7)
-- works as a week-ago comparison within a song's charting days.
-- A song's separate chart stints are not bridged, which is the
-- behavior we want: momentum is measured inside a single run.
--
-- Skills: LAG with offsets, window ordering, NULLIF guard, CTEs
-- ============================================================

USE spotify;

-- ------------------------------------------------------------
-- Per-day movement for every song
-- ------------------------------------------------------------
WITH movement AS (
    SELECT
        song,
        `date`,
        `rank`,
        streams,

        -- Rank and streams one day earlier in this song's run.
        LAG(`rank`, 1)   OVER (PARTITION BY song ORDER BY `date`) AS prev_rank,

        -- Rank and streams seven charting days earlier.
        LAG(`rank`, 7)   OVER (PARTITION BY song ORDER BY `date`) AS rank_7d_ago,
        LAG(streams, 7)  OVER (PARTITION BY song ORDER BY `date`) AS streams_7d_ago
    FROM us_song_daily
)
SELECT
    song,
    `date`,
    `rank`,

    -- Positive = climbed (rank number got smaller).
    prev_rank   - `rank` AS rank_change_1d,
    rank_7d_ago - `rank` AS rank_change_7d,

    -- Streaming velocity over the week.
    streams - streams_7d_ago AS stream_change_7d,
    ROUND((streams - streams_7d_ago) / NULLIF(streams_7d_ago, 0) * 100, 1)
        AS stream_pct_change_7d
FROM movement
WHERE rank_7d_ago IS NOT NULL
ORDER BY rank_change_7d DESC          -- biggest weekly climbers first
LIMIT 25;


-- ------------------------------------------------------------
-- Biggest single-week climbs into the top 10
-- A song's largest one-week jump that landed it in the top 10.
-- ------------------------------------------------------------
WITH movement AS (
    SELECT
        song,
        `date`,
        `rank`,
        LAG(`rank`, 7) OVER (PARTITION BY song ORDER BY `date`) AS rank_7d_ago
    FROM us_song_daily
)
SELECT
    song,
    `date`            AS reached_on,
    rank_7d_ago       AS rank_week_before,
    `rank`            AS rank_now,
    rank_7d_ago - `rank` AS positions_gained
FROM movement
WHERE `rank` <= 10
  AND rank_7d_ago IS NOT NULL
ORDER BY positions_gained DESC
LIMIT 25;
