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

# Read file line by line safely using a separate file descriptor (3)
# This prevents tools inside the loop from stealing the stdin stream
while IFS= read -r line <&3 || [ -n "$line" ]; do
    
    # Trim Windows carriage returns (\r) and leading/trailing whitespace purely in Bash
    line=$(echo "$line" | tr -d '\r')
    line="${line#"${line%%[![:space:]]*}"}" # Trim leading
    line="${line%"${line##*[![:space:]]}"}" # Trim trailing
    
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

done 3< "$DELTA_FILE" # Attached to file descriptor 3

echo "--------------------------------------------------"
# Final validation result
if [ $MISSING_FILES -gt 0 ]; then
    echo "❌ Validation Failed! $MISSING_FILES file(s) are missing."
    exit 1
else
    echo "✅ Validation Successful! All files match their rules."
    exit 0
fi
