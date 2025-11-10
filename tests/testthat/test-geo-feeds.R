# Tests for geographic feed search functionality

test_that("extract_bbox() validates numeric bbox", {
  expect_error(
    extract_bbox(c(1, 2, 3)),
    "must be a numeric vector of length 4"
  )

  expect_error(
    extract_bbox("invalid"),
    "must be a numeric vector of length 4"
  )

  expect_error(
    extract_bbox(list(1, 2, 3, 4)),
    "must be a numeric vector of length 4"
  )
})

test_that("extract_bbox() validates coordinate ranges", {
  # Invalid latitude ranges
  expect_error(
    extract_bbox(c(-122, -91, -121, 38)),
    "Latitude values must be between -90 and 90"
  )

  expect_error(
    extract_bbox(c(-122, 37, -121, 91)),
    "Latitude values must be between -90 and 90"
  )

  # Invalid longitude ranges
  expect_error(
    extract_bbox(c(-181, 37, -121, 38)),
    "Longitude values must be between -180 and 180"
  )

  expect_error(
    extract_bbox(c(-122, 37, 181, 38)),
    "Longitude values must be between -180 and 180"
  )
})

test_that("extract_bbox() validates min < max", {
  # min_lon >= max_lon
  expect_error(
    extract_bbox(c(-121, 37, -122, 38)),
    "min_lon must be less than max_lon"
  )

  # min_lat >= max_lat
  expect_error(
    extract_bbox(c(-122, 38, -121, 37)),
    "min_lat must be less than max_lat"
  )
})

test_that("extract_bbox() extracts valid numeric bbox", {
  bbox_coords <- extract_bbox(c(-122.5, 37.2, -121.8, 38.0))

  expect_type(bbox_coords, "list")
  expect_equal(bbox_coords$min_lon, -122.5)
  expect_equal(bbox_coords$min_lat, 37.2)
  expect_equal(bbox_coords$max_lon, -121.8)
  expect_equal(bbox_coords$max_lat, 38.0)
})

test_that("extract_bbox() handles sf bbox objects", {
  skip_if_not_installed("sf")

  # Create a simple sf bbox object
  bbox_sf <- structure(
    c(xmin = -122.5, ymin = 37.2, xmax = -121.8, ymax = 38.0),
    class = "bbox",
    crs = structure(list(input = "EPSG:4326"), class = "crs")
  )

  bbox_coords <- extract_bbox(bbox_sf)

  expect_type(bbox_coords, "list")
  expect_equal(bbox_coords$min_lon, -122.5)
  expect_equal(bbox_coords$min_lat, 37.2)
  expect_equal(bbox_coords$max_lon, -121.8)
  expect_equal(bbox_coords$max_lat, 38.0)
})

test_that("feeds_bbox() validates filter_method parameter", {
  expect_error(
    feeds_bbox(c(-122, 37, -121, 38), filter_method = "invalid"),
    "should be one of"
  )
})

test_that("feeds_bbox() validates status parameter", {
  expect_error(
    feeds_bbox(c(-122, 37, -121, 38), status = "invalid"),
    "should be one of"
  )
})

test_that("feeds_bbox() performs geographic search with default method", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("bbox_default"), "Fixtures not available")

  httptest2::with_mock_dir("bbox_default", {
    result <- feeds_bbox(
      bbox = c(-122.5, 37.2, -121.8, 38.0),
      limit = 10
    )

    expect_s3_class(result, "tbl_df")
    expect_true("id" %in% names(result))
    expect_true("provider" %in% names(result))
    expect_true("data_type" %in% names(result))
  })
})

test_that("feeds_bbox() with partially_enclosed method", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("bbox_partial"), "Fixtures not available")

  httptest2::with_mock_dir("bbox_partial", {
    result <- feeds_bbox(
      bbox = c(-118.9, 33.7, -118.0, 34.8),
      filter_method = "partially_enclosed",
      limit = 10
    )

    expect_s3_class(result, "tbl_df")
  })
})

test_that("feeds_bbox() with additional filters", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("bbox_filters"), "Fixtures not available")

  httptest2::with_mock_dir("bbox_filters", {
    result <- feeds_bbox(
      bbox = c(-122.5, 37.2, -121.8, 38.0),
      status = "active",
      official = TRUE,
      limit = 10
    )

    expect_s3_class(result, "tbl_df")
  })
})

test_that("feeds_bbox() respects use_cache parameter", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("bbox_cache"), "Fixtures not available")

  # Clear cache for this test
  cache_dir <- get_mobdb_cache_path()
  if (dir.exists(cache_dir)) {
    unlink(file.path(cache_dir, "feeds_bbox_*.rds"))
  }

  httptest2::with_mock_dir("bbox_cache", {
    # First call with caching
    result1 <- feeds_bbox(
      bbox = c(-122.5, 37.2, -121.8, 38.0),
      limit = 5,
      use_cache = TRUE
    )

    # Check cache file exists
    cache_files <- list.files(cache_dir, pattern = "^feeds_bbox_", full.names = TRUE)
    expect_true(length(cache_files) > 0)

    # Second call should use cache
    result2 <- feeds_bbox(
      bbox = c(-122.5, 37.2, -121.8, 38.0),
      limit = 5,
      use_cache = TRUE
    )
    expect_identical(result1, result2)
  })
})

test_that("feeds_bbox() filters official status correctly", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")
  skip_if_not(fixture_exists("bbox_official"), "Fixtures not available")

  httptest2::with_mock_dir("bbox_official", {
    result <- feeds_bbox(
      bbox = c(-122.5, 37.2, -121.8, 38.0),
      official = TRUE,
      limit = 10
    )

    expect_s3_class(result, "tbl_df")
    # Post-filter should ensure all results are official
    if (nrow(result) > 0) {
      expect_true(all(result$official == TRUE, na.rm = TRUE))
    }
  })
})
