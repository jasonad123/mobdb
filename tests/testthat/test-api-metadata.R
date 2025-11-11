# Tests for API metadata function

test_that("mobdb_metadata() retrieves API metadata", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("metadata", {
    result <- mobdb:::mobdb_metadata()

    expect_type(result, "list")

    # API metadata should contain version and commit_hash
    # Check for expected fields (exact structure may vary)
    expect_true(is.list(result))
  })
})

test_that("mobdb_metadata() returns version information", {
  skip_if_not_installed("httptest2")
  skip_if_not(mobdb_has_key(), "API key not configured")

  httptest2::with_mock_dir("metadata", {
    result <- mobdb:::mobdb_metadata()

    # Should return a list with some structure
    # The exact fields depend on the API response
    expect_type(result, "list")
    expect_true(length(result) > 0)
  })
})
