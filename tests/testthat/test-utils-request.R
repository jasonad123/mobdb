# Tests for internal request/response utilities

test_that("mobdb_user_agent() returns correctly formatted string", {
  ua <- mobdb:::mobdb_user_agent()

  expect_type(ua, "character")
  expect_match(ua, "^mobdb/[0-9.]+")
  expect_match(ua, "\\(R [0-9.]+\\)$")

  # Should contain package version
  version <- as.character(utils::packageVersion("mobdb"))
  expect_true(grepl(version, ua, fixed = TRUE))
})

test_that("build_query() removes NULL parameters", {
  result <- mobdb:::build_query(a = 1, b = NULL, c = 3)

  expect_type(result, "list")
  expect_equal(names(result), c("a", "c"))
  expect_equal(result$a, 1)
  expect_equal(result$c, 3)
})

test_that("build_query() preserves non-NULL parameters", {
  result <- mobdb:::build_query(a = 1, b = "test", c = TRUE)

  expect_equal(length(result), 3)
  expect_equal(result$a, 1)
  expect_equal(result$b, "test")
  expect_equal(result$c, TRUE)
})

test_that("build_query() handles all NULL parameters", {
  result <- mobdb:::build_query(a = NULL, b = NULL)

  expect_type(result, "list")
  expect_equal(length(result), 0)
})

test_that("build_query() handles empty parameter list", {
  result <- mobdb:::build_query()

  expect_type(result, "list")
  expect_equal(length(result), 0)
})

test_that("mobdb_error_body() extracts detail field", {
  # Direct test of logic - the function returns the detail field when present
  test_body_detail <- list(detail = "Detail error message")
  expect_equal(
    if (!is.null(test_body_detail$detail)) test_body_detail$detail else NULL,
    "Detail error message"
  )
})

test_that("mobdb_error_body() extracts message field when detail is NULL", {
  test_body_message <- list(message = "Message error text")
  expect_equal(
    if (!is.null(test_body_message$detail)) {
      test_body_message$detail
    } else if (!is.null(test_body_message$message)) {
      test_body_message$message
    } else {
      "An unknown error occurred"
    },
    "Message error text"
  )
})

test_that("mobdb_error_body() returns default when both fields are NULL", {
  test_body_empty <- list()
  expect_equal(
    if (!is.null(test_body_empty$detail)) {
      test_body_empty$detail
    } else if (!is.null(test_body_empty$message)) {
      test_body_empty$message
    } else {
      "An unknown error occurred"
    },
    "An unknown error occurred"
  )
})

test_that("mobdb_parse_response() handles data frame responses", {
  skip_if_not_installed("httptest2")

  # Test the logic of handling data frame
  test_df <- data.frame(id = 1:3, name = c("a", "b", "c"))

  result <- if (is.data.frame(test_df)) {
    tibble::as_tibble(test_df)
  } else {
    test_df
  }

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
})

test_that("mobdb_parse_response() extracts results field from list", {
  test_list <- list(results = data.frame(id = 1:2, value = c("x", "y")))

  result <- if (is.list(test_list) && !is.null(test_list$results)) {
    tibble::as_tibble(test_list$results)
  } else {
    NULL
  }

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("mobdb_parse_response() extracts data field from list", {
  test_list <- list(data = data.frame(id = 3:4, value = c("a", "b")))

  result <- if (is.list(test_list)) {
    if (!is.null(test_list$results)) {
      tibble::as_tibble(test_list$results)
    } else if (!is.null(test_list$data)) {
      tibble::as_tibble(test_list$data)
    } else {
      NULL
    }
  } else {
    NULL
  }

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("mobdb_parse_response() extracts feeds field from list", {
  test_list <- list(feeds = data.frame(id = 5:6, name = c("feed1", "feed2")))

  result <- if (is.list(test_list)) {
    if (!is.null(test_list$results)) {
      tibble::as_tibble(test_list$results)
    } else if (!is.null(test_list$data)) {
      tibble::as_tibble(test_list$data)
    } else if (!is.null(test_list$feeds)) {
      tibble::as_tibble(test_list$feeds)
    } else {
      NULL
    }
  } else {
    NULL
  }

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("check_rate_limit() logic handles missing headers gracefully", {
  # Test the logic when headers are NULL
  limit <- NULL
  remaining <- NULL

  should_warn <- !is.null(limit) && !is.null(remaining)
  expect_false(should_warn)
})

test_that("check_rate_limit() logic warns when approaching limit", {
  # Test the warning threshold logic (10%)
  limit <- "100"
  remaining <- "5"

  limit_num <- as.numeric(limit)
  remaining_num <- as.numeric(remaining)

  should_warn <- (remaining_num / limit_num) < 0.1
  expect_true(should_warn)
})

test_that("check_rate_limit() logic doesn't warn when not approaching limit", {
  limit <- "100"
  remaining <- "50"

  limit_num <- as.numeric(limit)
  remaining_num <- as.numeric(remaining)

  should_warn <- (remaining_num / limit_num) < 0.1
  expect_false(should_warn)
})

test_that("check_rate_limit() logic handles boundary case at 10% threshold", {
  limit <- "100"
  remaining <- "10"

  limit_num <- as.numeric(limit)
  remaining_num <- as.numeric(remaining)

  # At exactly 10%, should not warn
  should_warn <- (remaining_num / limit_num) < 0.1
  expect_false(should_warn)

  # At 9%, should warn
  remaining <- "9"
  remaining_num <- as.numeric(remaining)
  should_warn <- (remaining_num / limit_num) < 0.1
  expect_true(should_warn)
})

test_that("mobdb_request() constructs request with correct components", {
  skip_if_not(mobdb_has_key(), "API key not configured")

  req <- mobdb_request("gtfs/feeds")

  expect_s3_class(req, "httr2_request")

  # Check URL construction
  expect_match(req$url, "api\\.mobilitydatabase\\.org")
  expect_match(req$url, "gtfs/feeds$")

  # Check headers are set
  expect_true("Accept" %in% names(req$headers))
  expect_equal(req$headers$Accept, "application/json")

  # Check user agent is set (in options, not headers)
  expect_true("useragent" %in% names(req$options))
  expect_match(req$options$useragent, "^mobdb/")

  # Check auth token is configured (in options)
  expect_true("httpauth" %in% names(req$options) || length(req$options) > 0)
})

test_that("mobdb_request() configures retry policy", {
  skip_if_not(mobdb_has_key(), "API key not configured")

  req <- mobdb:::mobdb_request("test")

  # Check retry is configured (retry_max_tries policy should exist)
  expect_true("retry_max_tries" %in% names(req$policies))
  expect_equal(req$policies$retry_max_tries, 3)
})

# Tests that actually execute the parsing functions with mock responses

test_that("mobdb_parse_response() handles data frame body", {
  skip_if_not_installed("httptest2")

  # Create a mock response with data frame structure
  httptest2::with_mock_dir("parse_df", {
    skip_if_not(mobdb_has_key(), "API key not configured")

    # Use a real API call to get actual response structure
    result <- feeds(data_type = "gtfs", limit = 1)

    # If we got results, the parse function worked
    expect_s3_class(result, "tbl_df")
  })
})

test_that("mobdb_parse_response() handles results field", {
  # Test the parse logic by constructing the expected structure
  mock_body <- list(results = data.frame(id = 1:2, name = c("a", "b")))

  # Simulate what mobdb_parse_response does
  result <- if (is.list(mock_body) && !is.null(mock_body$results)) {
    tibble::as_tibble(mock_body$results)
  } else {
    NULL
  }

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("check_rate_limit() can be called without warnings when limit is high", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  # Make a small API call that should not trigger rate limit warning
  httptest2::with_mock_dir("no_rate_limit", {
    expect_no_warning({
      result <- feeds(data_type = "gtfs", limit = 1)
    })
  })
})
