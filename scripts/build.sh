#!/bin/bash
# NMYAML Build Script
# Builds the entire solution in Release configuration

set -e

echo "=== NMYAML Build Script ==="
echo "Building NMYAML solution in Release configuration..."
echo

# Restore dependencies
echo "Step 1: Restoring dependencies..."
dotnet restore

# Build solution
echo "Step 2: Building solution..."
dotnet build --configuration Release --no-restore

# Run tests
echo "Step 3: Running tests..."
dotnet test --configuration Release --no-build --verbosity normal

echo
echo "✅ Build completed successfully!"
echo "Ready for packaging and deployment."
