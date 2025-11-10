# Cache Management for mobdb

#' Get mobdb cache directory path
#'
#' Returns the cache directory path, checking environment variables and
#' options before falling back to the default R user directory.
#'
#' Priority order:
#' 1. MOBDB_CACHE_PATH environment variable
#' 2. mobdb.cache_path R option
#' 3. tools::R_user_dir("mobdb", "cache") (default)
#'
#' @return Character string with cache directory path
#' @keywords internal
get_mobdb_cache_path <- function() {
  # Priority 1: Environment variable
  env_path <- Sys.getenv("MOBDB_CACHE_PATH", unset = "")
  if (nzchar(env_path)) {
    return(path.expand(env_path))
  }

  # Priority 2: R options
  opt_path <- getOption("mobdb.cache_path")
  if (!is.null(opt_path)) {
    return(path.expand(opt_path))
  }

  # Priority 3: Default R user directory (CRAN-compliant)
  tools::R_user_dir("mobdb", which = "cache")
}

#' Ensure cache directory exists
#'
#' Creates the cache directory if it doesn't exist.
#'
#' @return Character string with cache directory path (invisibly)
#' @keywords internal
ensure_cache_dir <- function() {
  cache_dir <- get_mobdb_cache_path()
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(cache_dir)
}
#' Generate cache key from parameters
#'
#' Creates a unique cache key by hashing the provided parameters.
#'
#' @param ... Parameters to include in cache key
#' @param prefix Character prefix for cache key (default: "mobdb")
#' @return Character string with cache key (filename)
#' @keywords internal
generate_cache_key <- function(..., prefix = "mobdb") {
  params <- list(...)

  # Remove NULL values
  params <- params[!sapply(params, is.null)]

  # Sort for consistency (same params = same key regardless of order)
  if (length(params) > 0 && !is.null(names(params))) {
    params <- params[order(names(params))]
  }

  # Generate hash
  param_hash <- digest::digest(params, algo = "md5")

  paste0(prefix, "_", param_hash, ".rds")
}
#' Read from cache
#'
#' @param cache_key Cache file name
#' @param max_age Maximum age in hours (NULL = no limit)
#' @return Cached data or NULL if not found/expired
#' @keywords internal
read_from_cache <- function(cache_key, max_age = NULL) {
  cache_dir <- get_mobdb_cache_path()
  cache_file <- file.path(cache_dir, cache_key)

  if (!file.exists(cache_file)) {
    return(NULL)
  }

  # Check age if max_age specified
  if (!is.null(max_age)) {
    file_info <- file.info(cache_file)
    age_hours <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "hours"))

    if (age_hours > max_age) {
      cli::cli_alert_info("Cache expired (age: {round(age_hours, 1)}h > max: {max_age}h)")
      return(NULL)
    }
  }

  cli::cli_alert_success("Using cached data")
  readRDS(cache_file)
}

#' Write to cache
#'
#' @param data Data to cache
#' @param cache_key Cache file name
#' @keywords internal
write_to_cache <- function(data, cache_key) {
  cache_dir <- ensure_cache_dir()
  cache_file <- file.path(cache_dir, cache_key)

  saveRDS(data, cache_file, compress = TRUE)
  invisible(cache_file)
}
#' Get default cache TTL by endpoint type
#'
#' @param endpoint_type Type of endpoint
#' @return TTL in hours
#' @keywords internal
get_cache_ttl <- function(endpoint_type = c("feeds", "search", "datasets", "historical")) {
  endpoint_type <- match.arg(endpoint_type)

  ttls <- list(
    feeds = 1,        # Feed status changes relatively often
    search = 0.5,       # Search results should be fresh
    datasets = 24,    # Historical datasets don't change
    historical = 24   # Historical data is immutable
  )

  ttls[[endpoint_type]]
}
# User-facing cache management functions ----

#' Set or show mobdb cache directory
#'
#' Configure the directory where mobdb caches API responses. By default,
#' mobdb uses \code{tools::R_user_dir("mobdb", "cache")}.
#'
#' @param path Optional. Directory path for cache. If NULL (default), shows
#'   current cache path without changing it.
#' @param install Logical. If TRUE, adds MOBDB_CACHE_PATH to .Renviron for
#'   persistence across R sessions. Default: FALSE
#' @param overwrite Logical. If TRUE, overwrites existing MOBDB_CACHE_PATH in
#'   .Renviron. Default: FALSE
#'
#' @return Character string with cache path (invisibly)
#' @export
#'
#' @examples
#' \dontrun{
#' # Show current cache path
#' mobdb_cache_path()
#'
#' # Set for current session only
#' mobdb_cache_path("~/my_mobdb_cache")
#'
#' # Set permanently in .Renviron
#' mobdb_cache_path("~/my_mobdb_cache", install = TRUE)
#' }
mobdb_cache_path <- function(path = NULL, install = FALSE, overwrite = FALSE) {

  # If no path provided, just show current path
  if (is.null(path)) {
    current_path <- get_mobdb_cache_path()
    cli::cli_alert_info("Current cache path: {current_path}")
    return(invisible(current_path))
  }

  # Expand and validate path
  path <- path.expand(path)

  # Create directory if it doesn't exist
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    cli::cli_alert_success("Created cache directory: {path}")
  }

  # Set for current session
  Sys.setenv('MOBDB_CACHE_PATH' = path)
  cli::cli_alert_success("Cache path set to: {path}")

  # Make permanent if requested
  if (install) {
    home <- Sys.getenv("HOME")
    renv <- file.path(home, ".Renviron")

    # Check if already set
    if (file.exists(renv)) {
      oldenv <- readLines(renv, warn = FALSE)

      if (!overwrite && any(grepl("MOBDB_CACHE_PATH", oldenv))) {
        cli::cli_abort(c(
          "MOBDB_CACHE_PATH already set in .Renviron",
          "i" = "Use {.code overwrite = TRUE} to replace"
        ))
      }

      # Remove old entry
      newenv <- oldenv[!grepl("MOBDB_CACHE_PATH", oldenv)]
      writeLines(newenv, renv)
    }

    # Append new setting
    write(paste0("MOBDB_CACHE_PATH='", path, "'"),
          renv,
          sep = "\n",
          append = TRUE)

    cli::cli_alert_success("Added MOBDB_CACHE_PATH to .Renviron")
    cli::cli_alert_info("Restart R for permanent effect")
  }

  invisible(path)
}

#' Show cache information
#'
#' Displays information about the mobdb cache including location,
#' number of files, and total size.
#'
#' @return List with cache information (invisibly):
#'   \item{path}{Cache directory path}
#'   \item{files}{Number of cached files}
#'   \item{size_mb}{Total size in megabytes}
#'   \item{exists}{Whether cache directory exists}
#'
#' @export
#'
#' @examples
#' # Show cache info
#' mobdb_cache_info()
mobdb_cache_info <- function() {
  cache_path <- get_mobdb_cache_path()

  # Get cache statistics
  if (dir.exists(cache_path)) {
    files <- list.files(cache_path, pattern = "\\.rds$", full.names = TRUE)
    n_files <- length(files)

    if (n_files > 0) {
      total_size <- sum(file.size(files), na.rm = TRUE)
      size_mb <- round(total_size / 1024^2, 2)
    } else {
      size_mb <- 0
    }
  } else {
    n_files <- 0
    size_mb <- 0
  }

  cli::cli_h2("mobdb Cache Information")
  cli::cli_alert_info("Path: {cache_path}")
  cli::cli_alert_info("Files: {n_files}")
  cli::cli_alert_info("Size: {size_mb} MB")
  cli::cli_alert_info("Exists: {dir.exists(cache_path)}")

  invisible(list(
    path = cache_path,
    files = n_files,
    size_mb = size_mb,
    exists = dir.exists(cache_path)
  ))
}

#' List cached files
#'
#' Returns a tibble with information about all cached files, including
#' file name, size, modification time, and age.
#'
#' @return Tibble with columns:
#'   \item{file}{File name}
#'   \item{size_mb}{File size in megabytes}
#'   \item{modified}{Last modification time}
#'   \item{age_hours}{Age in hours}
#'
#' @export
#'
#' @examples
#' # List all cached files
#' mobdb_cache_list()
mobdb_cache_list <- function() {
  cache_dir <- get_mobdb_cache_path()

  if (!dir.exists(cache_dir)) {
    cli::cli_alert_warning("Cache directory does not exist: {cache_dir}")
    return(tibble::tibble())
  }

  files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is empty")
    return(tibble::tibble())
  }

  file_info <- file.info(files)

  tibble::tibble(
    file = basename(files),
    size_mb = round(file_info$size / 1024^2, 2),
    modified = file_info$mtime,
    age_hours = round(as.numeric(difftime(Sys.time(), file_info$mtime, units = "hours")), 1)
  ) |>
    dplyr::arrange(dplyr::desc(.data$modified))
}

#' Clear mobdb cache
#'
#' Removes cached files from the cache directory. Can remove all files
#' or only those older than a specified number of days.
#'
#' @param older_than Optional. Remove only files older than this many days.
#'   If NULL (default), removes all cached files.
#'
#' @return NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Clear all cache
#' mobdb_cache_clear()
#'
#' # Clear only files older than 7 days
#' mobdb_cache_clear(older_than = 7)
#' }
mobdb_cache_clear <- function(older_than = NULL) {
  cache_dir <- get_mobdb_cache_path()

  if (!dir.exists(cache_dir)) {
    cli::cli_alert_info("No cache directory found")
    return(invisible())
  }

  files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is already empty")
    return(invisible())
  }

  # Filter by age if specified
  if (!is.null(older_than)) {
    file_info <- file.info(files)
    age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))
    files <- files[age_days > older_than]

    if (length(files) == 0) {
      cli::cli_alert_info("No files older than {older_than} day{?s}")
      return(invisible())
    }
  }

  file.remove(files)
  cli::cli_alert_success("Removed {length(files)} cached file{?s}")

  invisible()
}
