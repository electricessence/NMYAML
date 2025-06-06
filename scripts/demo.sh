#!/bin/bash
# NMYAML Demo Script
# Demonstrates the dogfooding capabilities by transforming the XML workflow to YAML

set -e

echo "=== NMYAML Dogfooding Demo ==="
echo "Demonstrating XML to YAML transformation..."
echo

# Ensure CLI is built
echo "Step 1: Building CLI tool..."
dotnet build CLI/NMYAML.CLI --configuration Release

# Create .github/workflows directory if it doesn't exist
mkdir -p .github/workflows

# Transform XML workflow to YAML using the correct XSLT
echo "Step 2: Transforming XML workflow to YAML..."
cd CLI/NMYAML.CLI
dotnet run --configuration Release -- transform \
    "../../workflows/build-and-publish.xml" \
    "../../.github/workflows/build-and-publish.yml" \
    --xslt "../../xslt/github-actions-transform.xslt"

echo
echo "Step 3: Validating generated workflow..."
dotnet run --configuration Release -- validate \
    "../../.github/workflows/build-and-publish.yml"

echo
echo "Generated YAML workflow:"
echo "========================"
cat "../../.github/workflows/build-and-publish.yml"

echo
echo "✅ Dogfooding demo completed successfully!"
echo "🚀 Generated workflow is ready for GitHub Actions!"
