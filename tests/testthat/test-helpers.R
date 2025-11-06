# Tests for helper/utility functions

test_that("mobdb_extract_urls() extracts URLs from feeds", {
  # Create mock feed data - source_info is a data frame, not a list
  feeds <- tibble::tibble(
    id = c("mdb-1", "mdb-2"),
    provider = c("Agency 1", "Agency 2"),
    source_info = tibble::tibble(
      producer_url = c("https://example.com/feed1.zip", "https://example.com/feed2.zip")
    )
  )

  urls <- mobdb_extract_urls(feeds)

  expect_type(urls, "character")
  expect_length(urls, 2)
  expect_true(all(grepl("^https://", urls)))
})

test_that("mobdb_extract_urls() handles missing URLs", {
  # Create mock feed data with missing URL
  feeds <- tibble::tibble(
    id = c("mdb-1", "mdb-2"),
    provider = c("Agency 1", "Agency 2"),
    source_info = tibble::tibble(
      producer_url = c("https://example.com/feed1.zip", NA_character_)
    )
  )

  urls <- mobdb_extract_urls(feeds)

  expect_type(urls, "character")
  expect_length(urls, 2)
  expect_true(is.na(urls[2]))
})

test_that("mobdb_extract_locations() extracts location data", {
  # Create mock feed data - locations is a list-column of data frames
  feeds <- tibble::tibble(
    id = c("mdb-1", "mdb-2"),
    provider = c("Agency 1", "Agency 2"),
    locations = list(
      tibble::tibble(country_code = "US", country = "United States",
                     subdivision_name = "California", municipality = "San Francisco"),
      tibble::tibble(country_code = "CA", country = "Canada",
                     subdivision_name = "British Columbia", municipality = "Vancouver")
    )
  )

  locations <- mobdb_extract_locations(feeds)

  expect_s3_class(locations, "tbl_df")
  expect_true("country_code" %in% names(locations))
  expect_true("subdivision_name" %in% names(locations))
  expect_equal(nrow(locations), 2)
})

test_that("mobdb_extract_datasets() extracts validation data", {
  # Create mock feed data with latest_dataset as a data frame
  feeds <- tibble::tibble(
    id = c("mdb-1", "mdb-2"),
    provider = c("Agency 1", "Agency 2"),
    latest_dataset = tibble::tibble(
      id = c("ds-1", "ds-2"),
      hosted_url = c("url1", "url2"),
      downloaded_at = c("2024-01-01", "2024-01-02"),
      hash = c("hash1", "hash2"),
      service_date_range_start = c("2024-01-01", "2024-01-01"),
      service_date_range_end = c("2024-12-31", "2024-12-31"),
      agency_timezone = c("America/Los_Angeles", "America/Vancouver"),
      validation_report = tibble::tibble(
        total_error = c(0, 1),
        total_warning = c(2, 5),
        total_info = c(10, 15)
      )
    )
  )

  datasets <- mobdb_extract_datasets(feeds)

  expect_s3_class(datasets, "tbl_df")
  expect_true("dataset_id" %in% names(datasets))
  expect_true("total_error" %in% names(datasets))
  expect_equal(nrow(datasets), 2)
})

test_that("mobdb_extract_datasets() handles missing validation data", {
  # Create mock feed data without latest_dataset
  feeds <- tibble::tibble(
    id = c("mdb-1"),
    provider = c("Agency 1")
  )

  # Should warn and return empty tibble
  expect_warning(
    datasets <- mobdb_extract_datasets(feeds),
    "latest_dataset.*not found"
  )

  expect_s3_class(datasets, "tbl_df")
  expect_equal(nrow(datasets), 0)
})
