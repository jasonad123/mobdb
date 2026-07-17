# Test setup file
# This runs before any tests

# Helper function to check if fixtures exist for a test
fixture_exists <- function(fixture_dir) {
  fixture_path <- file.path("tests/testthat", fixture_dir)
  if (!file.exists(fixture_path)) {
    fixture_path <- file.path(fixture_dir)  # Try relative path
  }

  if (!dir.exists(fixture_path)) {
    return(FALSE)
  }

  # Get all files in the fixture directory
  all_files <- list.files(fixture_path, recursive = TRUE)

  # Exclude token files - we need actual API response fixtures
  non_token_files <- all_files[!grepl("tokens-.*-POST", all_files)]

  length(non_token_files) > 0
}

# Configure httptest2 behavior
if (requireNamespace("httptest2", quietly = TRUE)) {
  # Configure httptest2 to redact authorization headers
  # This prevents issues with bearer token serialization
  httptest2::set_redactor(function(req) {
    req$headers <- req$headers[names(req$headers) != "Authorization"]
    req
  })
}
