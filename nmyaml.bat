@echo off
REM Main entry point for YAML XML Schema conversion and validation tools

echo =====================================================
echo YAML XML Schema Conversion and Validation Tool Suite
echo =====================================================
echo.
echo Select an option:
echo 1. Convert Schema (namespaced to non-namespaced)
echo 2. Run Schema Validation
echo 3. Run Schema Comparison Demo 
echo 4. Transform XML to YAML
echo 5. Run Complete Demo Suite
echo 6. View YAML-XML Cheat Sheet
echo Q. Quit
echo.

set /p choice=Enter your choice (1-6, or Q to quit): 

if "%choice%"=="1" goto convert_schema
if "%choice%"=="2" goto validate_schema 
if "%choice%"=="3" goto comparison_demo
if "%choice%"=="4" goto transform_xml
if "%choice%"=="5" goto run_demo_suite
if "%choice%"=="6" goto yaml_cheatsheet
if /I "%choice%"=="Q" goto end

echo Invalid choice. Please try again.
goto end

:convert_schema
echo.
call scripts\convert-schema.bat
goto end

:validate_schema
echo.
echo Running Schema Validation...
powershell -ExecutionPolicy Bypass -File "scripts\validation\Validate-XmlWithSchema.ps1" -Verbose
goto end

:comparison_demo
echo.
echo Running Schema Comparison Demo...
powershell -ExecutionPolicy Bypass -File "scripts\demos\Schema-Comparison-Demo.ps1"
goto end

:transform_xml
echo.
echo Transforming samples\sample.yaml.xml to output\output.yaml using xslt\xml-to-yaml.xslt...
powershell -ExecutionPolicy Bypass -File "scripts\Convert-YamlXml.ps1" -XmlFile "samples\sample.yaml.xml" -XsltFile "xslt\xml-to-yaml.xslt" -OutputFile "output\output.yaml" -ShowOutput
goto end

:run_demo_suite
echo.
echo Running Complete Demo Suite...
powershell -ExecutionPolicy Bypass -File "scripts\demos\Complete-SchemaConversionExample.ps1"
goto end

:yaml_cheatsheet
echo.
echo Displaying YAML-XML Cheat Sheet...
powershell -ExecutionPolicy Bypass -File "scripts\Yaml-Xml-Cheatsheet.ps1"
goto end

:end
echo.
pause
