@echo off
rem convert-schema.bat
rem Simple wrapper script for schema conversion with default parameters

echo Converting namespaced schema to non-namespaced version...
powershell -ExecutionPolicy Bypass -File "%~dp0Convert-NamespacedSchema.ps1" -GenerateReport

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Schema conversion completed successfully.
    echo.
    echo To test the converted schema, run:
    echo powershell -ExecutionPolicy Bypass -File "%~dp0Manage-YamlSchema.ps1" -Action test
) else (
    echo.
    echo Schema conversion failed with error level %ERRORLEVEL%.
)

echo.
pause
