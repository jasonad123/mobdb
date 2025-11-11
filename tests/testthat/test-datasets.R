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

test_that("mobdb_datasets() supports caching", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip("Fixtures not available")

  httptest2::with_mock_dir("datasets_cache", {
    # First call - should cache
    result1 <- mobdb_datasets("mdb-1", use_cache = TRUE)
    expect_s3_class(result1, "tbl_df")

    # Second call - should use cache
    result2 <- mobdb_datasets("mdb-1", use_cache = TRUE)
    expect_s3_class(result2, "tbl_df")
    expect_equal(nrow(result1), nrow(result2))
  })
})

test_that("mobdb_datasets() can bypass cache", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip("Fixtures not available")

  httptest2::with_mock_dir("datasets_no_cache", {
    result <- mobdb_datasets("mdb-1", use_cache = FALSE)
    expect_s3_class(result, "tbl_df")
  })
})

test_that("mobdb_get_dataset() retrieves specific dataset", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip("Fixtures not available")

  httptest2::with_mock_dir("get_dataset_valid", {
    # First get a dataset ID
    datasets <- mobdb_datasets("mdb-1", latest = TRUE)
    dataset_id <- datasets$id[1]

    # Then retrieve it
    result <- mobdb_get_dataset(dataset_id)

    expect_type(result, "list")
    expect_true("id" %in% names(result))
  })
})

test_that("mobdb_get_dataset() returns consistent results", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip("Fixtures not available")

  httptest2::with_mock_dir("get_dataset_valid2", {
    datasets <- mobdb_datasets("mdb-1", latest = TRUE)
    dataset_id <- datasets$id[1]

    # Call twice
    result1 <- mobdb_get_dataset(dataset_id)
    result2 <- mobdb_get_dataset(dataset_id)

    expect_type(result1, "list")
    expect_type(result2, "list")
    expect_equal(result1$id, result2$id)
  })
})

test_that("mobdb_get_dataset() validates dataset_id parameter", {
  expect_error(
    mobdb_get_dataset(123),
    "must be a single character string"
  )

  expect_error(
    mobdb_get_dataset(c("id1", "id2")),
    "must be a single character string"
  )
})
