# Manual Testing Guide for GTFS Export Feature

This guide provides instructions for manually testing the `export_path` parameter added to `download_feed()` and `download_best_feed()`.

## Prerequisites

```r
# Install required packages
install.packages(c("tidytransit", "gtfsio", "zip"))

# Set up API key
mobdb::mobdb_set_key("your-refresh-token")
```

## Test 1: Basic Export with download_feed()

Test that `download_feed()` can download and export a GTFS feed to a ZIP file.

```r
library(mobdb)

# Create test directory
dir.create("test_exports", showWarnings = FALSE)

# Test 1a: Download and export by feed ID
gtfs <- download_feed("mdb-247", export_path = "test_exports/trimet.zip")

# Verify:
# 1. Function returns a gtfs object
class(gtfs)  # Should include "gtfs"

# 2. ZIP file was created
file.exists("test_exports/trimet.zip")  # Should be TRUE

# 3. ZIP file contains GTFS files
zip_contents <- zip::zip_list("test_exports/trimet.zip")
print(zip_contents$filename)
# Should include: agency.txt, routes.txt, stops.txt, trips.txt, stop_times.txt, etc.

# 4. File size is reasonable (> 0 bytes)
file.info("test_exports/trimet.zip")$size
```

**Expected Result**:
- Function completes without errors
- Returns a valid gtfs object
- Creates a ZIP file at the specified path
- ZIP file contains valid GTFS data

## Test 2: Export with Nested Directory Creation

Test that parent directories are automatically created.

```r
# Test 2: Export to nested directory that doesn't exist
gtfs <- download_feed(
  "mdb-53",  # BART
  export_path = "test_exports/nested/path/bart.zip"
)

# Verify:
# 1. Nested directories were created
dir.exists("test_exports/nested/path")  # Should be TRUE

# 2. ZIP file exists
file.exists("test_exports/nested/path/bart.zip")  # Should be TRUE
```

**Expected Result**:
- Automatically creates nested directories
- Successfully exports the file

## Test 3: Export with download_best_feed()

Test that `download_best_feed()` passes `export_path` correctly.

```r
# Test 3: Download best feed and export
gtfs <- download_best_feed(
  provider = "Bay Area Rapid Transit",
  export_path = "test_exports/bart_best.zip",
  interactive = FALSE
)

# Verify:
# 1. Function returns gtfs object
class(gtfs)  # Should include "gtfs"

# 2. Export file exists
file.exists("test_exports/bart_best.zip")  # Should be TRUE

# 3. Contents are valid
zip::zip_list("test_exports/bart_best.zip")
```

**Expected Result**:
- Selects and downloads the best feed
- Exports it to the specified path
- Returns the gtfs object

## Test 4: Export with Search Parameters

Test export with location-based search.

```r
# Test 4: Search by location and export
gtfs <- download_feed(
  country_code = "US",
  subdivision_name = "Oregon",
  municipality = "Portland",
  export_path = "test_exports/portland.zip"
)

# Verify export succeeded
file.exists("test_exports/portland.zip")  # Should be TRUE
```

**Expected Result**:
- Finds a feed matching the location
- Downloads and exports it successfully

## Test 5: Export with Agency Source URL

Test export when using agency's source URL.

```r
# Test 5: Download from agency source and export
gtfs <- download_feed(
  "mdb-247",
  use_source_url = TRUE,
  export_path = "test_exports/trimet_source.zip"
)

# Verify both files exist and compare sizes
file.info("test_exports/trimet.zip")$size
file.info("test_exports/trimet_source.zip")$size
# Sizes may differ slightly due to different compression or update timing
```

**Expected Result**:
- Downloads from agency's direct URL
- Successfully exports the feed
- File sizes should be similar to hosted version

## Test 6: Export = NULL (Default Behavior)

Test that omitting `export_path` maintains backward compatibility.

```r
# Test 6: No export (backward compatibility)
gtfs <- download_feed("mdb-247")

# Verify:
# 1. Function still works
class(gtfs)  # Should include "gtfs"

# 2. No unexpected files created
# Check that no ZIP files were created in working directory
```

**Expected Result**:
- Function works exactly as before
- No export happens
- Backward compatible with existing code

## Test 7: Error Handling - Missing gtfsio

Test that appropriate error is shown when gtfsio is not installed.

```r
# Test 7: Error when gtfsio not available
# (Only run this if you can temporarily remove gtfsio)
remove.packages("gtfsio")

# Should error with helpful message
tryCatch({
  download_feed("mdb-247", export_path = "test.zip")
}, error = function(e) {
  print(e$message)
  # Should mention: "gtfsio package is required"
  # Should mention: "install.packages('gtfsio')"
})

# Reinstall after test
install.packages("gtfsio")
```

**Expected Result**:
- Clear error message about missing gtfsio package
- Helpful instructions to install it

## Test 8: Export with Historical Dataset

Test export of a specific historical dataset version.

```r
# Test 8: Export historical dataset
gtfs <- download_feed(
  dataset_id = "mdb-53-202510250025",  # Use an actual dataset ID
  export_path = "test_exports/bart_historical.zip"
)

# Verify it's the historical version
file.exists("test_exports/bart_historical.zip")  # Should be TRUE
```

**Expected Result**:
- Downloads the specific historical version
- Exports it successfully

## Test 9: Export with Authentication

Test export when feed requires API authentication.

```r
# Test 9: Authenticated download and export
# (Replace with an actual feed requiring auth and your API key)
gtfs <- download_feed(
  provider = "WMATA",
  feed_name = "Rail",
  use_source_url = TRUE,
  auth_args = Sys.getenv("WMATA_API_KEY"),
  export_path = "test_exports/wmata.zip"
)

# Verify
file.exists("test_exports/wmata.zip")  # Should be TRUE
```

**Expected Result**:
- Authenticates successfully
- Downloads and exports the feed

## Test 10: Overwrite Existing File

Test behavior when export file already exists.

```r
# Test 10: Overwrite existing export
# First export
download_feed("mdb-247", export_path = "test_exports/overwrite_test.zip")
original_size <- file.info("test_exports/overwrite_test.zip")$size

# Second export (should overwrite)
download_feed("mdb-53", export_path = "test_exports/overwrite_test.zip")
new_size <- file.info("test_exports/overwrite_test.zip")$size

# Verify file was overwritten (size should be different)
print(paste("Original:", original_size, "New:", new_size))
```

**Expected Result**:
- File is overwritten without error
- New content replaces old content

## Test 11: Special Characters in Path

Test export with paths containing spaces and special characters.

```r
# Test 11: Path with spaces
gtfs <- download_feed(
  "mdb-247",
  export_path = "test_exports/path with spaces/feed.zip"
)

file.exists("test_exports/path with spaces/feed.zip")  # Should be TRUE
```

**Expected Result**:
- Handles paths with spaces correctly
- Creates directories and files as expected

## Clean Up

```r
# Remove test exports
unlink("test_exports", recursive = TRUE)
```

## Test Results Template

| Test | Status | Notes |
|------|--------|-------|
| 1. Basic Export | ☐ Pass / ☐ Fail | |
| 2. Nested Directory | ☐ Pass / ☐ Fail | |
| 3. download_best_feed() | ☐ Pass / ☐ Fail | |
| 4. Search Parameters | ☐ Pass / ☐ Fail | |
| 5. Agency Source URL | ☐ Pass / ☐ Fail | |
| 6. NULL Export | ☐ Pass / ☐ Fail | |
| 7. Missing gtfsio Error | ☐ Pass / ☐ Fail | |
| 8. Historical Dataset | ☐ Pass / ☐ Fail | |
| 9. Authentication | ☐ Pass / ☐ Fail | |
| 10. Overwrite | ☐ Pass / ☐ Fail | |
| 11. Special Characters | ☐ Pass / ☐ Fail | |

## Performance Considerations

The export process should add minimal overhead:

```r
# Benchmark download vs download+export
library(microbenchmark)

# Download only
time_download <- system.time({
  gtfs1 <- download_feed("mdb-247")
})

# Download + Export
time_export <- system.time({
  gtfs2 <- download_feed("mdb-247", export_path = "test_exports/bench.zip")
})

print("Download only:")
print(time_download)

print("Download + Export:")
print(time_export)

# Export overhead should be minimal (< 1 second for typical feeds)
print(paste("Export overhead:", time_export[3] - time_download[3], "seconds"))
```

**Expected Result**:
- Export adds minimal time (typically < 1-2 seconds)
- Most time is spent in the download, not the export

## Troubleshooting

### Issue: "gtfsio package is required"
**Solution**: Install gtfsio with `install.packages("gtfsio")`

### Issue: "Permission denied" when creating directories
**Solution**: Check write permissions on the target directory

### Issue: Export file is empty or corrupt
**Solution**:
1. Verify the GTFS object is valid before export
2. Check that gtfsio is the correct version
3. Try a different feed to rule out feed-specific issues

### Issue: Different content between direct download and export
**Solution**: This is expected - gtfsio may normalize the data or use different compression
