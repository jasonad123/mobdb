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
        total_info = c(10, 15),
        url_html = c("https://example.com/report1.html", "https://example.com/report2.html"),
        url_json = c("https://example.com/report1.json", "https://example.com/report2.json")
      )
    )
  )

  datasets <- mobdb_extract_datasets(feeds)

  expect_s3_class(datasets, "tbl_df")
  expect_true("dataset_id" %in% names(datasets))
  expect_true("total_error" %in% names(datasets))
  expect_true("html_report" %in% names(datasets))
  expect_true("json_report" %in% names(datasets))
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

test_that("mobdb_extract_locations() with unnest=FALSE returns summary", {
  feeds <- tibble::tibble(
    id = c("mdb-1", "mdb-2"),
    provider = c("Agency 1", "Agency 2"),
    locations = list(
      tibble::tibble(
        country_code = "US",
        country = "United States",
        subdivision_name = "California",
        municipality = "San Francisco"
      ),
      tibble::tibble(
        country_code = "CA",
        country = "Canada",
        subdivision_name = "British Columbia",
        municipality = "Vancouver"
      )
    )
  )

  result <- mobdb_extract_locations(feeds, unnest = FALSE)

  expect_s3_class(result, "tbl_df")
  expect_true("location_summary" %in% names(result))
  expect_equal(nrow(result), 2)
  expect_type(result$location_summary, "character")
  expect_match(result$location_summary[1], "San Francisco")
})

test_that("mobdb_extract_locations() handles missing locations column", {
  feeds <- tibble::tibble(
    id = c("mdb-1"),
    provider = c("Agency 1")
  )

  expect_warning(
    result <- mobdb_extract_locations(feeds),
    "locations.*not found"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
})

test_that("mobdb_extract_locations() handles empty results", {
  feeds <- tibble::tibble(
    id = character(),
    provider = character(),
    locations = list()
  )

  result <- mobdb_extract_locations(feeds)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("mobdb_extract_urls() validates input", {
  expect_error(
    mobdb_extract_urls("not a data frame"),
    "must be a data frame"
  )
})

test_that("mobdb_extract_urls() handles missing source_info column", {
  feeds <- tibble::tibble(
    id = c("mdb-1"),
    provider = c("Agency 1")
  )

  expect_error(
    mobdb_extract_urls(feeds),
    "source_info.*not found"
  )
})

test_that("mobdb_extract_urls() handles empty data frame", {
  feeds <- tibble::tibble(
    id = character(),
    provider = character(),
    source_info = tibble::tibble(producer_url = character())
  )[0, ]

  result <- mobdb_extract_urls(feeds)

  expect_type(result, "character")
  expect_length(result, 0)
})

test_that("mobdb_extract_datasets() validates input", {
  expect_error(
    mobdb_extract_datasets("not a data frame"),
    "must be a data frame"
  )
})

test_that("mobdb_extract_datasets() handles datasets without validation reports", {
  feeds <- tibble::tibble(
    id = c("mdb-1"),
    provider = c("Agency 1"),
    latest_dataset = tibble::tibble(
      id = c("ds-1"),
      hosted_url = c("url1"),
      downloaded_at = c("2024-01-01"),
      hash = c("hash1"),
      service_date_range_start = c("2024-01-01"),
      service_date_range_end = c("2024-12-31"),
      agency_timezone = c("America/Los_Angeles")
    )
  )

  datasets <- mobdb_extract_datasets(feeds)

  expect_s3_class(datasets, "tbl_df")
  expect_true("dataset_id" %in% names(datasets))
  # Should have dataset info but no validation columns
})

test_that("mobdb_extract_locations() validates input", {
  expect_error(
    mobdb_extract_locations("not a data frame"),
    "must be a data frame"
  )
})

# Tests for authentication helper functions

test_that("parse_auth_args() extracts value from plain value format", {
  result <- mobdb:::parse_auth_args("my_api_key_123")
  expect_equal(result, "my_api_key_123")
})

test_that("parse_auth_args() extracts value from param=value format", {
  result <- mobdb:::parse_auth_args("apikey=my_api_key_123")
  expect_equal(result, "my_api_key_123")
})

test_that("parse_auth_args() handles NULL input", {
  result <- mobdb:::parse_auth_args(NULL)
  expect_null(result)
})

test_that("parse_auth_args() handles NA input", {
  result <- mobdb:::parse_auth_args(NA_character_)
  expect_null(result)
})

test_that("parse_auth_args() handles empty string input", {
  result <- mobdb:::parse_auth_args("")
  expect_null(result)
})

test_that("parse_auth_args() validates format with multiple equals", {
  expect_error(
    mobdb:::parse_auth_args("key=value=extra"),
    "Invalid.*auth_args.*format"
  )
})

test_that("parse_auth_args() warns when param name doesn't match expected", {
  expect_warning(
    result <- mobdb:::parse_auth_args("wrong_param=value123", "expected_param"),
    "does not match expected"
  )
  expect_equal(result, "value123")
})

test_that("build_authenticated_request() returns URL for auth_type=0", {
  result <- mobdb:::build_authenticated_request(
    "https://example.com/feed.zip",
    auth_type = 0,
    auth_param_name = NULL,
    auth_value = NULL
  )
  expect_equal(result, "https://example.com/feed.zip")
})

test_that("build_authenticated_request() returns URL for NULL auth_type", {
  result <- mobdb:::build_authenticated_request(
    "https://example.com/feed.zip",
    auth_type = NULL,
    auth_param_name = NULL,
    auth_value = NULL
  )
  expect_equal(result, "https://example.com/feed.zip")
})

test_that("build_authenticated_request() builds URL with query param for auth_type=1", {
  result <- mobdb:::build_authenticated_request(
    "https://example.com/feed.zip",
    auth_type = 1,
    auth_param_name = "apikey",
    auth_value = "test123"
  )
  expect_equal(result, "https://example.com/feed.zip?apikey=test123")
})

test_that("build_authenticated_request() appends to existing query params for auth_type=1", {
  result <- mobdb:::build_authenticated_request(
    "https://example.com/feed.zip?format=json",
    auth_type = 1,
    auth_param_name = "apikey",
    auth_value = "test123"
  )
  expect_equal(result, "https://example.com/feed.zip?format=json&apikey=test123")
})

test_that("build_authenticated_request() builds httr2 request for auth_type=2", {
  skip_if_not_installed("httr2")

  result <- mobdb:::build_authenticated_request(
    "https://example.com/feed.zip",
    auth_type = 2,
    auth_param_name = "X-API-Key",
    auth_value = "test123"
  )

  expect_s3_class(result, "httr2_request")
})

test_that("build_authenticated_request() errors on unknown auth_type", {
  expect_error(
    mobdb:::build_authenticated_request(
      "https://example.com/feed.zip",
      auth_type = 99,
      auth_param_name = "key",
      auth_value = "value"
    ),
    "Unknown authentication type"
  )
})

test_that("build_authenticated_request() errors when param name missing for auth_type=1", {
  expect_error(
    mobdb:::build_authenticated_request(
      "https://example.com/feed.zip",
      auth_type = 1,
      auth_param_name = NULL,
      auth_value = "test123"
    ),
    "requires.*api_key_parameter_name"
  )
})

test_that("build_authenticated_request() errors when param name missing for auth_type=2", {
  expect_error(
    mobdb:::build_authenticated_request(
      "https://example.com/feed.zip",
      auth_type = 2,
      auth_param_name = NA_character_,
      auth_value = "test123"
    ),
    "requires.*api_key_parameter_name"
  )
})
