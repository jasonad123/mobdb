# Test setup file
# This runs before any tests

# Helper function to check if fixtures exist for a test
fixture_exists <- function(fixture_dir) {
  fixture_path <- file.path("tests/testthat", fixture_dir)
  if (!file.exists(fixture_path)) {
    fixture_path <- file.path(fixture_dir)  # Try relative path
  }
  dir.exists(fixture_path) && length(list.files(fixture_path, recursive = TRUE)) > 0
}

# Configure httptest2 behavior
if (requireNamespace("httptest2", quietly = TRUE)) {
  # During R CMD check, we don't want to record new fixtures
  # Set to error mode so missing fixtures cause skips instead of recording
  Sys.setenv("HTTPTEST_MOCK_MODE" = "read")
}
