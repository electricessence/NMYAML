#!/bin/bash
# NMYAML CLI Test Script
# Tests the CLI tool functionality with sample files

set -e

echo "=== NMYAML CLI Test Script ==="
echo "Testing CLI tool functionality..."
echo

cd CLI/NMYAML.CLI

echo "Step 1: Showing CLI help..."
dotnet run -- --help

echo
echo "Step 2: Testing transformation with sample workflow..."
dotnet run -- transform \
    "../../samples/github-workflow.xml" \
    "test-workflow.yml" \
    --xslt "../../xslt/github-actions-transform.xslt"

echo
echo "Step 3: Validating transformed output..."
dotnet run -- validate "test-workflow.yml"

echo
echo "Generated test workflow preview:"
echo "==============================="
head -20 test-workflow.yml

echo
echo "✅ CLI test completed successfully!"
