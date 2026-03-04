# Tests for GTFS date/time format conversion utilities

# --- Date conversion tests ---

test_that("convert_dates_to_gtfs_format converts Date columns in calendar", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      start_date = as.Date("2024-01-15"),
      end_date = as.Date("2024-12-31"),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(result$calendar$start_date, "20240115")
  expect_equal(result$calendar$end_date, "20241231")
  expect_type(result$calendar$start_date, "character")
})

test_that("convert_dates_to_gtfs_format converts calendar_dates", {
  mock_gtfs <- list(
    calendar_dates = data.frame(
      service_id = c("s1", "s1"),
      date = as.Date(c("2024-07-04", "2024-12-25")),
      exception_type = c(2L, 2L),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(result$calendar_dates$date, c("20240704", "20241225"))
})

test_that("convert_dates_to_gtfs_format converts feed_info dates", {
  mock_gtfs <- list(
    feed_info = data.frame(
      feed_publisher_name = "Test",
      feed_start_date = as.Date("2024-01-01"),
      feed_end_date = as.Date("2024-06-30"),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(result$feed_info$feed_start_date, "20240101")
  expect_equal(result$feed_info$feed_end_date, "20240630")
})

test_that("convert_dates_to_gtfs_format leaves integer dates unchanged", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      start_date = 20240115L,
      end_date = 20241231L,
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(result$calendar$start_date, 20240115L)
  expect_equal(result$calendar$end_date, 20241231L)
})

test_that("convert_dates_to_gtfs_format leaves character dates unchanged", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      start_date = "20240115",
      end_date = "20241231",
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(result$calendar$start_date, "20240115")
  expect_equal(result$calendar$end_date, "20241231")
})

test_that("convert_dates_to_gtfs_format handles NA dates", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = c("s1", "s2"),
      start_date = as.Date(c("2024-01-15", NA)),
      end_date = as.Date(c(NA, "2024-12-31")),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(result$calendar$start_date[1], "20240115")
  expect_true(is.na(result$calendar$start_date[2]))
  expect_true(is.na(result$calendar$end_date[1]))
  expect_equal(result$calendar$end_date[2], "20241231")
})

# --- Time conversion tests ---

test_that("convert_times_to_gtfs_format converts hms columns", {
  skip_if_not_installed("hms")
  mock_gtfs <- list(
    stop_times = data.frame(
      trip_id = "t1",
      arrival_time = hms::hms(hours = 8, minutes = 30, seconds = 0),
      departure_time = hms::hms(hours = 8, minutes = 31, seconds = 0),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_times_to_gtfs_format(mock_gtfs)
  expect_equal(result$stop_times$arrival_time, "08:30:00")
  expect_equal(result$stop_times$departure_time, "08:31:00")
  expect_type(result$stop_times$arrival_time, "character")
})

test_that("convert_times_to_gtfs_format preserves times >= 24:00:00", {
  skip_if_not_installed("hms")
  mock_gtfs <- list(
    stop_times = data.frame(
      trip_id = "t1",
      arrival_time = hms::hms(hours = 25, minutes = 30, seconds = 0),
      departure_time = hms::hms(hours = 26, minutes = 0, seconds = 15),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_times_to_gtfs_format(mock_gtfs)
  expect_equal(result$stop_times$arrival_time, "25:30:00")
  expect_equal(result$stop_times$departure_time, "26:00:15")
})

test_that("convert_times_to_gtfs_format handles frequencies table", {
  skip_if_not_installed("hms")
  mock_gtfs <- list(
    frequencies = data.frame(
      trip_id = "t1",
      start_time = hms::hms(hours = 6, minutes = 0, seconds = 0),
      end_time = hms::hms(hours = 22, minutes = 0, seconds = 0),
      headway_secs = 600L,
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_times_to_gtfs_format(mock_gtfs)
  expect_equal(result$frequencies$start_time, "06:00:00")
  expect_equal(result$frequencies$end_time, "22:00:00")
})

test_that("convert_times_to_gtfs_format handles NA times", {
  skip_if_not_installed("hms")
  mock_gtfs <- list(
    stop_times = data.frame(
      trip_id = c("t1", "t2"),
      arrival_time = hms::hms(c(30600, NA)),
      departure_time = hms::hms(c(NA, 31200)),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_times_to_gtfs_format(mock_gtfs)
  expect_equal(result$stop_times$arrival_time[1], "08:30:00")
  expect_true(is.na(result$stop_times$arrival_time[2]))
  expect_true(is.na(result$stop_times$departure_time[1]))
  expect_equal(result$stop_times$departure_time[2], "08:40:00")
})

test_that("convert_times_to_gtfs_format leaves character times unchanged", {
  mock_gtfs <- list(
    stop_times = data.frame(
      trip_id = "t1",
      arrival_time = "08:30:00",
      departure_time = "25:30:00",
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_times_to_gtfs_format(mock_gtfs)
  expect_equal(result$stop_times$arrival_time, "08:30:00")
  expect_equal(result$stop_times$departure_time, "25:30:00")
})

# --- Edge cases ---

test_that("conversion handles missing tables gracefully", {
  mock_gtfs <- list(
    agency = data.frame(agency_name = "Test", stringsAsFactors = FALSE)
  )
  expect_no_error(mobdb:::convert_dates_to_gtfs_format(mock_gtfs))
  expect_no_error(mobdb:::convert_times_to_gtfs_format(mock_gtfs))
})

test_that("conversion handles empty tables gracefully", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = character(0),
      start_date = as.Date(character(0)),
      end_date = as.Date(character(0)),
      stringsAsFactors = FALSE
    )
  )
  result <- mobdb:::convert_dates_to_gtfs_format(mock_gtfs)
  expect_equal(nrow(result$calendar), 0)
})

test_that("conversion handles tables with missing columns", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      monday = 1L,
      stringsAsFactors = FALSE
    )
  )
  # calendar exists but start_date/end_date columns are missing
  expect_no_error(mobdb:::convert_dates_to_gtfs_format(mock_gtfs))
})

# --- Validation tests ---

test_that("validate_gtfs_dates warns on NA dates", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = c("s1", "s2"),
      start_date = as.Date(c("2024-01-15", NA)),
      end_date = as.Date(c("2024-12-31", "2024-12-31")),
      stringsAsFactors = FALSE
    )
  )
  expect_warning(
    mobdb:::validate_gtfs_dates(mock_gtfs),
    "1 of 2.*start_date.*calendar.*NA"
  )
})

test_that("validate_gtfs_dates does not warn on clean data", {
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      start_date = as.Date("2024-01-15"),
      end_date = as.Date("2024-12-31"),
      stringsAsFactors = FALSE
    )
  )
  expect_no_warning(mobdb:::validate_gtfs_dates(mock_gtfs))
})

test_that("validate_gtfs_dates handles missing tables silently", {
  mock_gtfs <- list(
    agency = data.frame(agency_name = "Test", stringsAsFactors = FALSE)
  )
  expect_no_warning(mobdb:::validate_gtfs_dates(mock_gtfs))
})

# --- Public function tests ---

test_that("gtfs_to_spec_format converts all fields end-to-end", {
  skip_if_not_installed("hms")
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      start_date = as.Date("2024-01-01"),
      end_date = as.Date("2024-12-31"),
      stringsAsFactors = FALSE
    ),
    stop_times = data.frame(
      trip_id = "t1",
      arrival_time = hms::hms(hours = 25, minutes = 30, seconds = 0),
      departure_time = hms::hms(hours = 25, minutes = 31, seconds = 0),
      stringsAsFactors = FALSE
    )
  )
  result <- gtfs_to_spec_format(mock_gtfs)
  expect_equal(result$calendar$start_date, "20240101")
  expect_equal(result$calendar$end_date, "20241231")
  expect_equal(result$stop_times$arrival_time, "25:30:00")
  expect_equal(result$stop_times$departure_time, "25:31:00")
})

test_that("gtfs_to_spec_format does not modify original object", {
  skip_if_not_installed("hms")
  mock_gtfs <- list(
    calendar = data.frame(
      service_id = "s1",
      start_date = as.Date("2024-01-01"),
      end_date = as.Date("2024-12-31"),
      stringsAsFactors = FALSE
    )
  )
  result <- gtfs_to_spec_format(mock_gtfs)

  # Original should still have Date objects
  expect_s3_class(mock_gtfs$calendar$start_date, "Date")
  # Result should have character strings
  expect_type(result$calendar$start_date, "character")
})

test_that("gtfs_to_spec_format errors on non-list input", {
  expect_error(gtfs_to_spec_format("not a list"), "must be a list")
})
