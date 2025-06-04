@echo off
REM Batch script to transform XML to YAML using PowerShell and XSLT

set XML_FILE=..\samples\sample.yaml.xml
set XSLT_FILE=..\xslt\xml-to-yaml.xslt
set OUTPUT_FILE=..\output\output.yaml

if "%1" neq "" set XML_FILE=%1
if "%2" neq "" set XSLT_FILE=%2
if "%3" neq "" set OUTPUT_FILE=%3

echo Transforming %XML_FILE% to %OUTPUT_FILE% using %XSLT_FILE%...

powershell -ExecutionPolicy Bypass -File "%~dp0transform.ps1" -XmlFile "%XML_FILE%" -XsltFile "%XSLT_FILE%" -OutputFile "%OUTPUT_FILE%"

if %ERRORLEVEL% equ 0 (
    echo.
    echo Transformation completed successfully!
    echo Output written to: %OUTPUT_FILE%
) else (
    echo.
    echo Transformation failed with error code %ERRORLEVEL%
)

pause
