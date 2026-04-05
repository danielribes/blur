#!/usr/bin/env bash
# run_tests.sh — integration tests for blur

set -euo pipefail

BLUR="$(cd "$(dirname "$0")/.." && pwd)/blur"
SAMPLE="$(dirname "$0")/sample.csv"
TMP_DIR=$(mktemp -d /tmp/blur_tests_XXXXXX)

pass_count=0
fail_count=0

# ---------------------------------------------------------------------------
# assert: compare actual vs expected, report result
# ---------------------------------------------------------------------------
assert() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        echo "  PASS  $test_name"
        pass_count=$((pass_count + 1))
    else
        echo "  FAIL  $test_name"
        echo "        expected: $expected"
        echo "        actual:   $actual"
        fail_count=$((fail_count + 1))
    fi
}

# ---------------------------------------------------------------------------
# assert_not_empty: check that a value is non-empty
# ---------------------------------------------------------------------------
assert_not_empty() {
    local test_name="$1"
    local actual="$2"

    if [[ -n "$actual" ]]; then
        echo "  PASS  $test_name"
        pass_count=$((pass_count + 1))
    else
        echo "  FAIL  $test_name (got empty string)"
        fail_count=$((fail_count + 1))
    fi
}

# ---------------------------------------------------------------------------
# assert_matches: check that a value matches a regex pattern
# ---------------------------------------------------------------------------
assert_matches() {
    local test_name="$1"
    local pattern="$2"
    local actual="$3"

    if [[ "$actual" =~ $pattern ]]; then
        echo "  PASS  $test_name"
        pass_count=$((pass_count + 1))
    else
        echo "  FAIL  $test_name"
        echo "        pattern:  $pattern"
        echo "        actual:   $actual"
        fail_count=$((fail_count + 1))
    fi
}

cleanup_tmp() {
    rm -rf "$TMP_DIR"
}
trap cleanup_tmp EXIT

echo "blur test suite"
echo "==============="
echo ""

# ---------------------------------------------------------------------------
# Test: --help exits cleanly
# ---------------------------------------------------------------------------
echo "[ help ]"
exit_code=0
"$BLUR" --help >/dev/null 2>&1 || exit_code=$?
assert "help flag exits 0" "0" "$exit_code"
echo ""

# ---------------------------------------------------------------------------
# Test: missing file error
# ---------------------------------------------------------------------------
echo "[ input validation ]"
exit_code=0
"$BLUR" /nonexistent/file.csv 2>/dev/null || exit_code=$?
assert "nonexistent file exits 1" "1" "$exit_code"
echo ""

# ---------------------------------------------------------------------------
# Test: batch mode — uuid method
# ---------------------------------------------------------------------------
echo "[ uuid method ]"
output="$TMP_DIR/uuid_test.csv"
"$BLUR" -c "email:uuid" -o "$output" "$SAMPLE" >/dev/null

# Read second data row (skip header), email column (index 3)
email_val=$(awk -F',' 'NR==2 {print $3}' "$output")
assert_matches "uuid replaces email with 32-char hex" "^[0-9a-f]{32}$" "$email_val"
echo ""

# ---------------------------------------------------------------------------
# Test: batch mode — email method
# ---------------------------------------------------------------------------
echo "[ email method ]"
output="$TMP_DIR/email_test.csv"
"$BLUR" -c "email:email" -o "$output" "$SAMPLE" >/dev/null

email_val=$(awk -F',' 'NR==2 {print $3}' "$output")
assert_matches "email method produces <uuid>@anon.local" "^[0-9a-f]{32}@anon\.local$" "$email_val"
echo ""

# ---------------------------------------------------------------------------
# Test: batch mode — name method
# ---------------------------------------------------------------------------
echo "[ name method ]"
output="$TMP_DIR/name_test.csv"
"$BLUR" -c "full_name:name" -o "$output" "$SAMPLE" >/dev/null

name_val=$(awk -F',' 'NR==2 {print $2}' "$output")
assert_matches "name method produces ANON_N" "^ANON_[0-9]+$" "$name_val"

# All ANON values must be unique (sequential)
unique_count=$(awk -F',' 'NR>1 {print $2}' "$output" | sort -u | wc -l | tr -d ' ')
row_count=$(awk 'NR>1' "$output" | wc -l | tr -d ' ')
assert "name method produces unique values" "$row_count" "$unique_count"
echo ""

# ---------------------------------------------------------------------------
# Test: batch mode — phone method
# ---------------------------------------------------------------------------
echo "[ phone method ]"
output="$TMP_DIR/phone_test.csv"
"$BLUR" -c "phone:phone" -o "$output" "$SAMPLE" >/dev/null

# Original phone "+34 612 345 678" has length 15
original_len=15
phone_val=$(awk -F',' 'NR==2 {print $4}' "$output")
actual_len=${#phone_val}
assert "phone preserves original character length" "$original_len" "$actual_len"
echo ""

# ---------------------------------------------------------------------------
# Test: batch mode — multiple columns at once
# ---------------------------------------------------------------------------
echo "[ multiple columns ]"
output="$TMP_DIR/multi_test.csv"
"$BLUR" -c "full_name:name,email:email,phone:phone" -o "$output" "$SAMPLE" >/dev/null

# Verify original is NOT modified
original_first_email=$(awk -F',' 'NR==2 {print $3}' "$SAMPLE")
assert_not_empty "original file email is non-empty" "$original_first_email"
assert_matches "original file still has real email" "^joan" "$original_first_email"

# Verify output columns were changed
out_email=$(awk -F',' 'NR==2 {print $3}' "$output")
assert_matches "output email is anonymized" "@anon\.local$" "$out_email"
echo ""

# ---------------------------------------------------------------------------
# Test: row count is preserved
# ---------------------------------------------------------------------------
echo "[ row count ]"
output="$TMP_DIR/rowcount_test.csv"
"$BLUR" -c "email:email" -o "$output" "$SAMPLE" >/dev/null

# Subtract 1 for header row
original_rows=$(awk 'NR>1' "$SAMPLE" | wc -l | tr -d ' ')
output_rows=$(awk 'NR>1' "$output" | wc -l | tr -d ' ')
assert "output preserves row count" "$original_rows" "$output_rows"
echo ""

# ---------------------------------------------------------------------------
# Test: unknown method exits with error
# ---------------------------------------------------------------------------
echo "[ error handling ]"
exit_code=0
"$BLUR" -c "email:fakemethod" -o "$TMP_DIR/err_test.csv" "$SAMPLE" 2>/dev/null || exit_code=$?
assert "unknown method exits with error" "1" "$exit_code"

exit_code=0
"$BLUR" -c "nonexistent_column:email" -o "$TMP_DIR/err_test2.csv" "$SAMPLE" 2>/dev/null || exit_code=$?
assert "nonexistent column exits with error" "1" "$exit_code"
echo ""

# ---------------------------------------------------------------------------
# Test: semicolon-separated CSV is detected and processed correctly
# ---------------------------------------------------------------------------
echo "[ semicolon separator ]"
SAMPLE_SC="$(dirname "$0")/sample_semicolon.csv"
output="$TMP_DIR/semicolon_test.csv"
"$BLUR" -c "email:email,full_name:name" -o "$output" "$SAMPLE_SC" >/dev/null

# Output must also use semicolons
header_sep=$(head -1 "$output" | grep -c ';' || true)
assert_not_empty "semicolon output uses semicolons as separator" "$header_sep"

email_val=$(awk -F';' 'NR==2 {print $3}' "$output")
assert_matches "semicolon file: email anonymized" "@anon\.local$" "$email_val"

name_val=$(awk -F';' 'NR==2 {print $2}' "$output")
assert_matches "semicolon file: name anonymized" "^ANON_" "$name_val"

# Verify quoted field with comma inside was handled correctly (row 3)
name_row3=$(awk -F';' 'NR==4 {print $2}' "$output")
assert_matches "semicolon file: quoted field with comma anonymized" "^ANON_" "$name_row3"
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"
echo ""

if [[ "$fail_count" -gt 0 ]]; then
    exit 1
fi
