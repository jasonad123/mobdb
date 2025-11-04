#' Get Mobility Database API metadata
#'
#' @description
#' Retrieve information about the API itself, including version, status,
#' and available data types.
#'
#' @return A list containing API metadata.
#'
#' @examples
#' \dontrun{
#' # Check API metadata
#' meta <- mobdb_metadata()
#' print(meta$version)
#'
#' }
#' @export
mobdb_metadata <- function() {
  req <- mobdb_request("metadata")
  
  resp <- httr2::req_perform(req)
  
  httr2::resp_body_json(resp)
}
