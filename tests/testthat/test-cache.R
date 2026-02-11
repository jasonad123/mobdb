# Tests for cache management functionality

test_that("get_mobdb_cache_path() respects priority order", {
  # Save current state
  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  old_opt <- getOption("mobdb.cache_path")

  # Clean slate
  Sys.unsetenv("MOBDB_CACHE_PATH")
  options(mobdb.cache_path = NULL)

  # Test default (Priority 3)
  default_path <- get_mobdb_cache_path()
  expect_true(grepl("mobdb", default_path))

  # Test R option (Priority 2)
  options(mobdb.cache_path = "/tmp/test_cache_opt")
  expect_equal(get_mobdb_cache_path(), "/tmp/test_cache_opt")

  # Test env var (Priority 1 - highest)
  Sys.setenv(MOBDB_CACHE_PATH = "/tmp/test_cache_env")
  expect_equal(get_mobdb_cache_path(), "/tmp/test_cache_env")

  # Restore
  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
  options(mobdb.cache_path = old_opt)
})

test_that("get_mobdb_cache_path() expands tilde", {
  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)

  Sys.setenv(MOBDB_CACHE_PATH = "~/test_cache")
  path <- get_mobdb_cache_path()
  expect_false(grepl("^~", path))  # Should be expanded

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("ensure_cache_dir() creates directory", {
  temp_cache <- file.path(tempdir(), "mobdb_test_cache", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  expect_false(dir.exists(temp_cache))
  result <- ensure_cache_dir()
  expect_true(dir.exists(temp_cache))
  expect_equal(result, temp_cache)

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("generate_cache_key() creates consistent keys", {
  key1 <- generate_cache_key(a = 1, b = 2, prefix = "test")
  key2 <- generate_cache_key(a = 1, b = 2, prefix = "test")
  expect_equal(key1, key2)

  # Order shouldn't matter
  key3 <- generate_cache_key(b = 2, a = 1, prefix = "test")
  expect_equal(key1, key3)
})

test_that("generate_cache_key() removes NULL values", {
  key1 <- generate_cache_key(a = 1, b = NULL, c = 3, prefix = "test")
  key2 <- generate_cache_key(a = 1, c = 3, prefix = "test")
  expect_equal(key1, key2)
})

test_that("generate_cache_key() uses prefix", {
  key1 <- generate_cache_key(a = 1, prefix = "prefix1")
  key2 <- generate_cache_key(a = 1, prefix = "prefix2")
  expect_true(grepl("^prefix1_", key1))
  expect_true(grepl("^prefix2_", key2))
  expect_false(key1 == key2)
})

test_that("generate_cache_key() handles different parameter types", {
  key_chr <- generate_cache_key(x = "test", prefix = "test")
  key_num <- generate_cache_key(x = 123, prefix = "test")
  key_bool <- generate_cache_key(x = TRUE, prefix = "test")
  key_list <- generate_cache_key(x = list(a = 1, b = 2), prefix = "test")

  expect_true(grepl("\\.rds$", key_chr))
  expect_true(grepl("\\.rds$", key_num))
  expect_true(grepl("\\.rds$", key_bool))
  expect_true(grepl("\\.rds$", key_list))
})

test_that("write_to_cache() and read_from_cache() work together", {
  temp_cache <- file.path(tempdir(), "mobdb_test_write_read", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  test_data <- data.frame(a = 1:3, b = letters[1:3])
  cache_key <- "test_data.rds"

  # Write
  result <- write_to_cache(test_data, cache_key)
  expect_true(file.exists(result))

  # Read
  cached <- read_from_cache(cache_key)
  expect_equal(cached, test_data)

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("read_from_cache() returns NULL for missing files", {
  temp_cache <- file.path(tempdir(), "mobdb_test_missing", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  result <- read_from_cache("nonexistent.rds")
  expect_null(result)

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("read_from_cache() respects max_age", {
  temp_cache <- file.path(tempdir(), "mobdb_test_age", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  test_data <- data.frame(x = 1)
  cache_key <- "age_test.rds"

  write_to_cache(test_data, cache_key)

  # Should return data with max_age = 1 hour (fresh file)
  result <- read_from_cache(cache_key, max_age = 1)
  expect_equal(result, test_data)

  # Should return data with no max_age
  result <- read_from_cache(cache_key, max_age = NULL)
  expect_equal(result, test_data)

  # Simulate old file by changing mtime (this may not work on all systems)
  # For a robust test, we would need to actually wait, so we skip detailed age testing

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("get_cache_ttl() returns correct values", {
  expect_equal(get_cache_ttl("feeds"), 1)
  expect_equal(get_cache_ttl("search"), 0.5)
  expect_equal(get_cache_ttl("datasets"), 24)
  expect_equal(get_cache_ttl("historical"), 24)
})

test_that("get_cache_ttl() validates endpoint_type", {
  expect_error(
    get_cache_ttl("invalid"),
    "should be one of"
  )
})

test_that("mobdb_cache_path() shows current path", {
  expect_invisible(mobdb_cache_path())
  path <- mobdb_cache_path()
  expect_type(path, "character")
})

test_that("mobdb_cache_path() emits message when showing path", {
  expect_message(
    mobdb_cache_path(),
    "Current cache path"
  )
})

test_that("mobdb_cache_path() emits message when setting path", {
  temp_cache <- file.path(tempdir(), "mobdb_test_msg_set", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)

  expect_message(
    mobdb_cache_path(temp_cache),
    "Cache path set to"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_path(install = TRUE) writes .Renviron in non-interactive mode", {
  skip_if(interactive(), "Test requires non-interactive session")

  temp_cache <- file.path(tempdir(), "mobdb_test_install_cache", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  temp_home <- file.path(tempdir(), "mobdb_test_cache_home", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)

  withr::with_envvar(c(HOME = temp_home), {
    mobdb_cache_path(temp_cache, install = TRUE)

    renviron_path <- file.path(temp_home, ".Renviron")
    expect_true(file.exists(renviron_path))

    lines <- readLines(renviron_path)
    expect_true(any(grepl("MOBDB_CACHE_PATH=", lines)))
  })

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_path(install = TRUE) errors if already set without overwrite", {
  skip_if(interactive(), "Test requires non-interactive session")

  temp_cache <- file.path(tempdir(), "mobdb_test_no_overwrite", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  temp_home <- file.path(tempdir(), "mobdb_test_cache_noow", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  # Pre-populate .Renviron with existing entry
  renviron_path <- file.path(temp_home, ".Renviron")
  writeLines("MOBDB_CACHE_PATH='/old/path'", renviron_path)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)

  withr::with_envvar(c(HOME = temp_home), {
    expect_error(
      mobdb_cache_path(temp_cache, install = TRUE, overwrite = FALSE),
      "MOBDB_CACHE_PATH already set"
    )
  })

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_path(install = TRUE, overwrite = TRUE) replaces .Renviron entry", {
  skip_if(interactive(), "Test requires non-interactive session")

  temp_cache <- file.path(tempdir(), "mobdb_test_overwrite", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  temp_home <- file.path(tempdir(), "mobdb_test_cache_ow", basename(tempfile()))
  dir.create(temp_home, recursive = TRUE)
  on.exit(unlink(temp_home, recursive = TRUE), add = TRUE)

  # Pre-populate .Renviron with existing entry and other vars
  renviron_path <- file.path(temp_home, ".Renviron")
  writeLines(c("OTHER_VAR=keep", "MOBDB_CACHE_PATH='/old/path'"), renviron_path)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)

  withr::with_envvar(c(HOME = temp_home), {
    mobdb_cache_path(temp_cache, install = TRUE, overwrite = TRUE)

    lines <- readLines(renviron_path)
    cache_lines <- grep("MOBDB_CACHE_PATH", lines, value = TRUE)

    # Old entry replaced, only one entry remains
    expect_length(cache_lines, 1)
    expect_true(grepl(temp_cache, cache_lines, fixed = TRUE))

    # Other vars preserved
    expect_true(any(grepl("OTHER_VAR=keep", lines)))
  })

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_path() sets cache path", {
  temp_cache <- file.path(tempdir(), "mobdb_test_set", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)

  path <- mobdb_cache_path(temp_cache)
  expect_equal(path, temp_cache)
  expect_equal(Sys.getenv("MOBDB_CACHE_PATH"), temp_cache)
  expect_true(dir.exists(temp_cache))

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_info() returns cache information", {
  temp_cache <- file.path(tempdir(), "mobdb_test_info", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  info <- mobdb_cache_info()
  expect_type(info, "list")
  expect_true("path" %in% names(info))
  expect_true("files" %in% names(info))
  expect_true("size_mb" %in% names(info))
  expect_true("exists" %in% names(info))

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_list() returns tibble of cached files", {
  temp_cache <- file.path(tempdir(), "mobdb_test_list", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  # Empty cache
  result <- mobdb_cache_list()
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)

  # Add some files
  write_to_cache(data.frame(x = 1), "file1.rds")
  write_to_cache(data.frame(x = 2), "file2.rds")

  result <- mobdb_cache_list()
  expect_equal(nrow(result), 2)
  expect_true(all(c("file", "size_mb", "modified", "age_hours") %in% names(result)))

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() removes all files", {
  temp_cache <- file.path(tempdir(), "mobdb_test_clear", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  # Add files
  write_to_cache(data.frame(x = 1), "file1.rds")
  write_to_cache(data.frame(x = 2), "file2.rds")

  files <- list.files(temp_cache, pattern = "\\.rds$")
  expect_equal(length(files), 2)

  # Clear
  mobdb_cache_clear()

  files <- list.files(temp_cache, pattern = "\\.rds$")
  expect_equal(length(files), 0)

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() handles empty cache gracefully", {
  temp_cache <- file.path(tempdir(), "mobdb_test_clear_empty", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  expect_invisible(mobdb_cache_clear())

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() handles missing cache directory", {
  temp_cache <- file.path(tempdir(), "nonexistent_dir", basename(tempfile()))

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  expect_invisible(mobdb_cache_clear())

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("read_from_cache() emits message on cache hit", {
  temp_cache <- file.path(tempdir(), "mobdb_test_msg_hit", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  write_to_cache(data.frame(x = 1), "msg_test.rds")

  expect_message(
    read_from_cache("msg_test.rds"),
    "Using cached data"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("read_from_cache() emits message on cache expiry", {
  temp_cache <- file.path(tempdir(), "mobdb_test_msg_expire", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  write_to_cache(data.frame(x = 1), "expire_msg_test.rds")

  # Backdate the file to simulate expiry
  cache_file <- file.path(temp_cache, "expire_msg_test.rds")
  Sys.setFileTime(cache_file, Sys.time() - 7200)  # 2 hours ago

  expect_message(
    result <- read_from_cache("expire_msg_test.rds", max_age = 1),
    "Cache expired"
  )
  expect_null(result)

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_info() emits messages via message stream", {
  temp_cache <- file.path(tempdir(), "mobdb_test_info_msg", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  expect_message(
    mobdb_cache_info(),
    "Path:"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_list() warns when cache dir does not exist", {
  temp_cache <- file.path(tempdir(), "nonexistent_list_dir", basename(tempfile()))

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  expect_warning(
    result <- mobdb_cache_list(),
    "Cache directory does not exist"
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_list() emits message for empty cache", {
  temp_cache <- file.path(tempdir(), "mobdb_test_list_empty_msg", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  expect_message(
    mobdb_cache_list(),
    "Cache is empty"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() emits messages via message stream", {
  temp_cache <- file.path(tempdir(), "mobdb_test_clear_msg", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  write_to_cache(data.frame(x = 1), "clear_msg.rds")

  expect_message(
    mobdb_cache_clear(),
    "Removed 1 cached file"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() emits message for missing directory", {
  temp_cache <- file.path(tempdir(), "nonexistent_clear_dir", basename(tempfile()))

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)

  expect_message(
    mobdb_cache_clear(),
    "No cache directory found"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() emits message for empty cache", {
  temp_cache <- file.path(tempdir(), "mobdb_test_clear_empty_msg", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  expect_message(
    mobdb_cache_clear(),
    "Cache is already empty"
  )

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})

test_that("mobdb_cache_clear() with older_than parameter", {
  temp_cache <- file.path(tempdir(), "mobdb_test_clear_old", basename(tempfile()))
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv("MOBDB_CACHE_PATH", unset = NA)
  Sys.setenv(MOBDB_CACHE_PATH = temp_cache)
  ensure_cache_dir()

  # Add files
  write_to_cache(data.frame(x = 1), "file1.rds")

  # Clear files older than 1 day (should find nothing)
  mobdb_cache_clear(older_than = 1)

  files <- list.files(temp_cache, pattern = "\\.rds$")
  expect_equal(length(files), 1)  # File should still exist

  if (!is.na(old_env)) {
    Sys.setenv(MOBDB_CACHE_PATH = old_env)
  } else {
    Sys.unsetenv("MOBDB_CACHE_PATH")
  }
})
