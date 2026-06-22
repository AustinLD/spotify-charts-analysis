# Spotify Charts: What Makes a Song Climb

Analyzing five years of daily Spotify chart data (2017-2021) to understand how songs move on and off the charts, where streaming is concentrated, and what momentum signals come before a track breaks into the top 10.

This is a portfolio project. The data is real chart data scraped from Spotify's public charts; the findings are for skill demonstration, not label strategy.

## The Questions

1. What does a typical chart run look like, and what separates songs that climb and stay from one-week spikes?
2. How concentrated is streaming, and has that shifted over time?
3. Which momentum signals tend to come before a song reaching the top 10?

## Stack

- **Python (Pandas):** filter the raw 26M-row file to a clean regional slice, validate, prep for analysis
- **SQL (window functions, CTEs):** chart-run analysis, rank deltas, streaming concentration, momentum
- **Power BI:** interactive chart-dynamics dashboard
- **GitHub:** version control

## Repo Structure

```
spotify-charts-analysis/
├── data/         # Slim filtered CSV (raw 3.4GB file is gitignored)
├── sql/          # SQL scripts, named by analysis
├── notebooks/    # Jupyter notebook for prep and EDA
├── powerbi/      # .pbix dashboard
└── README.md
```

## Key Findings

Across 7,878 songs that charted in the US Top 200 (2017-2021):

- **Staying power is rare.** 55% of charting songs lasted a week or less; the median run was 6 days. The outlier is Travis Scott's "goosebumps" at 1,778 days.
- **The top 10 is mostly an event, not a journey.** Only 11% of songs ever reached the top 10, and 69% of those debuted there. True slow burns are 10% of top-10 songs but average 215 days to break through.
- **Streaming is heavily concentrated.** The top 1% of songs captured ~21% of streams, the top 5% more than half, and the top 10% ~73%.
- **Momentum shows up before the peak.** Week-over-week rank changes flag climbers early, like Juice WRLD's "Legends" jumping 195 spots in a week.

## Case Study

Full write-up (Problem, Approach, Insights, and what I would do with it) in [CASE_STUDY.md](CASE_STUDY.md).
