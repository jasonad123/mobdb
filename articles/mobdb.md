# Introduction to mobdb

## Introduction

**mobdb** is your first stop to analyzing transit in R. It helps you
**find** and **download** GTFS and GBFS feeds from the [Mobility
Database](https://mobilitydatabase.org/), which contains information for
about 4000+ transit and shared mobility feeds worldwide.

## Installation

Install mobdb from r-universe:

``` r

# install from r-universe
install.packages("mobdb", repos = c("https://jasonad123.r-universe.dev", "https://cloud.r-project.org"))
```

Alternatively, you can also install mobdb from GitHub:

``` r

# install.packages("pak")
pak::pak("jasonad123/mobdb")
```

## Authentication

The Mobility Database API requires authentication in the form of a
*Refresh Token*. To get your Refresh Token, follow these steps:

1.  Go to <https://mobilitydatabase.org/>
2.  Create a free account - or sign in if you already have one
3.  Go to the “Account” menu, then click “Account Details”
4.  Copy the Refresh Token from the account page
5.  Store it in your R environment

``` r

library(mobdb)

# Shortcut to launch the Mobility Database in your browser
mobdb_browse()

# Set your API refresh token (do this once)
# mobdb_set_key("your-refresh-token-here")

# Check if authentication is configured
mobdb_has_key()
#> [1] TRUE
```

**Tip:** Store your token in your `.Renviron` file to avoid entering it
each session:

``` r

usethis::edit_r_environ()
# Add this line:
# MOBDB_REFRESH_TOKEN=your-refresh-token-here
# Then restart your R session
```

## Basics: Discover, download, analyze

### Discover feeds

Find GTFS feeds using various search criteria:

``` r

# Find all feeds in California
ca_feeds <- feeds(
  country_code = "US",
  subdivision_name = "California",
  data_type = "gtfs"
)

# View results
head(ca_feeds)
#> # A tibble: 6 × 10
#>   id       data_type status provider     feed_name location...

# Search by provider name
bart_feeds <- feeds("BART")
bart_feeds
```

### Step 2: Download feeds

Download a specific feed by ID or search term:

``` r

# Download by feed ID (Bay Area Rapid Transit)
bart <- download_feed("mdb-53")

# Or search and download in one step (use full name for better results)
bart <- download_feed(provider = "Bay Area Rapid Transit")

# The result is a gtfs object (from tidytransit)
class(bart)
#> [1] "tidygtfs" "gtfs"     "list"

names(bart)
#> [1] "agency" "calendar" "calendar_attributes" "calendar_dates" "directions" ...
```

### Step 3: Analyze feeds with tidytransit

Now that you have the feed, use tidytransit for analysis:

``` r

library(tidytransit)

# Validate the feed
validation <- validate_gtfs(bart)
summary(validation)

# Calculate stop frequencies
stop_freq <- get_stop_frequency(bart)
head(stop_freq)

# Calculate route frequencies
route_freq <- get_route_frequency(bart)
head(route_freq)

# Convert to spatial features
bart_sf <- gtfs_as_sf(bart)
plot(bart_sf$stops)
```

## Common use cases

### Finding feeds by location

``` r

# Find feeds in a specific municipality
seattle_feeds <- feeds(municipality = "Seattle", data_type = "gtfs")

# Find feeds in a country
canada_feeds <- feeds(country_code = "CA", data_type = "gtfs")

# Combine filters
bc_feeds <- feeds(
  country_code = "CA",
  subdivision_name = "British Columbia",
  status = "active",
  data_type = "gtfs"
)
```

### Working with multiple feeds

``` r

# Get feeds for several cities
agencies <- c("TriMet", "King County Metro", "TransLink Vancouver")
feeds_list <- lapply(agencies, function(agency) {
  feeds <- feeds(provider = agency, data_type = "gtfs")
  if (nrow(feeds) > 0) {
    download_feed(feeds$id[1])
  }
})

# Analyze each feed with tidytransit
library(tidytransit)
frequencies <- lapply(feeds_list, function(gtfs) {
  if (!is.null(gtfs)) get_stop_frequency(gtfs)
})
```

### Downloading feeds to local storage

Oftentimes, you’ll need to download your feeds as a ZIP file to local
storage - whether that’s because you’re just archiving it or because
your workflow specifically uses it, as is the case with packages that
use external routing engines like
[r5r](https://cran.r-project.org/package=r5r). For this use case, just
give
[`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
a value for the `export_path` parameter to save it locally.

``` r

# Find feeds in a specific municipality or jurisdiction
seattle_feeds <- feeds(municipality = "Seattle", data_type = "gtfs")
pdx_feeds <- feeds(municipality = "Portland", data_type = "gtfs")

# Download a feed directly to disk
seattle_dl <- download_feed("mdb-1080", export_path = "data/gtfs/seattle.zip")

# Download the raw feed, bypassing any processing by tidytransit
pdx_dl <- download_feed("mdb-247", export_path = "data/gtfs/portland.zip", raw = TRUE)
```

## Example workflow

Here’s a complete example from discovery to analysis:

``` r

library(mobdb)
library(tidytransit)
library(ggplot2)
library(tidyverse)
library(sf)

# 1. DISCOVER: Find feeds in Vancouver, BC, Canada
vancouver_feeds <- feeds(
  provider = "TransLink",
  municipality = "Vancouver",
  country_code = "CA",
  data_type = "gtfs"
)

# 2. DOWNLOAD: Get the sixth feed (TransLink)
translink <- download_feed(vancouver_feeds$id[1])

# 3. VALIDATE: Check feed quality (tidytransit)
validation <- validate_gtfs(translink)
print(validation)

# 3a. VALIDATE (another way): Check feed quality (using the Mobility Database report)
vancouver_datasets <- mobdb_datasets(vancouver_feeds$id[1])
feed_report <- get_validation_report(vancouver_datasets)
print(feed_report)

# 4. ANALYZE: Calculate AM route frequencies (tidytransit)
am_route_freq <- get_route_frequency(translink,
                                     start_time = 6 * 3600, end_time = 10 * 3600)
head(am_route_freq) %>%
  knitr::kable()

# get_route_geometry needs a gtfs object that includes shapes as simple feature data frames
translink <- gtfs_as_sf(translink)
routes_sf <- get_route_geometry(translink)

routes_sf <- routes_sf %>%
  inner_join(am_route_freq, by = "route_id")

# 5. VISUALIZE: Plot routes with (tidytransit + ggplot2)
# convert to an appropriate coordinate reference system
routes_sf_crs <- sf::st_transform(routes_sf, 26910)

routes_sf_crs %>%
  filter(median_headways < 10 * 60) %>%
  ggplot() +
  geom_sf(aes(colour = as.factor(median_headways))) +
  labs(color = "Headways") +
  geom_sf_text(aes(label = route_id)) +
  theme_bw()

routes_sf_buffer <- st_buffer(routes_sf, dist = routes_sf$total_departures / 1e6)

routes_sf_buffer %>%
  ggplot() +
  geom_sf(colour = alpha("white", 0), fill = alpha("blue", 0.5)) +
  theme_bw()
```

## Advanced features

### Accessing archived feeds (datasets)

The Mobility Database downloads and archives GTFS Schedule feeds at
midnight UTC, allowing users to download and reference historical
versions of feeds.

These historical versions are called “datasets” in the Mobility Database
nomenclature. We can access datasets through the Mobility Database API
and download them independently.

``` r

versions <- download_feed("mdb-53", latest = FALSE)  # BART
nrow(versions)
head(versions$id, n = 10)

# Download a specific historical version
historical <- download_feed(dataset_id = "mdb-53-202507240047")

# Compare validation across versions
recent_versions <- versions[1:3, ]
sapply(1:3, function(i) {
  get_validation_report(recent_versions[i, ])$total_error
})
```

### Check feed quality before downloading

The Mobility Database validates all GTFS Schedule feeds through the
canonical GTFS validator. You can check validation results before
downloading.

``` r

# Get validation report for a feed
datasets <- mobdb_datasets("mdb-482")  # Alexandria DASH
validation <- get_validation_report(datasets)
validation

# View detailed validation report in browser
view_validation_report("mdb-482")

# Check feed quality, then download if clean
if (validation$total_error == 0) {
  gtfs <- download_feed("mdb-482")
}
```

## Other feed types

For information on how to use `mobdb` with other feed types accessible
in the Mobility Database, see [this
vignette](https://mobdb.jasonadle.dev/articles/gbfs-and-gtfs-rt.md).

## Related packages

mobdb is just the first stop, not the end of the route when it comes to
transit and transportation on R.

Other packages for analyzing GTFS in the R ecosystem include:

- [tidytransit](https://r-transit.github.io/tidytransit/): A tool to
  read and analyze GTFS feeds
- [gtfstools](https://github.com/ipea/gtfstools): Edit and validate
  feeds
- [gtfsio](https://github.com/r-transit/gtfsio): Fast I/O operations
  like saving GTFS back to ZIP files

Once you have GTFS files or GTFS objects, you can perform some pretty
interesting analysis with other tools like:

- [R5r](https://r-transit.github.io/tidytransit/): A wrapper for the R5
  routing engine, to perform travel time and access analysis
- [dodgr](https://github.com/UrbanAnalyst/dodgr): Distances on Directed
  Graphs in R
