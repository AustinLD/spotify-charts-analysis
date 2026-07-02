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

**Page 2: Chart dynamics** (redesigned session 15)

The original histogram + debut-vs-peak scatter were hard to read: the histogram was crushed by the right-skewed run-length distribution, and the scatter formed a mathematically forced triangle (peak rank can never be worse than debut). Replaced both with banded/categorical columns that carry one clear takeaway each.

- Tenure column chart ("How long songs stay on the chart"): clustered column, X = `Song Summary[Tenure Band]` (sorted by `Tenure Band Sort`), Y = Count of song, data labels on (white). The 6 bands: 1 week or less, 1-4 weeks, 1-3 months, 3-6 months, 6-12 months, 1 year+. Reads 55.2% gone within a week.
- Debut-outcome column chart ("Most songs peak the week they debut"): clustered column, X = `Song Summary[Debut Outcome]`, Y = `[Pct of Songs]`, data labels on (white, %). Shows 66.9% debut at peak vs 33.1% climb higher.
- Table ("Top 15 longest-running songs"): song, Debut Rank, Peak Rank, Days On Chart. Top 15 filter by Days On Chart. Days On Chart set to Sum (each song is one row, so values are unchanged) so green conditional-formatting data bars can be enabled; header renamed back to "Days On Chart". Sorted descending.

Supporting model objects (all on the `Song Summary` table, see note below):

```DAX
Tenure Band =
VAR d = 'Song Summary'[Days On Chart]
RETURN SWITCH ( TRUE (),
    d <= 7, "1 week or less", d <= 28, "1-4 weeks", d <= 91, "1-3 months",
    d <= 182, "3-6 months", d <= 365, "6-12 months", "1 year+" )

Tenure Band Sort =
VAR d = 'Song Summary'[Days On Chart]
RETURN SWITCH ( TRUE (), d <= 7, 1, d <= 28, 2, d <= 91, 3, d <= 182, 4, d <= 365, 5, 6 )

Debut Outcome =
IF ( 'Song Summary'[Peak Rank] = 'Song Summary'[Debut Rank], "Debuted at peak", "Climbed higher" )

Song Count = COUNTROWS ( 'Song Summary' )
Pct of Songs = DIVIDE ( COUNTROWS ( 'Song Summary' ), CALCULATE ( COUNTROWS ( 'Song Summary' ), REMOVEFILTERS ( 'Song Summary' ) ) )
```

**Page 3: Concentration**

- Use `Song Stream Rank` on the axis and a running-total of `Song Total Streams` to draw the cumulative share curve (Pareto).
- Card callouts: share held by the top 1%, 5%, 10% of songs.
- Bar chart: top 15 songs by total streams.

**Page 4: Climbers** (redesigned session 16)

The original two-song trajectory line chart was noisy: it drew fake bridges across off-chart gaps and its example "catalog climber" actually decayed. Replaced with a single ranked bar of the biggest real climbs, which is what `02_rank_momentum.sql` computes and yields an honest finding.

- Ranked horizontal bar of the 12 biggest single-week climbs into the Top 10, colored green for external-event spikes and gray for organic climbs, with the driving event in the tooltip. Backed by a "Top Climbs" DATATABLE calc table (refresh the model after creating it).
- Headline: 9 of the 12 biggest jumps are event-driven re-entries (XXXTENTACION and Juice WRLD deaths, The Weeknd's Super Bowl LV), only 3 organic.

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

Save the file as `powerbi/spotify-chart-dynamics.pbix`. The file (about 12MB) is committed to the repo so it can be opened directly, and page screenshots live in `screenshots/` for the README preview.
