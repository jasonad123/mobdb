test_that("score_feed_quality scores active feeds higher than deprecated", {
  feed_active <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_deprecated <- data.frame(
    id = "mdb-2",
    status = "deprecated",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score_active <- mobdb:::score_feed_quality(feed_active, prefer_official = FALSE, prefer_active = TRUE)
  score_deprecated <- mobdb:::score_feed_quality(feed_deprecated, prefer_official = FALSE, prefer_active = TRUE)

  expect_gt(score_active, score_deprecated)
})

test_that("score_feed_quality handles all status values", {
  statuses <- c("active", "future", "development", "deprecated", "inactive")

  for (status in statuses) {
    feed <- data.frame(
      id = "mdb-1",
      status = status,
      official = FALSE,
      created_at = "2024-01-01",
      stringsAsFactors = FALSE
    )

    score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
    expect_true(is.numeric(score))
    expect_true(score >= 0)
  }
})

test_that("score_feed_quality handles NA status", {
  feed <- data.frame(
    id = "mdb-1",
    status = NA_character_,
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})

test_that("score_feed_quality scores official feeds higher", {
  feed_official <- data.frame(
    id = "mdb-1",
    status = "active",
    official = TRUE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_unofficial <- data.frame(
    id = "mdb-2",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score_official <- mobdb:::score_feed_quality(feed_official, prefer_official = TRUE, prefer_active = TRUE)
  score_unofficial <- mobdb:::score_feed_quality(feed_unofficial, prefer_official = TRUE, prefer_active = TRUE)

  expect_gt(score_official, score_unofficial)
  expect_equal(as.numeric(score_official) - as.numeric(score_unofficial), 50)
})

test_that("score_feed_quality handles NA official status", {
  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = NA,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = TRUE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})

test_that("score_feed_quality respects prefer_official = FALSE", {
  feed_official <- data.frame(
    id = "mdb-1",
    status = "active",
    official = TRUE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_unofficial <- data.frame(
    id = "mdb-2",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score_official <- mobdb:::score_feed_quality(feed_official, prefer_official = FALSE, prefer_active = TRUE)
  score_unofficial <- mobdb:::score_feed_quality(feed_unofficial, prefer_official = FALSE, prefer_active = TRUE)

  expect_equal(score_official, score_unofficial)
})

test_that("score_feed_quality respects prefer_active = FALSE", {
  feed_active <- data.frame(
    id = "mdb-1",
    status = "active",
    official = TRUE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_deprecated <- data.frame(
    id = "mdb-2",
    status = "deprecated",
    official = TRUE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score_active <- mobdb:::score_feed_quality(feed_active, prefer_official = TRUE, prefer_active = FALSE)
  score_deprecated <- mobdb:::score_feed_quality(feed_deprecated, prefer_official = TRUE, prefer_active = FALSE)

  expect_equal(score_active, score_deprecated)
})

test_that("score_feed_quality gives bonus for recent feeds", {
  feed_recent <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = as.character(Sys.Date() - 100),
    stringsAsFactors = FALSE
  )

  feed_old <- data.frame(
    id = "mdb-2",
    status = "active",
    official = FALSE,
    created_at = as.character(Sys.Date() - 500),
    stringsAsFactors = FALSE
  )

  score_recent <- mobdb:::score_feed_quality(feed_recent, prefer_official = FALSE, prefer_active = TRUE)
  score_old <- mobdb:::score_feed_quality(feed_old, prefer_official = FALSE, prefer_active = TRUE)

  expect_gt(score_recent, score_old)
})

test_that("score_feed_quality handles NA created_at", {
  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = NA_character_,
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})

test_that("score_feed_quality gives bonus for current service dates", {
  today <- Sys.Date()

  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    service_date_range_start = as.character(today - 30),
    service_date_range_end = as.character(today + 30),
    stringsAsFactors = FALSE
  )

  score_with_dates <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)

  feed_no_dates <- data.frame(
    id = "mdb-2",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score_without_dates <- mobdb:::score_feed_quality(feed_no_dates, prefer_official = FALSE, prefer_active = TRUE)

  expect_gt(score_with_dates, score_without_dates)
})

test_that("score_feed_quality handles future service dates", {
  today <- Sys.Date()

  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    service_date_range_start = as.character(today + 30),
    service_date_range_end = as.character(today + 60),
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
  expect_gt(score, 0)
})

test_that("score_feed_quality handles recently expired service dates", {
  today <- Sys.Date()

  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    service_date_range_start = as.character(today - 60),
    service_date_range_end = as.character(today - 15),
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})

test_that("score_feed_quality gives bonus for feeds with no validation errors", {
  feed_no_errors <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_no_errors$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  feed_no_errors$latest_dataset$validation_report <- data.frame(
    total_error = 0,
    stringsAsFactors = FALSE
  )

  feed_with_errors <- data.frame(
    id = "mdb-2",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_with_errors$latest_dataset <- data.frame(
    id = "ds-2",
    stringsAsFactors = FALSE
  )

  feed_with_errors$latest_dataset$validation_report <- data.frame(
    total_error = 25,
    stringsAsFactors = FALSE
  )

  score_no_errors <- mobdb:::score_feed_quality(feed_no_errors, prefer_official = FALSE, prefer_active = TRUE)
  score_with_errors <- mobdb:::score_feed_quality(feed_with_errors, prefer_official = FALSE, prefer_active = TRUE)

  expect_gt(score_no_errors, score_with_errors)
})

test_that("score_feed_quality handles feeds with few validation errors", {
  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset$validation_report <- data.frame(
    total_error = 3,
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
  expect_gt(score, 0)
})

test_that("score_feed_quality handles NA validation errors", {
  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset$validation_report <- data.frame(
    total_error = NA_integer_,
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})

test_that("score_feed_quality handles missing latest_dataset", {
  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})

test_that("score_feed_quality handles NULL latest_dataset", {
  feed <- data.frame(
    id = "mdb-1",
    status = "active",
    official = FALSE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed$latest_dataset <- NULL

  score <- mobdb:::score_feed_quality(feed, prefer_official = FALSE, prefer_active = TRUE)
  expect_true(is.numeric(score))
})
