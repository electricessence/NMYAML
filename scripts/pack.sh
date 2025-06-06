#!/bin/bash
# NMYAML Pack Script
# Creates NuGet package for the Core library

set -e

echo "=== NMYAML Pack Script ==="
echo "Creating NuGet package for NMYAML.Core..."
echo

# Pack the Core library
echo "Packing NMYAML.Core..."
dotnet pack Core/NMYAML.Core/NMYAML.Core.csproj --configuration Release --no-restore

# Show package info
echo
echo "📦 Package created:"
ls -la Core/NMYAML.Core/bin/Release/*.nupkg

echo
echo "✅ Packaging completed successfully!"
