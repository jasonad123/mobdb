# Tests for search functionality

test_that("mobdb_search() validates query parameter", {
  expect_error(
    mobdb_search(""),
    "must be a non-empty character string"
  )

  expect_error(
    mobdb_search(NULL),
    "must be a non-empty character string"
  )

  expect_error(
    mobdb_search(c("a", "b")),
    "must be a non-empty character string"
  )
})

test_that("mobdb_search() validates data_type parameter", {
  expect_error(
    mobdb_search("test", data_type = "invalid"),
    "should be one of"
  )
})

test_that("mobdb_search() validates status parameter", {
  expect_error(
    mobdb_search("test", status = "invalid"),
    "should be one of"
  )
})

test_that("mobdb_search() enforces feed_id exclusivity", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_search("test", feed_id = "mdb-1", data_type = "gtfs"),
    "When.*feed_id.*is provided"
  )

  expect_error(
    mobdb_search("test", feed_id = "mdb-1", official = TRUE),
    "When.*feed_id.*is provided"
  )
})

test_that("mobdb_search() validates gtfs_feature is only for GTFS", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_search("test", data_type = "gbfs", gtfs_feature = "fares-v2"),
    "gtfs_feature.*can only be used with GTFS"
  )
})

test_that("mobdb_search() validates gbfs_version is only for GBFS", {
  skip_if_not_installed("httptest2")

  expect_error(
    mobdb_search("test", data_type = "gtfs", gbfs_version = "2.0"),
    "gbfs_version.*can only be used with GBFS"
  )
})

test_that("mobdb_search() performs basic search", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_basic"), "Fixtures not available")

  httptest2::with_mock_dir("search_basic", {
    result <- mobdb_search("transit", limit = 10)

    expect_s3_class(result, "tbl_df")
    expect_true("id" %in% names(result))
    expect_true("provider" %in% names(result))
  })
})

test_that("mobdb_search() with data_type filter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_gtfs_only"), "Fixtures not available")

  httptest2::with_mock_dir("search_gtfs_only", {
    result <- mobdb_search("transit", data_type = "gtfs", limit = 5)

    expect_s3_class(result, "tbl_df")
    if (nrow(result) > 0) {
      expect_true(all(result$data_type == "gtfs"))
    }
  })
})

test_that("mobdb_search() with official filter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_official"), "Fixtures not available")

  httptest2::with_mock_dir("search_official", {
    result <- mobdb_search("metro", official = TRUE, limit = 5)

    expect_s3_class(result, "tbl_df")
  })
})

test_that("mobdb_search() with status filter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_active"), "Fixtures not available")

  httptest2::with_mock_dir("search_active", {
    result <- mobdb_search("transit", status = "active", limit = 5)

    expect_s3_class(result, "tbl_df")
    if (nrow(result) > 0) {
      expect_true(all(result$status == "active"))
    }
  })
})

test_that("mobdb_search() with pagination", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_pagination"), "Fixtures not available")

  httptest2::with_mock_dir("search_pagination", {
    result <- mobdb_search("metro", limit = 10, offset = 0)

    expect_s3_class(result, "tbl_df")
  })
})

test_that("mobdb_search() handles empty results", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_empty"), "Fixtures not available")

  httptest2::with_mock_dir("search_empty", {
    result <- mobdb_search("xyznonexistentquery999")

    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 0)
  })
})

test_that("mobdb_search() respects use_cache parameter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("search_caching"), "Fixtures not available")

  # Clear cache for this test
  cache_dir <- get_mobdb_cache_path()
  if (dir.exists(cache_dir)) {
    unlink(file.path(cache_dir, "search_*.rds"))
  }

  httptest2::with_mock_dir("search_caching", {
    # First call with caching
    result1 <- mobdb_search("metro", limit = 5, use_cache = TRUE)

    # Check cache file exists
    cache_files <- list.files(cache_dir, pattern = "^search_", full.names = TRUE)
    expect_true(length(cache_files) > 0)

    # Second call should use cache (no new HTTP request)
    result2 <- mobdb_search("metro", limit = 5, use_cache = TRUE)
    expect_identical(result1, result2)

    # Call with use_cache = FALSE should bypass cache
    result3 <- mobdb_search("metro", limit = 5, use_cache = FALSE)
    expect_s3_class(result3, "tbl_df")
  })
})
