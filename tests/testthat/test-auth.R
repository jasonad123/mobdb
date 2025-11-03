test_that("mobdb_set_key validates input", {
  expect_error(
    mobdb_set_key(123),
    class = "rlang_error"
  )
  
  expect_error(
    mobdb_set_key(c("token1", "token2")),
    class = "rlang_error"
  )
  
  expect_error(
    mobdb_set_key(""),
    class = "rlang_error"
  )
})

test_that("mobdb_set_key stores token in environment", {
  test_token <- "test_refresh_token_12345"
  
  result <- mobdb_set_key(test_token, install = FALSE)
  
  expect_true(result)
  expect_equal(mobdb_env$refresh_token, test_token)
  expect_null(mobdb_env$access_token)
})

test_that("mobdb_has_key detects token presence", {
  # Clear any existing token
  mobdb_env$refresh_token <- NULL
  
  withr::with_envvar(
    c(MOBDB_REFRESH_TOKEN = ""),
    {
      expect_false(mobdb_has_key())
    }
  )
  
  mobdb_env$refresh_token <- "test_token"
  expect_true(mobdb_has_key())
  
  # Clean up
  mobdb_env$refresh_token <- NULL
})

test_that("mobdb_token fails when no refresh token is set", {
  mobdb_env$refresh_token <- NULL
  
  withr::with_envvar(
    c(MOBDB_REFRESH_TOKEN = ""),
    {
      expect_error(
        mobdb_token(),
        class = "rlang_error"
      )
    }
  )
})
