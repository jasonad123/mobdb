#' Get Mobility Database API metadata
#'
#' @description
#' Retrieve information about the API itself, including version and commit hash.
#' This is primarily useful for debugging and reporting issues.
#'
#' @return A list containing API metadata including `version` and `commit_hash`.
#'
#' @keywords internal
#' @noRd
mobdb_metadata <- function() {
  req <- mobdb_request("metadata")

  resp <- httr2::req_perform(req)

  httr2::resp_body_json(resp)
}
