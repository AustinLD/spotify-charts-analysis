-- ============================================================
-- Spotify Charts Database Setup
-- Run this once to create the database, load the slice, and
-- build the helper view the analysis scripts depend on.
--
-- BEFORE RUNNING:
--   1. Update the file path in the LOAD DATA statement to match
--      where the CSV lives on your computer. Use forward slashes.
--   2. Enable local_infile in MySQL:
--        SET GLOBAL local_infile = 1;
--      Or add allowLocalInfile=true to your VS Code connection.
--
-- NOTE: load the uncompressed CSV (spotify_us_global_top200.csv),
-- not the .gz. The .gz is only the committed copy for GitHub.
-- ============================================================

CREATE DATABASE IF NOT EXISTS spotify;
USE spotify;

DROP TABLE IF EXISTS charts;

-- `rank` and `date` are reserved words in MySQL, so they are backticked
-- everywhere they appear.
CREATE TABLE charts (
    title    VARCHAR(255),
    `rank`   SMALLINT,
    `date`   DATE,
    artist   VARCHAR(255),
    url      VARCHAR(255),
    region   VARCHAR(50),
    chart    VARCHAR(20),
    trend    VARCHAR(20),
    streams  INT
);

LOAD DATA LOCAL INFILE 'C:/Users/austi/OneDrive/Documents/Cowork OS/Workstations/Portfolio Projects/Project 2 - Spotify Charts Analysis/data/spotify_us_global_top200.csv'
INTO TABLE charts
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title, `rank`, `date`, artist, url, region, chart, trend, streams);

-- Indexes for the partitions and filters the analysis uses most.
CREATE INDEX idx_region_date ON charts (region, `date`);
CREATE INDEX idx_title_artist ON charts (title, artist);

-- ============================================================
-- Helper view: us_song_daily
--
-- A song can appear under several Spotify URLs (single vs. album
-- vs. re-release), which would split its chart life across rows.
-- This view keys a song by (title + artist) and keeps its BEST
-- rank and TOTAL streams for each day. Every analysis script
-- builds on this so the "one song" definition stays consistent.
--
-- Scope: United States, Top 200 only.
-- ============================================================

CREATE OR REPLACE VIEW us_song_daily AS
SELECT
    CONCAT(title, '  -  ', artist) AS song,
    title,
    artist,
    `date`,
    MIN(`rank`)   AS `rank`,     -- best (lowest) rank that day
    SUM(streams)  AS streams      -- streams summed across versions
FROM charts
WHERE region = 'United States'
  AND chart  = 'top200'
GROUP BY title, artist, `date`;

-- ============================================================
-- VERIFY LOAD
-- ============================================================

SELECT region, chart, COUNT(*) AS row_count
FROM charts
GROUP BY region, chart
ORDER BY region, chart;

-- Expected: United States / top200 and Global / top200, ~363K rows each.
