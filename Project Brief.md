# Project 2: Spotify Charts: What Makes a Song Climb

## Problem Statement

A song's life on the Spotify charts is a product story. Some tracks debut high and fade in a week, others climb slowly and live on the chart for months. A label or playlist team wants to know what separates the two, so they can spot momentum early and decide where to put marketing weight.

This project treats daily chart positions as a behavioral dataset and answers three questions:

1. What does a typical chart run look like, and what distinguishes songs that climb and stay from one-week spikes?
2. How concentrated is streaming, do a small share of artists and songs capture most of the streams, and has that shifted over time?
3. Which momentum signals (week-over-week rank change and streaming velocity) tend to come before a song breaks into the top 10?

The point is to show product and marketing analytics thinking: define the metric, find the signal, and make a recommendation a team could act on.

## Dataset

**Spotify Charts (daily Top 200 and Viral 50)**

- Source: [kaggle.com/datasets/dhruvildave/spotify-charts](https://www.kaggle.com/datasets/dhruvildave/spotify-charts)
- Size: ~26M rows, 2017-2021, daily
- Columns: title, rank, date, artist, url, region, chart, trend, streams

This is real chart data scraped from Spotify's public charts. Findings are for skill demonstration, not label strategy.

The full file is around 3.4GB, so the first notebook step filters to a workable slice (default: United States and Global) and exports a slim, analysis-ready file. That filtering and validation step is part of the deliverable, not a shortcut around it.

## Tools & Stack

| Layer | Tool | Purpose |
| :---- | :---- | :---- |
| Data prep | Python (Pandas) | Filter the raw 26M rows to a clean regional slice, parse dates, validate |
| SQL analysis | SQL (CTEs, window functions) | Chart-run analysis, rank deltas, streaming concentration, momentum signals |
| Python | Pandas, Matplotlib, Seaborn | EDA, trajectory plots, concentration curves |
| Visualization | Power BI | Interactive chart-dynamics dashboard |
| Version control | GitHub | Code, SQL scripts, README, case study |

For 26M raw rows, DuckDB is an option for fast local querying, but the filtered slice loads fine into the same MySQL/SQLite setup from Project 1.

## Deliverables

### 1. SQL Analysis Scripts

Well-commented queries built around window functions, including:

- Each song's chart run: debut rank, peak rank, and weeks on chart using FIRST_VALUE, MIN, and COUNT over a partition by track
- Week-over-week rank change and streaming velocity with LAG over a track ordered by date
- Running total streams per artist and per song with SUM() OVER
- Streaming concentration: share of total streams held by the top N songs each week, using NTILE and ranked CTEs
- Momentum before a top-10 entry: rank trajectory in the days leading up to a song first hitting the top 10

### 2. Python Notebook

- Load and filter the raw charts file to the chosen regions, parse dates, validate row counts and nulls
- EDA: chart-run length distribution, debut vs. peak rank, streams over time
- Trajectory plots for a few representative climbers vs. spikes
- Streaming concentration curve (share of streams by song rank)
- Export the clean slice for Power BI

### 3. Power BI Dashboard

- **Overview:** total streams, unique songs and artists charting, average chart-run length, as KPI cards with trend lines
- **Chart dynamics:** rank trajectory view, climbers vs. spikes, weeks-on-chart distribution
- **Concentration:** top-artist and top-song share of streams over time
- **Momentum:** week-over-week movers, songs gaining fastest into the top 10

### 4. Case Study Write-Up

A short document (500-800 words): Problem, Approach, Insights, Business Impact. Hosted as the GitHub README. Written for a hiring manager with 90 seconds.

## Key Skills Demonstrated

- Advanced SQL: window functions (LAG, FIRST_VALUE, NTILE, SUM OVER, ROW_NUMBER), CTEs, partitioned time-series logic
- Data prep at scale: filtering and validating a 26M-row file down to a clean analysis set
- DAX: time-intelligence measures, rank-change and running-total logic
- Python: cleaning, EDA, trajectory and concentration visuals
- Storytelling: a product-framed write-up, not a methods report

## GitHub Structure (planned)

```
spotify-charts-analysis/
├── data/               # Slim filtered CSV (raw file gitignored, too large)
├── sql/                # SQL scripts, named by analysis
├── notebooks/          # Jupyter notebook for prep and EDA
├── powerbi/            # .pbix file
└── README.md           # Case study write-up
```

## Status

Active. Week 1: download the raw file, filter to the regional slice in Python, explore the schema, draft the first SQL queries.
