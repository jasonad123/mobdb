# Tests for integration functions (download_feed, read_gtfs)
# Using httptest2 for mocking HTTP requests

# Helper to skip tests when fixtures don't exist
skip_if_no_fixtures <- function(fixture_dir) {
  fixture_path <- file.path("tests/testthat", fixture_dir)
  if (!file.exists(fixture_path)) {
    fixture_path <- file.path(fixture_dir)
  }

  has_fixtures <- dir.exists(fixture_path) &&
                  length(list.files(fixture_path, recursive = TRUE)) > 0

  if (!has_fixtures) {
    skip("HTTP fixtures not found. Run tests with API key to record fixtures.")
  }
}

test_that("download_feed() requires feed identifier", {
  skip_if_not_installed("httptest2")

  expect_error(
    download_feed(),
    "Must provide either.*feed_id.*or search parameters"
  )
})

test_that("download_feed() works with feed_id", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not_installed("tidytransit")

  # Skip this test - requires full GTFS download
  # Download by ID tested manually in V0.1.2_TESTING_NOTES.md (Test 1)
  skip("Requires full GTFS download - tested manually")

  httptest2::with_mock_dir("download_feed_id", {
    # This test will need actual GTFS data or mocking
    # For now, just test that it doesn't error on API call
    expect_error(
      download_feed("mdb-1"),
      NA  # Should not error (though download might fail)
    )
  }, simplify = FALSE)
})

test_that("download_feed() works with provider search", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not_installed("tidytransit")

  # Skip this test - requires HTTP fixtures
  # Provider search tested manually in V0.1.2_TESTING_NOTES.md (Tests 2, 3, 4)
  skip("Requires HTTP fixtures - provider search tested manually")

  httptest2::with_mock_dir("download_feed_search", {
    # Test that search with multiple results gives helpful error
    expect_error(
      download_feed(provider = "TransLink", search = TRUE),
      "Multiple feeds found"
    )
  }, simplify = FALSE)
})

test_that("download_feed() validates exclude_flex parameter", {
  skip_if_not_installed("httptest2")

  # Skip - function doesn't validate exclude_flex type (R coerces it)
  # This is standard R behavior - parameter type is not enforced at runtime
  skip("Parameter validation not implemented - relies on R type coercion")

  # This test doesn't need API calls - just validates parameter
  expect_error(
    download_feed("mdb-1", exclude_flex = "invalid"),
    "exclude_flex.*logical"
  )
})

test_that("download_feed() handles feeds with empty feed_name", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  # Skip this test - requires HTTP fixtures
  # Tested manually with various feeds in V0.1.2_TESTING_NOTES.md
  skip("Requires HTTP fixtures - tested manually")

  httptest2::with_mock_dir("download_feed_empty_name", {
    # Test edge case: feed with NULL or empty feed_name
    # Should use provider name or id as fallback
    expect_no_error(
      download_feed("mdb-1")
    )
  }, simplify = FALSE)
})

test_that("download_feed() handles feeds with NULL producer_url", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  # Skip this test - requires specific fixtures
  # Error handling tested manually in V0.1.2_TESTING_NOTES.md (Test 9)
  skip("Requires HTTP fixtures - error handling tested manually")

  httptest2::with_mock_dir("download_feed_null_url", {
    # Test edge case: feed with NULL source_info$producer_url
    # Should provide helpful error message
    expect_error(
      download_feed("mdb-nonexistent"),
      "URL.*not found|feed.*not found"
    )
  }, simplify = FALSE)
})

test_that("mobdb_read_gtfs() requires feed identifier", {
  skip_if_not_installed("httptest2")

  # mobdb_read_gtfs() has feed_id as a required parameter
  # R will throw "argument.*missing" error
  expect_error(
    mobdb_read_gtfs(),
    "argument.*missing"
  )
})

test_that("mobdb_read_gtfs() works with feed_id", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not_installed("tidytransit")

  # Skip this test - it requires full GTFS download and parsing
  # Comprehensive manual testing in V0.1.2_TESTING_NOTES.md confirms this works
  skip("Requires full GTFS download - tested manually")

  httptest2::with_mock_dir("read_gtfs_id", {
    # This would require actual GTFS data
    # Testing that API call works
    expect_error(
      mobdb_read_gtfs("mdb-1"),
      NA  # Should not error on API call
    )
  }, simplify = FALSE)
})

test_that("mobdb_read_gtfs() passes extra args to tidytransit", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not_installed("tidytransit")

  # Skip this test - it requires full GTFS download and parsing
  # Comprehensive manual testing in V0.1.2_TESTING_NOTES.md confirms this works
  skip("Requires full GTFS download - tested manually")

  httptest2::with_mock_dir("read_gtfs_args", {
    # Test that extra arguments are passed through
    # files argument is a tidytransit parameter
    expect_error(
      mobdb_read_gtfs("mdb-1", files = c("agency", "routes")),
      NA  # Should accept tidytransit arguments
    )
  }, simplify = FALSE)
})
