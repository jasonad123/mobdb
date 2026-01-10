test_that("download_best_feed requires search parameters", {
  skip_if_not_installed("tidytransit")

  expect_error(
    download_best_feed(),
    "At least one search parameter must be provided"
  )
})

test_that("score_feed_quality scores active feeds higher", {
  feed_active <- data.frame(
    id = "mdb-1",
    status = "active",
    official = TRUE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  feed_future <- data.frame(
    id = "mdb-2",
    status = "future",
    official = TRUE,
    created_at = "2024-01-01",
    stringsAsFactors = FALSE
  )

  score_active <- mobdb:::score_feed_quality(feed_active, prefer_official = TRUE, prefer_active = TRUE)
  score_future <- mobdb:::score_feed_quality(feed_future, prefer_official = TRUE, prefer_active = TRUE)

  expect_true(score_active > score_future)
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

  expect_true(score_official > score_unofficial)
})

test_that("format_feed_summary creates readable summary", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    feed_name = "Test Transit",
    status = "active",
    official = TRUE,
    stringsAsFactors = FALSE
  )

  summary <- mobdb:::format_feed_summary(feed, include_validation = FALSE)

  expect_true(grepl("\\[mdb-1\\]", summary))
  expect_true(grepl("Test Transit", summary))
  expect_true(grepl("Status: active", summary))
  expect_true(grepl("Official: TRUE", summary))
})

test_that("select_best_feed returns single feed when only one provided", {
  feed <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    status = "active",
    official = TRUE,
    stringsAsFactors = FALSE
  )

  result <- mobdb:::select_best_feed(feed)

  expect_equal(nrow(result), 1)
  expect_equal(result$id, "mdb-1")
})

test_that("select_best_feed selects highest scoring feed", {
  feeds <- data.frame(
    id = c("mdb-1", "mdb-2", "mdb-3"),
    provider = c("Transit A", "Transit B", "Transit C"),
    status = c("deprecated", "active", "future"),
    official = c(TRUE, TRUE, TRUE),
    created_at = rep("2024-01-01", 3),
    stringsAsFactors = FALSE
  )

  result <- mobdb:::select_best_feed(feeds, prefer_official = TRUE, prefer_active = TRUE)

  # Should select mdb-2 (active status)
  expect_equal(result$id, "mdb-2")
})

test_that("find_active_dataset handles errors gracefully", {
  skip_on_cran()
  skip_if_offline()

  # Invalid feed ID should error from mobdb_datasets
  # This is expected behavior
  expect_error(
    mobdb:::find_active_dataset("mdb-nonexistent"),
    "404"
  )
})
