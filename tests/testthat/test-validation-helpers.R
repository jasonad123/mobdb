test_that("get_validation_report extracts from dataset data", {
  dataset <- data.frame(
    id = "ds-1",
    feed_id = "mdb-1",
    stringsAsFactors = FALSE
  )

  dataset$validation_report <- data.frame(
    total_error = 5,
    total_warning = 10,
    total_info = 2,
    unique_error_count = 3,
    unique_warning_count = 7,
    unique_info_count = 1,
    url_html = "https://example.com/report.html",
    url_json = "https://example.com/report.json",
    validated_at = "2024-01-01T12:00:00Z",
    validator_version = "4.0.0",
    stringsAsFactors = FALSE
  )

  result <- get_validation_report(dataset)

  expect_s3_class(result, "tbl_df")
  expect_equal(result$dataset_id, "ds-1")
  expect_equal(result$feed_id, "mdb-1")
  expect_equal(result$total_error, 5)
  expect_equal(result$total_warning, 10)
  expect_equal(result$unique_error_count, 3)
})

test_that("get_validation_report extracts from search results", {
  search_result <- data.frame(
    id = "mdb-1",
    provider = "Test Transit",
    stringsAsFactors = FALSE
  )

  search_result$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  search_result$latest_dataset$validation_report <- data.frame(
    total_error = 3,
    total_warning = 8,
    total_info = 1,
    unique_error_count = 2,
    unique_warning_count = 5,
    unique_info_count = 1,
    url_html = "https://example.com/report.html",
    url_json = "https://example.com/report.json",
    validated_at = "2024-01-01T12:00:00Z",
    validator_version = "4.0.0",
    stringsAsFactors = FALSE
  )

  result <- get_validation_report(search_result)

  expect_s3_class(result, "tbl_df")
  expect_equal(result$feed_id, "mdb-1")
  expect_equal(result$provider, "Test Transit")
  expect_equal(result$dataset_id, "ds-1")
  expect_equal(result$total_error, 3)
})

test_that("get_validation_report handles missing feed_id in dataset", {
  dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  dataset$validation_report <- data.frame(
    total_error = 5,
    total_warning = 10,
    total_info = 2,
    unique_error_count = 3,
    unique_warning_count = 7,
    unique_info_count = 1,
    url_html = "https://example.com/report.html",
    url_json = "https://example.com/report.json",
    validated_at = "2024-01-01T12:00:00Z",
    validator_version = "4.0.0",
    stringsAsFactors = FALSE
  )

  result <- get_validation_report(dataset)

  expect_true(is.na(result$feed_id))
})

test_that("get_validation_report handles missing provider in search results", {
  search_result <- data.frame(
    id = "mdb-1",
    stringsAsFactors = FALSE
  )

  search_result$latest_dataset <- data.frame(
    id = "ds-1",
    stringsAsFactors = FALSE
  )

  search_result$latest_dataset$validation_report <- data.frame(
    total_error = 3,
    total_warning = 8,
    total_info = 1,
    unique_error_count = 2,
    unique_warning_count = 5,
    unique_info_count = 1,
    url_html = "https://example.com/report.html",
    url_json = "https://example.com/report.json",
    validated_at = "2024-01-01T12:00:00Z",
    validator_version = "4.0.0",
    stringsAsFactors = FALSE
  )

  result <- get_validation_report(search_result)

  expect_true(is.na(result$provider))
})

test_that("get_validation_report errors on non-data.frame input", {
  expect_error(
    get_validation_report("not a data frame"),
    "must be a data frame"
  )

  expect_error(
    get_validation_report(list(id = "test")),
    "must be a data frame"
  )
})

test_that("get_validation_report warns on empty data frame", {
  empty_df <- data.frame()

  expect_warning(
    result <- get_validation_report(empty_df),
    "Empty data frame"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("get_validation_report warns when validation_report is not a data frame", {
  dataset <- data.frame(
    id = "ds-1",
    validation_report = "not a data frame",
    stringsAsFactors = FALSE
  )

  expect_warning(
    result <- get_validation_report(dataset),
    "No validation report data found"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("get_validation_report warns when latest_dataset validation_report is not a data frame", {
  search_result <- data.frame(
    id = "mdb-1",
    stringsAsFactors = FALSE
  )

  search_result$latest_dataset <- data.frame(
    id = "ds-1",
    validation_report = "not a data frame",
    stringsAsFactors = FALSE
  )

  expect_warning(
    result <- get_validation_report(search_result),
    "No validation report data found"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("get_validation_report errors when no validation data columns present", {
  data <- data.frame(
    id = "test-1",
    name = "Test",
    stringsAsFactors = FALSE
  )

  expect_error(
    get_validation_report(data),
    "Could not find validation data"
  )
})

# Note: filter_by_validation is an internal function that expects data frames
# from the API, not list structures. Testing its usage pattern would require
# mocking full API responses, which is better tested through integration tests.
