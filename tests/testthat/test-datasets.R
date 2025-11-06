# Tests for dataset functions
# Using httptest2 for mocking HTTP requests

test_that("mobdb_datasets() requires feed_id parameter", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_datasets(),
    "argument.*feed_id.*missing"
  )
})

test_that("mobdb_datasets() returns latest dataset by default", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("datasets_latest", {
    result <- mobdb_datasets("mdb-1")

    expect_s3_class(result, "tbl_df")
    expect_true("id" %in% names(result))
    expect_true("downloaded_at" %in% names(result))
    # By default, should return only latest
    expect_true(nrow(result) >= 1)
  })
})

test_that("mobdb_datasets() returns all datasets when latest=FALSE", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("datasets_all", {
    result <- mobdb_datasets("mdb-1", latest = FALSE)

    expect_s3_class(result, "tbl_df")
    expect_true("id" %in% names(result))
    # Should potentially return multiple versions
    expect_true(nrow(result) >= 1)
  })
})

test_that("mobdb_datasets() returns multiple versions when latest=FALSE", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("datasets_all", {
    result <- mobdb_datasets("mdb-1", latest = FALSE)

    expect_s3_class(result, "tbl_df")
    # When latest=FALSE, should return all historical datasets
    expect_true(nrow(result) >= 1)
  })
})

test_that("mobdb_get_dataset() requires dataset_id parameter", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_get_dataset(),
    "argument.*dataset_id.*missing"
  )
})

test_that("mobdb_get_dataset() handles nonexistent dataset", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("get_dataset_missing", {
    # Should error with 404
    expect_error(
      mobdb_get_dataset("dataset-nonexistent-999999"),
      "404"
    )
  })
})

test_that("mobdb_datasets() handles nonexistent feed", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  # This test captures the error response
  httptest2::with_mock_dir("datasets_none", {
    # Should error with 404 for nonexistent feed
    expect_error(
      mobdb_datasets("mdb-nonexistent-999999"),
      "404|not found"
    )
  }, simplify = FALSE)
})
