# Spotify Charts: What Makes a Song Climb

## Problem

A song's run on the Spotify charts is a product story. Some tracks debut high and disappear in a week, others climb slowly and stay for months. A label or playlist team wants to know which is which early, so it can decide where to put marketing weight before a song peaks. I used five years of daily chart data to answer three questions: what a typical chart run looks like, how concentrated streaming really is, and what the climb to the top 10 actually looks like.

## Approach

The raw dataset is about 26 million rows (3.4GB) of daily Top 200 and Viral 50 charts by country, 2017 to 2021. I filtered it in Python to the United States and Global Top 200, which left a clean 726,000-row slice with no missing values and near-complete daily coverage (only five missing days in five years).

One modeling decision shaped everything after it. The same song can appear under several Spotify URLs (a single, an album version, a re-release), which splits its chart life across rows. I caught this when "Look What You Made Me Do" showed a false four-day run. The fix was to key a song by title and artist and take its best rank and total streams each day, so a song is counted as one song. Every SQL query is built on that consolidated view.

The analysis itself is SQL, leaning on window functions: FIRST_VALUE and MIN OVER to pull debut and peak rank in a single pass, LAG to measure day-over-day and week-over-week movement, NTILE with a running SUM OVER to build the streaming concentration curve, and a conditional MIN OVER to find the first day each song reached the top 10. The numbers were cross-checked against an independent Python pass.

## Insights

**Staying power is rare.** Of the 7,878 songs that charted in the US, more than half (55%) lasted a week or less, and the median run was just six days. The long tail is small but striking: Travis Scott's "goosebumps" lived on the chart for 1,778 days, nearly the entire window.

**The top 10 is a different world.** Only 11% of charting songs ever reached the top 10. Getting there is mostly an event, not a journey: 69% of top-10 songs debuted in the top 10, and another 15% arrived within a week. True slow burns are the exception at 10% of top-10 songs, but they are dramatic when they happen, taking an average of 215 days to break through. Juice WRLD's "All Girls Are The Same" is the clearest case, entering at 191 and grinding to a peak of 5 over 1,342 days.

**Streaming is heavily concentrated.** The top 1% of songs captured about 21% of all US streams, the top 5% captured more than half, and the top 10% captured roughly 73%. A small set of songs carries the platform, which is the same Pareto shape that shows up in most engagement data.

**The biggest weekly jumps are events, not momentum.** Ranking the largest single-week climbs into the Top 10 shows that 9 of the 12 sharpest jumps were driven by external events rather than organic build. The XXXTENTACION (June 2018) and Juice WRLD (December 2019) catalogs surged the week each artist died, and Starboy and The Hills both re-entered the days after The Weeknd's Super Bowl LV halftime show. "Legends" jumped 195 positions in a single week, the largest move in the data, the week after Juice WRLD's death. Only three of the top jumps (Something Just Like This, you should see me in a crown, Blinding Lights) came from ordinary release or organic growth.

## What I would do with this

For a playlist or marketing team, the practical takeaway is to read a big week-over-week jump correctly before spending against it. Most of the largest jumps are event-driven re-entries of older catalog tracks (a death, a televised performance, a cultural moment) that spike fast and fade, so they call for quick, short-lived activation rather than a sustained campaign. Genuine organic climbers, a song debuting outside the top 50 and posting steady positive rank changes week over week without an obvious external trigger, are rarer but are the ones worth backing for the long run. Because streaming is so concentrated, telling these two patterns apart early is worth more than broad support across the catalog.

## Stack

Python and Pandas for filtering and validation, SQL (CTEs and window functions) for the analysis, and Power BI for the dashboard. The full SQL is in `/sql`, the prep and exploratory notebook is in `/notebooks`, and the analysis-ready slice is in `/data`.

## Caveats

This is real chart data but it only covers songs that charted, so it says nothing about songs that never broke in. Findings are for skill demonstration, not label strategy.
