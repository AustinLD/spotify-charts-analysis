# Power BI Build Guide: Spotify Chart Dynamics

This is the step-by-step for building the dashboard. The `.pbix` is assembled in Power BI Desktop; this guide gives you the data model, the measures, and the four pages.

## 1. Load the data

Get Data > Text/CSV > `data/spotify_us_global_top200.csv`.

In Power Query before loading:

- Set types: `date` = Date, `rank` and `streams` = Whole Number, the rest = Text.
- Keep both regions (United States and Global) and use Region as a slicer, or filter to United States if you want the dashboard to match the case study exactly.
- Add a column `song` = `title` & "  -  " & `artist`. This is the consolidated song key, the same one the SQL uses.
- Rename the query to `Charts`. Close & Apply.

## 2. Add a date table

Create a dedicated date table so time intelligence works. Modeling > New Table:

```DAX
Calendar =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2017, 1, 1 ), DATE ( 2021, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month", FORMAT ( [Date], "MMM" ),
    "MonthNo", MONTH ( [Date] ),
    "YearMonth", FORMAT ( [Date], "YYYY-MM" )
)
```

Relationship: `Calendar[Date]` 1-to-many to `Charts[date]`. Mark `Calendar` as the date table.

## 3. Core measures

Create these in a measures table (New Measure):

```DAX
Total Streams = SUM ( Charts[streams] )

Unique Songs = DISTINCTCOUNT ( Charts[song] )

Unique Artists = DISTINCTCOUNT ( Charts[artist] )

-- best (lowest) rank in the current context
Best Rank = MIN ( Charts[rank] )

-- one row per song's run length, then averaged
Avg Days on Chart =
AVERAGEX ( VALUES ( Charts[song] ), CALCULATE ( DISTINCTCOUNT ( Charts[date] ) ) )

Songs Reaching Top 10 =
CALCULATE (
    DISTINCTCOUNT ( Charts[song] ),
    FILTER ( Charts, Charts[rank] <= 10 )
)

% Reached Top 10 =
DIVIDE ( [Songs Reaching Top 10], [Unique Songs] )
```

For the concentration page, add a song-streams measure and a rank:

```DAX
Song Total Streams = CALCULATE ( [Total Streams], ALLEXCEPT ( Charts, Charts[song] ) )

Song Stream Rank =
RANKX ( ALL ( Charts[song] ), [Song Total Streams],, DESC )
```

## 4. The four pages

**Page 1: Overview**

- KPI cards: Total Streams, Unique Songs, Unique Artists, Avg Days on Chart, % Reached Top 10.
- Line chart: Total Streams by `Calendar[Date]` (the upward trend).
- Slicers: Region, Year.

**Page 2: Chart dynamics**

- Histogram of run length: bucket `Avg Days on Chart` per song, or build a "days on chart" calculated column per song and chart its distribution.
- Scatter: debut rank (x) vs peak rank (y), one point per song. Build debut/peak as calculated columns on a song summary table (see note below).
- Table: top 25 longest-running songs with debut, peak, days on chart.

**Page 3: Concentration**

- Use `Song Stream Rank` on the axis and a running-total of `Song Total Streams` to draw the cumulative share curve (Pareto).
- Card callouts: share held by the top 1%, 5%, 10% of songs.
- Bar chart: top 15 songs by total streams.

**Page 4: Momentum**

- Table sorted by week-over-week positions gained, with a rank-change calculated column (see note).
- Line chart: pick two or three songs (a climber and a spike) and plot `Best Rank` over time, with the rank axis reversed so 1 is on top.
- Slicer: date range.

## 5. Note on song-run columns

The scatter and momentum visuals need per-song debut/peak and per-day rank change. Easiest path: build a small **Song Summary** table in Power Query (Group By `song`: min date, min rank, count of dates) or with a DAX calculated table:

```DAX
Song Summary =
SUMMARIZE (
    Charts,
    Charts[song],
    "Days On Chart", DISTINCTCOUNT ( Charts[date] ),
    "Peak Rank", MIN ( Charts[rank] )
)
```

Add debut rank by joining back to the first charting date per song. Relate `Song Summary[song]` to `Charts[song]` for cross-filtering.

## 6. Theme

Use a dark background with Spotify green (#1DB954) as the accent to match the notebook figures. Keep it to two or three colors so the dashboard reads cleanly.

## 7. Save

Save the file as `powerbi/spotify-chart-dynamics.pbix`. It is gitignored (binary), so commit a screenshot or two of the finished pages into `data/` or a `screenshots/` folder for the README instead.
