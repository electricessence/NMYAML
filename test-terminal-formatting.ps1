# test-terminal-formatting.ps1
# Script to test the enhanced terminal formatting in the TerminalOutput module

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsDir = Join-Path $scriptDir "scripts"

# Define paths for the XML-YAML conversion demo
$sampleXml = Join-Path $scriptDir "samples\sample.yaml.xml"
$noNamespaceXml = Join-Path $scriptDir "samples\sample-no-namespace.yaml.xml"
$outputYaml = Join-Path $scriptDir "output-terminal-test.yaml"
$xsltFile = Join-Path $scriptDir "xslt\xml-to-yaml-universal.xslt"
$schemaFile = Join-Path $scriptDir "schemas\yaml-schema.xsd"
$noNamespaceSchemaFile = Join-Path $scriptDir "schemas\yaml-schema-no-namespace.xsd"

# Import the TerminalOutput module directly to show its capabilities
$terminalModulePath = Join-Path $scriptDir "scripts\modules\TerminalOutput.psm1"
Import-Module $terminalModulePath -Force

# Display a welcome banner
Write-Banner -Text "YAML-XML Terminal Output Demo" -ForegroundColor Cyan -Width 60

# Display info about the test
Write-SectionHeader -Text "Test Configuration" -ForegroundColor Yellow
Write-InfoMessage "Testing enhanced terminal output formatting features"
Write-InfoMessage "Sample XML: $sampleXml"
Write-InfoMessage "Sample XML (No Namespace): $noNamespaceXml"
Write-InfoMessage "Output YAML: $outputYaml"
Write-InfoMessage "XSLT: $xsltFile"
Write-InfoMessage "Schema: $schemaFile"

# Show a progress indicator for "preparing environment"
Write-SectionHeader -Text "Preparing Environment" -ForegroundColor Magenta
for ($i = 0; $i -le 100; $i += 10) {
    Write-ProgressBar -PercentComplete $i
    Start-Sleep -Milliseconds 100
}
Write-SuccessMessage "Environment ready"

# Run the Schema Manager with "test" action
Write-SectionHeader -Text "Running Schema Validation Test" -ForegroundColor Green
$cmd = Join-Path $scriptsDir "Manage-YamlSchema.ps1"
$params = @{
    "Action" = "test"
    "NamespacedSchemaPath" = $schemaFile
    "NonNamespacedSchemaPath" = $noNamespaceSchemaFile
    "NamespacedXmlPath" = $sampleXml
    "NonNamespacedXmlPath" = $noNamespaceXml
}
& $cmd @params

# Run the Conversion script
Write-SectionHeader -Text "Running XML to YAML Conversion" -ForegroundColor Green
$cmd = Join-Path $scriptsDir "Convert-YamlXml.ps1"
$params = @{
    "Mode" = "xml-to-yaml"
    "XmlFile" = $sampleXml
    "XsltFile" = $xsltFile
    "OutputFile" = $outputYaml
    "ValidateInput" = $true
    "XsdFile" = $schemaFile
    "ShowOutput" = $true
}
& $cmd @params

# Show a sample table with results
Write-SectionHeader -Text "Test Results Summary" -ForegroundColor Yellow
$testResults = @(
    [PSCustomObject]@{
        TestName = "Schema Validation" 
        Status = "Pass"
        ExecutionTime = "0.34s"
        Description = "XML validates against schema"
    },
    [PSCustomObject]@{
        TestName = "Namespace Support"
        Status = "Pass" 
        ExecutionTime = "0.12s"
        Description = "Both namespaced and non-namespaced XML supported"
    },
    [PSCustomObject]@{
        TestName = "YAML Output Format" 
        Status = "Pass"
        ExecutionTime = "0.76s"
        Description = "YAML syntax verified"
    },
    [PSCustomObject]@{
        TestName = "UTF-8 Handling"
        Status = "Pass" 
        ExecutionTime = "0.21s"
        Description = "UTF-8 encoding properly maintained"
    }
)

Write-ConsoleTable -Data $testResults -Properties TestName, Status, ExecutionTime, Description -Title "Validation Results"

# Show a tree view of the workspace structure
Write-SectionHeader -Text "Project Structure" -ForegroundColor Yellow
$rootObject = [PSCustomObject]@{
    Name = "NMYAML"
    Children = @(
        [PSCustomObject]@{
            Name = "scripts"
            Children = @(
                [PSCustomObject]@{
                    Name = "modules"
                    Children = @(
                        [PSCustomObject]@{ Name = "XmlYamlUtils.psm1"; Children = @() },
                        [PSCustomObject]@{ Name = "XmlYamlSchema.psm1"; Children = @() },
                        [PSCustomObject]@{ Name = "TerminalOutput.psm1"; Children = @() }
                    )
                },
                [PSCustomObject]@{ Name = "Convert-YamlXml.ps1"; Children = @() },
                [PSCustomObject]@{ Name = "Manage-YamlSchema.ps1"; Children = @() }
            )
        },
        [PSCustomObject]@{
            Name = "schemas"
            Children = @(
                [PSCustomObject]@{ Name = "yaml-schema.xsd"; Children = @() },
                [PSCustomObject]@{ Name = "yaml-schema-no-namespace.xsd"; Children = @() }
            )
        },
        [PSCustomObject]@{
            Name = "xslt"
            Children = @(
                [PSCustomObject]@{ Name = "xml-to-yaml-universal.xslt"; Children = @() },
                [PSCustomObject]@{ Name = "xml-to-yaml-simple.xslt"; Children = @() }
            )
        },
        [PSCustomObject]@{
            Name = "samples"
            Children = @(
                [PSCustomObject]@{ Name = "sample.yaml.xml"; Children = @() },
                [PSCustomObject]@{ Name = "sample-no-namespace.yaml.xml"; Children = @() }
            )
        }
    )
}

Write-TreeView -Node $rootObject -ChildrenProperty "Children" -DisplayProperty "Name"

# Display syntax highlighting examples
Write-SectionHeader -Text "Syntax Highlighting Examples" -ForegroundColor Magenta

# XML example
$xmlSample = @"
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:key value="person" />
    <yaml:mapping>
      <yaml:key value="name" />
      <yaml:scalar>John Smith</yaml:scalar>
      <yaml:key value="age" />
      <yaml:scalar>35</yaml:scalar>
      <yaml:key value="address" />
      <yaml:mapping>
        <yaml:key value="city" />
        <yaml:scalar>New York</yaml:scalar>
        <yaml:key value="country" />
        <yaml:scalar>USA</yaml:scalar>
      </yaml:mapping>
    </yaml:mapping>
  </yaml:mapping>
</yaml:document>
"@

# YAML example
$yamlSample = @"
person:
  name: John Smith
  age: 35
  address:
    city: New York
    country: USA
"@

# PowerShell example
$powershellSample = @"
function Convert-XmlToYaml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlFile,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )
    
    try {
        # Process the file
        $content = Get-Content $XmlFile -Raw
        # Do the conversion
        $result = $true
        return $result
    } catch {
        Write-Error "Error processing XML: $($_.Exception.Message)"
        return $false
    }
}
"@

Write-SectionHeader -Text "XML Syntax" -ForegroundColor Green -LeadingNewLine:$false
Write-SyntaxHighlight -Text $xmlSample -Language xml

Write-SectionHeader -Text "YAML Syntax" -ForegroundColor Green
Write-SyntaxHighlight -Text $yamlSample -Language yaml

Write-SectionHeader -Text "PowerShell Syntax" -ForegroundColor Green
Write-SyntaxHighlight -Text $powershellSample -Language powershell

# Show completion message
Write-Banner -Text "Demo Completed" -ForegroundColor Green -Width 60
