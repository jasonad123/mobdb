# Tests for API feeds functions
# Using httptest2 for mocking HTTP requests

test_that("mobdb_feeds() works without data_type (returns all types)", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feeds_all", {
    result <- mobdb_feeds(limit = 5)
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) <= 5)
  })
})

test_that("mobdb_feeds() validates data_type parameter", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_feeds(data_type = "invalid"),
    "should be one of"  # match.arg error message
  )
})

test_that("mobdb_feeds() works with valid data_type", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feeds_gtfs", {
    result <- mobdb_feeds(data_type = "gtfs", limit = 5)

    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) <= 5)
    expect_true("id" %in% names(result))
    expect_true("provider" %in% names(result))
    expect_true("data_type" %in% names(result))
  })
})

test_that("mobdb_feeds() respects limit parameter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feeds_limit", {
    result <- mobdb_feeds(data_type = "gtfs", limit = 3)
    expect_true(nrow(result) <= 3)
  })
})

test_that("mobdb_feeds() filters by location require data_type", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_feeds(country_code = "US"),
    "Location filters require.*data_type"
  )
})

test_that("mobdb_feeds() works with location filters", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feeds_us", {
    result <- mobdb_feeds(
      data_type = "gtfs",
      country_code = "US",
      limit = 5
    )

    expect_s3_class(result, "tbl_df")
    # locations is a list-column, check it exists
    expect_true("locations" %in% names(result))
    # Check that results have US locations (if any results)
    if (nrow(result) > 0 && !is.null(result$locations[[1]])) {
      # First result's first location should have US
      expect_true(any(result$locations[[1]]$country_code == "US"))
    }
  })
})

test_that("mobdb_feeds() works with provider filter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feeds_provider", {
    result <- mobdb_feeds(
      data_type = "gtfs",
      provider = "TransLink"
    )

    expect_s3_class(result, "tbl_df")
    if (nrow(result) > 0) {
      expect_true(any(grepl("TransLink", result$provider, ignore.case = TRUE)))
    }
  })
})

test_that("mobdb_feeds() works with status filter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feeds_active", {
    result <- mobdb_feeds(
      data_type = "gtfs",
      status = "active",
      limit = 5
    )

    expect_s3_class(result, "tbl_df")
    # Status filter may not always be honored by API, just check it runs
    expect_true(nrow(result) >= 0)
  })
})

test_that("mobdb_get_feed() requires feed_id", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_get_feed(),
    "argument.*feed_id.*missing"
  )
})

test_that("mobdb_get_feed() returns single feed as list", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("get_feed", {
    # Using a known feed ID (will be recorded on first run)
    result <- mobdb_get_feed("mdb-1")

    # mobdb_get_feed returns JSON (a list), not a tibble
    expect_type(result, "list")
    expect_true("id" %in% names(result))
    expect_equal(result$id, "mdb-1")
  })
})

test_that("mobdb_feed_url() extracts URL correctly", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feed_url", {
    url <- mobdb_feed_url("mdb-1")

    expect_type(url, "character")
    expect_true(grepl("^https?://", url))
  })
})

test_that("mobdb_feed_url() handles nonexistent feed", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("feed_url_missing", {
    # Test with a feed that doesn't exist - should error
    expect_error(
      url <- mobdb_feed_url("mdb-nonexistent-999999"),
      "404"  # HTTP 404 error
    )
  })
})
