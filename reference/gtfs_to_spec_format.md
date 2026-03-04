# Convert tidygtfs object to GTFS-spec-compliant format

Converts a tidygtfs object (as returned by
[`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html))
back to GTFS-spec-compliant string formats. This reverses tidytransit's
automatic type conversions:

- **Date columns** (R `Date` objects) are converted back to YYYYMMDD
  strings (e.g., `as.Date("2024-01-15")` becomes `"20240115"`)

- **Time columns** (`hms`/`difftime` objects) are converted back to
  HH:MM:SS strings, preserving values \>= 24:00:00 for trips past
  midnight (e.g., `hms::hms(hours = 25, minutes = 30)` becomes
  `"25:30:00"`)

Columns that are already in the correct format (character or integer)
are left unchanged. Returns a modified copy; the original object is not
modified.

## Usage

``` r
gtfs_to_spec_format(gtfs)
```

## Arguments

- gtfs:

  A gtfs/tidygtfs object, typically from
  [`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html)
  or
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md).

## Value

A modified copy of the gtfs object with date and time columns converted
to GTFS-spec-compliant strings.

## Affected tables and columns

**Date columns** (YYYYMMDD):

- `calendar`: `start_date`, `end_date`

- `calendar_dates`: `date`

- `feed_info`: `feed_start_date`, `feed_end_date`

**Time columns** (HH:MM:SS):

- `stop_times`: `arrival_time`, `departure_time`

- `frequencies`: `start_time`, `end_time`

## Examples

``` r
if (FALSE) { # mobdb_can_run_examples() && mobdb_has_tidytransit()
gtfs <- download_feed("mdb-247")

# Dates are R Date objects from tidytransit
class(gtfs$calendar$start_date)
# [1] "Date"

# Convert to GTFS-spec format
spec <- gtfs_to_spec_format(gtfs)
spec$calendar$start_date
# [1] "20240101"

spec$stop_times$arrival_time[1]
# [1] "08:30:00"
}
```
