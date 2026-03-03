# Internal mapping of GTFS tables to their date columns (YYYYMMDD format per spec)
.gtfs_date_columns <- list(
  calendar = c("start_date", "end_date"),
  calendar_dates = c("date"),
  feed_info = c("feed_start_date", "feed_end_date")
)

# Internal mapping of GTFS tables to their time columns (HH:MM:SS format, can exceed 24:00:00)
.gtfs_time_columns <- list(
  stop_times = c("arrival_time", "departure_time"),
  frequencies = c("start_time", "end_time")
)

# Internal: Validate date columns for NAs that may indicate conversion issues
# Called after tidytransit::read_gtfs() to detect silent data loss
validate_gtfs_dates <- function(gtfs) {
  for (table_name in names(.gtfs_date_columns)) {
    if (!table_name %in% names(gtfs)) next
    tbl <- gtfs[[table_name]]
    if (is.null(tbl) || nrow(tbl) == 0) next

    for (col_name in .gtfs_date_columns[[table_name]]) {
      if (!col_name %in% names(tbl)) next
      na_count <- sum(is.na(tbl[[col_name]]))
      if (na_count > 0) {
        total <- nrow(tbl)
        cli::cli_warn(c(
          "!" = "{na_count} of {total} value{?s} in {.field {col_name}} of {.val {table_name}} {?is/are} NA.",
          "i" = "This may indicate malformed dates in the source feed (e.g., dashes instead of YYYYMMDD).",
          "i" = "Use {.code export_path} with {.code raw = TRUE} to download the raw feed and inspect the original data."
        ))
      }
    }
  }
  invisible(gtfs)
}

# Internal: Convert hms/difftime values to GTFS-spec HH:MM:SS strings
# Vectorized. Preserves times >= 24:00:00 (e.g., 25:30:00 for trips past midnight).
.hms_to_gtfs_time <- function(x) {
  total_secs <- round(as.numeric(x, units = "secs"))
  result <- rep(NA_character_, length(total_secs))
  valid <- !is.na(total_secs)
  hours <- total_secs[valid] %/% 3600
  mins <- (total_secs[valid] %% 3600) %/% 60
  secs <- total_secs[valid] %% 60
  result[valid] <- sprintf("%02d:%02d:%02d", hours, mins, secs)
  result
}

# Internal: Convert Date columns back to YYYYMMDD strings
convert_dates_to_gtfs_format <- function(gtfs) {
  for (table_name in names(.gtfs_date_columns)) {
    if (!table_name %in% names(gtfs)) next
    tbl <- gtfs[[table_name]]
    if (is.null(tbl) || nrow(tbl) == 0) next

    for (col_name in .gtfs_date_columns[[table_name]]) {
      if (!col_name %in% names(tbl)) next
      col <- tbl[[col_name]]
      if (inherits(col, "Date")) {
        gtfs[[table_name]][[col_name]] <- format(col, "%Y%m%d")
      }
    }
  }
  gtfs
}

# Internal: Convert hms/difftime columns back to HH:MM:SS strings
convert_times_to_gtfs_format <- function(gtfs) {
  for (table_name in names(.gtfs_time_columns)) {
    if (!table_name %in% names(gtfs)) next
    tbl <- gtfs[[table_name]]
    if (is.null(tbl) || nrow(tbl) == 0) next

    for (col_name in .gtfs_time_columns[[table_name]]) {
      if (!col_name %in% names(tbl)) next
      col <- tbl[[col_name]]
      if (inherits(col, "hms") || inherits(col, "difftime")) {
        gtfs[[table_name]][[col_name]] <- .hms_to_gtfs_time(col)
      }
    }
  }
  gtfs
}

#' Convert tidygtfs object to GTFS-spec-compliant format
#'
#' @description
#' Converts a tidygtfs object (as returned by [tidytransit::read_gtfs()])
#' back to GTFS-spec-compliant string formats. This reverses tidytransit's
#' automatic type conversions:
#'
#' * **Date columns** (R `Date` objects) are converted back to YYYYMMDD strings
#'   (e.g., `as.Date("2024-01-15")` becomes `"20240115"`)
#' * **Time columns** (`hms`/`difftime` objects) are converted back to HH:MM:SS
#'   strings, preserving values >= 24:00:00 for trips past midnight
#'   (e.g., `hms::hms(hours = 25, minutes = 30)` becomes `"25:30:00"`)
#'
#' Columns that are already in the correct format (character or integer) are
#' left unchanged. Returns a modified copy; the original object is not modified.
#'
#' @param gtfs A gtfs/tidygtfs object, typically from [tidytransit::read_gtfs()]
#'   or [download_feed()].
#'
#' @return A modified copy of the gtfs object with date and time columns
#'   converted to GTFS-spec-compliant strings.
#'
#' @section Affected tables and columns:
#' **Date columns** (YYYYMMDD):
#' * `calendar`: `start_date`, `end_date`
#' * `calendar_dates`: `date`
#' * `feed_info`: `feed_start_date`, `feed_end_date`
#'
#' **Time columns** (HH:MM:SS):
#' * `stop_times`: `arrival_time`, `departure_time`
#' * `frequencies`: `start_time`, `end_time`
#'
#' @examplesIf mobdb_can_run_examples() && mobdb_has_tidytransit()
#' gtfs <- download_feed("mdb-247")
#'
#' # Dates are R Date objects from tidytransit
#' class(gtfs$calendar$start_date)
#' # [1] "Date"
#'
#' # Convert to GTFS-spec format
#' spec <- gtfs_to_spec_format(gtfs)
#' spec$calendar$start_date
#' # [1] "20240101"
#'
#' spec$stop_times$arrival_time[1]
#' # [1] "08:30:00"
#'
#' @export
gtfs_to_spec_format <- function(gtfs) {
  if (!is.list(gtfs)) {
    cli::cli_abort("{.arg gtfs} must be a list (gtfs/tidygtfs object).")
  }
  gtfs <- convert_dates_to_gtfs_format(gtfs)
  gtfs <- convert_times_to_gtfs_format(gtfs)
  gtfs
}
