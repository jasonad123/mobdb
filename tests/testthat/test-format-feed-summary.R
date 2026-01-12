test_that("format_feed_summary includes feed ID", {
  feed <- data.frame(
    id = "mdb-123",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("\\[mdb-123\\]", summary))
})

test_that("format_feed_summary includes provider name", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit Agency",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("Test Transit Agency", summary))
})

test_that("format_feed_summary includes feed_name when different from provider", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Transit Agency",
    feed_name = "Bus Routes",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("\\(Bus Routes\\)", summary))
})

test_that("format_feed_summary excludes feed_name when same as provider", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Transit Agency",
    feed_name = "Transit Agency",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_false(grepl("\\(Transit Agency\\)", summary))
})

test_that("format_feed_summary includes status", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    status = "active",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("Status: active", summary))
})

test_that("format_feed_summary includes official status when TRUE", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    official = TRUE,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("Official: TRUE", summary))
})

test_that("format_feed_summary includes official status when FALSE", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    official = FALSE,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("Official: FALSE", summary))
})

test_that("format_feed_summary handles NA official status", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    official = NA,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_false(grepl("Official:", summary))
})

test_that("format_feed_summary includes validation errors and warnings", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset$validation_report <- data.frame(
    total_error = 5,
    total_warning = 10,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_true(grepl("Errors: 5", summary))
  expect_true(grepl("Warnings: 10", summary))
})

test_that("format_feed_summary excludes validation when include_validation = FALSE", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset$validation_report <- data.frame(
    total_error = 5,
    total_warning = 10,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_false(grepl("Errors:", summary))
  expect_false(grepl("Warnings:", summary))
})

test_that("format_feed_summary includes service date range", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    service_date_range_start = "2024-01-01",
    service_date_range_end = "2024-12-31",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_true(grepl("Service: 2024-01-01 to 2024-12-31", summary))
})

test_that("format_feed_summary handles missing service dates", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_false(grepl("Service:", summary))
})

test_that("format_feed_summary handles NA service dates", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    service_date_range_start = NA_character_,
    service_date_range_end = NA_character_,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_false(grepl("Service:", summary))
})

test_that("format_feed_summary handles NA validation values", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset$validation_report <- data.frame(
    total_error = NA_integer_,
    total_warning = NA_integer_,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_false(grepl("Errors:", summary))
  expect_false(grepl("Warnings:", summary))
})

test_that("format_feed_summary handles missing latest_dataset", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_true(is.character(summary))
  expect_gt(nchar(summary), 0)
})

test_that("format_feed_summary handles NULL latest_dataset", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- NULL

  summary <- mobdb:::format_feed_summary(feed, include_validation = TRUE)
  expect_true(is.character(summary))
  expect_gt(nchar(summary), 0)
})

test_that("format_feed_summary handles minimal feed data", {
  feed <- data.frame(
    id = "mdb-1",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(is.character(summary))
  expect_true(grepl("mdb-1", summary))
})

test_that("format_feed_summary handles NA id", {
  feed <- data.frame(
    id = NA_character_,
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(is.character(summary))
  expect_true(grepl("Test Transit", summary))
})

test_that("format_feed_summary handles NA provider", {
  feed <- data.frame(
    id = "mdb-1",
    provider = NA_character_,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(is.character(summary))
  expect_true(grepl("mdb-1", summary))
})

test_that("format_feed_summary creates multiline output with details", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    status = "active",
    official = TRUE,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)
  expect_true(grepl("\n", summary))
})
