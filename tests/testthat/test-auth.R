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

test_that("mobdb_set_key emits message on session-only install", {
  old_token <- mobdb_env$refresh_token
  on.exit(mobdb_env$refresh_token <- old_token, add = TRUE)

  expect_message(
    mobdb_set_key("test_token_msg", install = FALSE),
    "Refresh token set for current session"
  )
})

test_that("mobdb_set_key with install = TRUE writes .Renviron in non-interactive mode", {
  skip_if(interactive(), "Test requires non-interactive session")

  old_token <- mobdb_env$refresh_token
  on.exit(mobdb_env$refresh_token <- old_token, add = TRUE)

  # Use a temp directory to avoid writing to real .Renviron
  temp_home <- file.path(tempdir(), "mobdb_test_auth_home", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  withr::with_envvar(c(HOME = temp_home), {
    result <- mobdb_set_key("test_install_token", install = TRUE)
    expect_true(result)

    renviron_path <- file.path(temp_home, ".Renviron")
    expect_true(file.exists(renviron_path))

    lines <- readLines(renviron_path)
    expect_true(any(grepl("MOBDB_REFRESH_TOKEN=test_install_token", lines)))
  })
})

test_that("set_renviron_key writes token to .Renviron", {
  temp_home <- file.path(tempdir(), "mobdb_test_renviron", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  withr::with_envvar(c(HOME = temp_home), {
    mobdb:::set_renviron_key("my_test_token")

    renviron_path <- file.path(temp_home, ".Renviron")
    expect_true(file.exists(renviron_path))

    lines <- readLines(renviron_path)
    expect_true(any(grepl("^MOBDB_REFRESH_TOKEN=my_test_token$", lines)))
  })
})

test_that("set_renviron_key replaces existing token", {
  temp_home <- file.path(tempdir(), "mobdb_test_renviron_replace", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  withr::with_envvar(c(HOME = temp_home), {
    # Write initial token
    mobdb:::set_renviron_key("token_v1")

    # Overwrite with new token
    mobdb:::set_renviron_key("token_v2")

    lines <- readLines(file.path(temp_home, ".Renviron"))
    token_lines <- grep("^MOBDB_REFRESH_TOKEN=", lines, value = TRUE)

    # Should only have one entry with the new token
    expect_length(token_lines, 1)
    expect_equal(token_lines, "MOBDB_REFRESH_TOKEN=token_v2")
  })
})

test_that("set_renviron_key preserves other .Renviron entries", {
  temp_home <- file.path(tempdir(), "mobdb_test_renviron_preserve", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  renviron_path <- file.path(temp_home, ".Renviron")

  # Write existing content
  writeLines(c("OTHER_VAR=keep_me", "ANOTHER=also_keep"), renviron_path)

  withr::with_envvar(c(HOME = temp_home), {
    mobdb:::set_renviron_key("my_token")

    lines <- readLines(renviron_path)
    expect_true(any(grepl("^OTHER_VAR=keep_me$", lines)))
    expect_true(any(grepl("^ANOTHER=also_keep$", lines)))
    expect_true(any(grepl("^MOBDB_REFRESH_TOKEN=my_token$", lines)))
  })
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
