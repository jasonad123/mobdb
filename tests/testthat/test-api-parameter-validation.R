# Note: Most parameter validation happens at the API level
# These tests verify the functions handle required parameters correctly

test_that("download_feed() requires feed_id or search parameters", {
  skip_if_not_installed("tidytransit")

  expect_error(
    download_feed(),
    "Must provide either.*feed_id.*or search parameters"
  )
})

test_that("download_best_feed() requires at least one search parameter", {
  skip_if_not_installed("tidytransit")

  expect_error(
    download_best_feed(),
    "At least one search parameter must be provided"
  )
})

# Most parameter validation for download_best_feed() happens within the function
# or is delegated to the search API
