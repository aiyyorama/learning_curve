#!/bin/bash

# Dynamically locate the repository root folder where 'release' lives
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Define absolute paths based on the repo root
RELEASE_DIR="$REPO_ROOT/release/2026/jun"
DELTA_FILE="$RELEASE_DIR/delta.txt"

# Check if delta.txt exists
if [ ! -f "$DELTA_FILE" ]; then
    echo "❌ Error: Delta file not found at $DELTA_FILE"
    exit 1
fi

MISSING_FILES=0

echo "🔍 Starting validation for files listed in $DELTA_FILE..."
echo "--------------------------------------------------"

while IFS= read -r line || [ -n "$line" ]; do
    # Trim whitespace and remove carriage returns (\r)
    line=$(echo "$line" | tr -d '\r' | xargs)
    
    # Skip empty lines
    [ -z "$line" ] && continue

    # Extract just the raw filename
    filename=$(basename "$line")

    echo "Checking file: $filename"

    # Rule 1: If file starts with Rollback_, check ONLY in the rollback folder
    if [[ "$filename" == Rollback_* ]]; then
        TARGET_PATH="$RELEASE_DIR/rollback/$filename"
        if [ ! -f "$TARGET_PATH" ]; then
            echo "  -> ❌ Missing in Rollback folder ($TARGET_PATH)"
            MISSING_FILES=$((MISSING_FILES + 1))
        else
            echo "  ->  Found in Rollback folder."
        fi

    # Rule 2: If file starts with anything else, check ONLY in dml folder
    else
        TARGET_PATH="$RELEASE_DIR/dml/$filename"
        if [ ! -f "$TARGET_PATH" ]; then
            echo "  -> ❌ Missing in DML folder ($TARGET_PATH)"
            MISSING_FILES=$((MISSING_FILES + 1))
        else
            echo "  ->  Found in DML folder."
        fi
    fi

done < "$DELTA_FILE"

echo "--------------------------------------------------"
# Final validation result
if [ $MISSING_FILES -gt 0 ]; then
    echo "❌ Validation Failed! $MISSING_FILES file(s) are missing."
    exit 1
else
    echo "✅ Validation Successful! All files match their rules."
    exit 0
fi
