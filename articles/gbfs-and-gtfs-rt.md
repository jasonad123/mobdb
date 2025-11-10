# Working with GTFS-Realtime and GBFS

The Mobility Database catalogs several types of transit and mobility
feeds. While GTFS Schedule feeds (formerly GTFS Static) make up the
majority of entries, they represent only part of the mobility data
landscape. Knowing when a bus is scheduled to arrive is useful, but
knowing whether it will actually arrive on time is even more valuable.

The Database also contains GTFS Realtime and GBFS feeds, which provide
real-time operational data about transit systems and shared mobility
services.

As `mobdb` consumes data from the Mobility Database API, a number of the
functions in this package will provide valid outputs of GTFS-Realtime
and GBFS objects. However, it’s important to note that support for
GTFS-Realtime and GBFS in `mobdb` should be considered
***experimental*** at this time and is limited only to feed discovery.

## GTFS-Realtime data structure

GTFS-Realtime, as of the time of writing, supports four distinct feed
entities:

- `TripUpdates` - fluctuations in the timetable - **“Bus X is delayed 2
  minutes”**
- `ServiceAlerts` - problems/issues with an entity - **“Stop Y is
  closed”**
- `VehiclePositions` - vehicle location and sometimes speed - **“This
  bus is at position X at time Y”**
- `TripModifications` - detours that affect a set of trips - **“On X
  weekend, XYZ trips are on detour”**

A detailed overview of what each feed entity does is available on the
[official GTFS
reference](https://gtfs.org/documentation/realtime/reference/).

GTFS-Realtime data is encoded and decoded as [Protocol
Buffers](https://developers.google.com/protocol-buffers/). In R,
Protocol Buffers can be interpreted using the
[RProtoBuf](https://cran.r-project.org/web/packages/RProtoBuf/index.html)
package.

### How mobdb handles GTFS-Realtime

`mobdb`, whether through
[`feeds()`](https://mobdb.pages.dev/reference/feeds.md) or
[`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
will surface all available GTFS-Realtime feeds on the Mobility Database.
The URL retrieved from
[`mobdb_feed_url()`](https://mobdb.pages.dev/reference/mobdb_feed_url.md)
will be the protobuf endpoint url.

**Note:** Many GTFS-Realtime producers *will* require authentication to
access their endpoints. Use the `source_info` data frame to get
authentication information from the Mobility Database.

``` r
# TransLink Vancouver GTFS-RT
gtfs_rt_yvr <- feeds(provider = "TransLink Vancouver", data_type = "gtfs_rt")

# read URL for GTFS-RT vehicle position
mobdb_feed_url(gtfs_rt_yvr$id[1])

# TransLink, like many agencies, requires authentication for their RT API
# Get authentication information from Mobility Database
yvr_rt_auth <- gtfs_rt_yvr$source_info[1, ]

# Get column names
names(yvr_rt_auth)

# Get registration URL
yvr_rt_auth$authentication_info_url

# Get API key parameter
yvr_rt_auth$api_key_parameter_name
```

### Parsing GTFS-Realtime with RProtoBuf

Once you have the URL, you can use RProtoBuf to decode the Protocol
Buffer data:

``` r
library(RProtoBuf)

gtfs_rt_example <- feeds(provider = "sample-agency", data_type = "gtfs_rt")

# read URL for GTFS-RT vehicle position
example_url <- mobdb_feed_url(gtfs_rt_example$id[1])

# Download and read the GTFS-RT .proto definition
# Available at: https://gtfs.org/documentation/realtime/gtfs-realtime.proto
proto_url <- "https://raw.githubusercontent.com/google/transit/master/gtfs-realtime/proto/gtfs-realtime.proto"
proto_file <- tempfile(fileext = ".proto")
download.file(proto_url, proto_file, quiet = TRUE)
readProtoFiles(proto_file)

# Fetch and parse the feed
con <- url(gtfs_rt_example, "rb")
feed <- read(transit_realtime.FeedMessage, con)
close(con)

# Access vehicle positions
for (entity in feed$entity) {
  if (entity$has("vehicle")) {
    vehicle <- entity$vehicle
    cat("Vehicle ID:", vehicle$vehicle$id, "\n")
    cat("Position:", vehicle$position$latitude, ",", vehicle$position$longitude, "\n")
    cat("Timestamp:", vehicle$timestamp, "\n\n")
  }
}
```

**Note:** The GTFS-Realtime Protocol Buffer definition is maintained in
the [Google Transit GitHub
repository](https://github.com/google/transit/tree/master/gtfs-realtime/proto).
The example above downloads it automatically, but you can also save it
locally for repeated use.

## GBFS data structure

GBFS, or the General Bikeshare Feed Specification, is a “real-time,
pull-based, data specification that describes the current status of a
mobility system”. In other words, GBFS defines the status of shared
mobility systems like bikeshare or scooter share systems.

Unlike GTFS-Schedule or GTFS-Realtime, it is structured as a series of
JSON files.

As of the latest version (v3), two files are *required* of any GBFS
feed:

- `gbfs.json` - an auto-discovery file that core information about a
  shared mobility feed and shares what other files are available
- `system_information.json` - defines core information about the shared
  mobility *system*

Other feed types are conditionally required depending on the system type
(e.g. dock vs dockless), while others are fully optional.

A full list of the GBFS feed entities and their requirements are
available on the [official GBFS reference
documentation](https://gbfs.org/documentation/reference/) or on the
[GitHub repo](https://github.com/MobilityData/gbfs/blob/master/gbfs.md).

### How mobdb handles GBFS

`mobdb`, whether through
[`feeds()`](https://mobdb.pages.dev/reference/feeds.md) or
[`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
will surface all available GBFS feeds on the Mobility Database. The URL
retrieved from
[`mobdb_feed_url()`](https://mobdb.pages.dev/reference/mobdb_feed_url.md)
will be the auto-discovery endpoint (i.e. `gbfs.json`).

``` r
# Search GBFS feeds in Vancouver
gbfs_yvr <- mobdb_search("vancouver", data_type = "gbfs")

yvr_feed <- mobdb_feed_url(gbfs_yvr$id[1])

yvr_feed
```

This can then be passed on to
[jsonlite](https://cran.r-project.org/web/packages/jsonlite/index.html)
for parsing or to the dedicated [gbfs](https://gbfs.netlify.app/)
package for discovery.

``` r
library(gbfs)

gbfs_yvr <- mobdb_search("vancouver", data_type = "gbfs")
yvr_feed <- mobdb_feed_url(gbfs_yvr$id[1])
yvr_station_info <- get_station_information(yvr_feed, output = "return")
```

## Next Steps

This vignette covered the basics of discovering GTFS-Realtime and GBFS
feeds using `mobdb`. For working with the actual feed data:

- **GTFS-Realtime**: Use the
  [RProtoBuf](https://cran.r-project.org/web/packages/RProtoBuf/index.html)
  package to decode Protocol Buffer data
- **GBFS**: Use the [gbfs](https://gbfs.netlify.app/) package for
  streamlined access to bikeshare data, or
  [jsonlite](https://cran.r-project.org/web/packages/jsonlite/index.html)
  for direct JSON parsing

For discovering GTFS Schedule feeds and working with historical transit
data, see the main package documentation and other vignettes.
