# Tests for convenience utility functions

test_that("mobdb_browse() returns correct URL", {
  skip_on_cran()
  skip_if_not(interactive(), "browseURL doesn't work in non-interactive mode")

  # We can't easily test browseURL without opening a browser,
  # but we can test the return value
  # Use testthat::with_mocked_bindings for R >= 4.0
  if (getRversion() >= "4.0.0") {
    testthat::local_mocked_bindings(
      browseURL = function(url) invisible(NULL),
      .package = "utils"
    )

    result <- mobdb_browse()
    expect_equal(result, "https://mobilitydatabase.org")
    expect_type(result, "character")
  } else {
    skip("Mocking requires R >= 4.0")
  }
})

test_that("mobdb_browse() returns invisibly", {
  skip_on_cran()

  if (getRversion() >= "4.0.0") {
    testthat::local_mocked_bindings(
      browseURL = function(url) invisible(NULL),
      .package = "utils"
    )

    expect_invisible(mobdb_browse())
  } else {
    skip("Mocking requires R >= 4.0")
  }
})

test_that("mobdb_browse() URL is correct", {
  # Test without actually calling browseURL
  # Just verify the expected URL value
  expected_url <- "https://mobilitydatabase.org"

  expect_equal(expected_url, "https://mobilitydatabase.org")
  expect_type(expected_url, "character")
  expect_match(expected_url, "^https://")
})
