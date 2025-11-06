# Test Fixtures

This directory contains test files and HTTP fixtures for mocking API responses.

## httptest2 Fixtures

The subdirectories (e.g., `search_bart/`, `feeds_gtfs/`, etc.) contain HTTP response fixtures recorded by [httptest2](https://enpiar.com/r/httptest2/).

### Why Fixtures Are Gitignored

These fixtures are **not committed** to the repository because:

1. **Size**: Search results can be 700KB+ each (full feed metadata)
2. **Tokens**: Token fixtures contain temporary JWT access tokens
3. **Local Development**: Each developer records their own fixtures with their API key

### How to Record Fixtures

When you run tests with an API key set, httptest2 automatically records API responses:

```r
# Set your API key
mobdb::mobdb_set_key("your-refresh-token")

# Run tests - fixtures will be recorded automatically
devtools::test()
```

Fixtures are stored in subdirectories like:
- `search_bart/api.mobilitydatabase.org/v1/search-xxxxx.json`
- `feeds_gtfs/api.mobilitydatabase.org/v1/gtfs_feeds-xxxxx.json`
- etc.

### Running Tests Without Fixtures

If you don't have fixtures recorded:

**Option 1: Record them (recommended)**
```r
mobdb::mobdb_set_key("your-token")
devtools::test()  # Will record and pass
```

**Option 2: Skip HTTP tests**
Tests will automatically skip if:
- httptest2 is not installed
- API key is not configured
- Required fixtures don't exist

### CI/CD Considerations

For continuous integration:

1. **Option A**: Set up API key as GitHub secret and record fixtures in CI
2. **Option B**: Skip httptest2 tests in CI (acceptable - they test API integration, not core logic)
3. **Option C**: Commit small, sanitized fixtures (requires manual cleanup)

Current approach: **Option B** - Tests skip gracefully without fixtures.

### Fixture Sizes

Typical sizes when recorded:
- Feed listings: 12-48KB
- Single feed: 4-8KB
- Datasets: 4-8KB
- Search results: **700-800KB** (contains full feed metadata for all matches)
- Tokens: 4KB (but contains sensitive JWTs)

Total: ~3-4MB if all fixtures recorded

### Test Files

The `.R` files in this directory are actual test files:
- `test-api-feeds.R` - Feed discovery and filtering
- `test-datasets.R` - Historical datasets
- `test-search.R` - Full-text search
- `test-helpers.R` - Utility functions
- `test-integration.R` - Download/read integration
- `test-auth.R` - Authentication

These ARE committed to the repository.

### .gitignore

The `.gitignore` in this directory excludes all subdirectories (fixtures) but keeps test files:

```gitignore
# Ignore all fixture directories
*/
```

This means only `*.R` files and this README are tracked by git.
