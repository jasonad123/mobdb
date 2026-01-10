#' Load the Mobility Database in browser
#'
#' @description
#' Opens the Mobility Database in your default web browser.
#' You'll need to log in or sign up on the website to get an
#' API key to use this package.
#'
#' @return Invisibly returns the URL that was opened.
#'
#'
#' @export
mobdb_browse <- function() {
  url <- "https://mobilitydatabase.org"
  cli::cli_inform("Opening Mobility Database in browser: {.url {url}}")
  utils::browseURL(url)

  invisible(url)
}

# Internal helper: Score feed quality for selection
# Used by download_best_feed() to rank feeds
score_feed_quality <- function(feed_row, prefer_official = TRUE, prefer_active = TRUE) {
  score <- 0

  # Status scoring (if prefer_active = TRUE)
  if (prefer_active && !is.na(feed_row$status)) {
    status_scores <- c(
      "active" = 100,
      "future" = 80,
      "development" = 60,
      "deprecated" = 40,
      "inactive" = 20
    )
    score <- score + status_scores[feed_row$status]
  }

  # Official designation scoring (if prefer_official = TRUE)
  if (prefer_official) {
    if (!is.na(feed_row$official)) {
      if (isTRUE(feed_row$official)) {
        score <- score + 50
      }
    } else {
      # NA values get intermediate score
      score <- score + 25
    }
  }

  # Service date coverage (if available from latest_dataset)
  if ("latest_dataset" %in% names(feed_row)) {
    if (!is.null(feed_row$latest_dataset) && is.data.frame(feed_row$latest_dataset)) {
      ld <- feed_row$latest_dataset
      if ("service_date_range_start" %in% names(ld) &&
          "service_date_range_end" %in% names(ld)) {
        today <- Sys.Date()
        start_date <- as.Date(ld$service_date_range_start)
        end_date <- as.Date(ld$service_date_range_end)

        if (!is.na(start_date) && !is.na(end_date)) {
          is_current <- start_date <= today && end_date >= today
          if (is_current) {
            score <- score + 30
          } else {
            # Check how far from today
            days_until <- as.numeric(start_date - today)
            days_since <- as.numeric(today - end_date)

            if (days_until > 0 && days_until <= 90) {
              # Future but soon (within 90 days)
              score <- score + 20
            } else if (days_since > 0 && days_since <= 30) {
              # Expired recently (within 30 days)
              score <- score + 15
            }
          }
        }
      }
    }
  }

  # Validation quality (if available)
  if ("latest_dataset" %in% names(feed_row)) {
    if (!is.null(feed_row$latest_dataset) && is.data.frame(feed_row$latest_dataset)) {
      ld <- feed_row$latest_dataset
      if ("validation_report" %in% names(ld) && is.data.frame(ld$validation_report)) {
        vr <- ld$validation_report
        if ("total_error" %in% names(vr) && !is.na(vr$total_error)) {
          # Deduct points for errors
          if (vr$total_error == 0) {
            score <- score + 20
          } else if (vr$total_error <= 5) {
            score <- score + 10
          } else if (vr$total_error > 20) {
            score <- score - 10
          }
        }
      }
    }
  }

  # Recency (based on created_at or updated_at if available)
  if ("created_at" %in% names(feed_row) && !is.na(feed_row$created_at)) {
    # More recent feeds get a small boost
    # This is just a tiebreaker
    created_date <- as.Date(feed_row$created_at)
    days_old <- as.numeric(Sys.Date() - created_date)
    if (days_old < 365) {
      score <- score + 5
    }
  }

  score
}

# Internal helper: Format feed summary for display
# Used by download_best_feed() for prompts and messages
format_feed_summary <- function(feed_row, include_validation = TRUE) {
  parts <- character()

  # Feed ID and provider
  if ("id" %in% names(feed_row) && !is.na(feed_row$id)) {
    parts <- c(parts, paste0("[", feed_row$id, "]"))
  }

  if ("provider" %in% names(feed_row) && !is.na(feed_row$provider)) {
    parts <- c(parts, feed_row$provider)
  }

  # Feed name (if different from provider)
  if ("feed_name" %in% names(feed_row) && !is.na(feed_row$feed_name)) {
    if (is.null(feed_row$provider) || feed_row$feed_name != feed_row$provider) {
      parts <- c(parts, paste0("(", feed_row$feed_name, ")"))
    }
  }

  summary <- paste(parts, collapse = " ")

  # Add status and official info on separate line
  details <- character()

  if ("status" %in% names(feed_row) && !is.na(feed_row$status)) {
    details <- c(details, paste0("Status: ", feed_row$status))
  }

  if ("official" %in% names(feed_row)) {
    if (!is.na(feed_row$official)) {
      official_text <- if (isTRUE(feed_row$official)) "TRUE" else "FALSE"
      details <- c(details, paste0("Official: ", official_text))
    }
  }

  # Add validation info if requested and available
  if (include_validation && "latest_dataset" %in% names(feed_row)) {
    if (!is.null(feed_row$latest_dataset) && is.data.frame(feed_row$latest_dataset)) {
      ld <- feed_row$latest_dataset
      if ("validation_report" %in% names(ld) && is.data.frame(ld$validation_report)) {
        vr <- ld$validation_report
        if ("total_error" %in% names(vr) && "total_warning" %in% names(vr)) {
          if (!is.na(vr$total_error) && !is.na(vr$total_warning)) {
            details <- c(
              details,
              paste0("Errors: ", vr$total_error),
              paste0("Warnings: ", vr$total_warning)
            )
          }
        }
      }

      # Add service date range if available
      if ("service_date_range_start" %in% names(ld) && "service_date_range_end" %in% names(ld)) {
        if (!is.na(ld$service_date_range_start) && !is.na(ld$service_date_range_end)) {
          details <- c(
            details,
            paste0("Service: ", ld$service_date_range_start, " to ", ld$service_date_range_end)
          )
        }
      }
    }
  }

  if (length(details) > 0) {
    summary <- paste0(summary, "\n     ", paste(details, collapse = " | "))
  }

  summary
}
