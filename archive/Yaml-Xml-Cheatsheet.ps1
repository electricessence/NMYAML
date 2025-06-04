# Yaml-Xml-Cheatsheet.ps1
# A simple cheat sheet for working with YAML XML in both namespaced and non-namespaced formats

# Header
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "               YAML XML Format Cheat Sheet" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host

# Define both formats for a simple YAML structure:
$yamlText = @"
# Sample YAML
server:
  hostname: example.com
  port: 8080
  features:
    - ssl
    - http2
    - compression
"@

Write-Host "Original YAML:" -ForegroundColor Yellow
Write-Host $yamlText -ForegroundColor Gray
Write-Host

# XML formats
Write-Host "1. XML Representations" -ForegroundColor Yellow
Write-Host   "---------------------" -ForegroundColor Yellow

$namespacedXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>server</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:mapping>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>hostname</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:scalar>example.com</yaml:scalar>
            </yaml:value>
          </yaml:entry>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>port</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:scalar>8080</yaml:scalar>
            </yaml:value>
          </yaml:entry>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>features</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:sequence>
                <yaml:item>
                  <yaml:scalar>ssl</yaml:scalar>
                </yaml:item>
                <yaml:item>
                  <yaml:scalar>http2</yaml:scalar>
                </yaml:item>
                <yaml:item>
                  <yaml:scalar>compression</yaml:scalar>
                </yaml:item>
              </yaml:sequence>
            </yaml:value>
          </yaml:entry>
        </yaml:mapping>
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
"@

$nonNamespacedXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<document>
  <mapping>
    <entry>
      <key>
        <scalar>server</scalar>
      </key>
      <value>
        <mapping>
          <entry>
            <key>
              <scalar>hostname</scalar>
            </key>
            <value>
              <scalar>example.com</scalar>
            </value>
          </entry>
          <entry>
            <key>
              <scalar>port</scalar>
            </key>
            <value>
              <scalar>8080</scalar>
            </value>
          </entry>
          <entry>
            <key>
              <scalar>features</scalar>
            </key>
            <value>
              <sequence>
                <item>
                  <scalar>ssl</scalar>
                </item>
                <item>
                  <scalar>http2</scalar>
                </item>
                <item>
                  <scalar>compression</scalar>
                </item>
              </sequence>
            </value>
          </entry>
        </mapping>
      </value>
    </entry>
  </mapping>
</document>
"@

Write-Host "Namespaced XML:" -ForegroundColor Magenta
Write-Host $namespacedXml
Write-Host

Write-Host "Non-namespaced XML:" -ForegroundColor Magenta
Write-Host $nonNamespacedXml
Write-Host

# Validation examples
Write-Host "2. Schema Validation" -ForegroundColor Yellow
Write-Host   "------------------" -ForegroundColor Yellow

$validationCode = @"
# Validate namespaced XML with namespaced schema
\$settings = New-Object System.Xml.XmlReaderSettings
\$settings.ValidationType = [System.Xml.ValidationType]::Schema
\$settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints

# Add namespaced schema
\$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
\$schemaSet.Add("http://yaml.org/xml/1.2", "path\to\yaml-schema.xsd")
\$settings.Schemas = \$schemaSet

# Validate
\$reader = [System.Xml.XmlReader]::Create("path\to\namespaced.yaml.xml", \$settings)
try {
    while (\$reader.Read()) { }
    Write-Host "Validation successful!"
}
catch {
    Write-Host "Validation error: \$(\$_.Exception.Message)"
}
finally {
    \$reader.Close()
}

# Validate non-namespaced XML with non-namespaced schema
\$settings = New-Object System.Xml.XmlReaderSettings
\$settings.ValidationType = [System.Xml.ValidationType]::Schema
\$settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints

# Add non-namespaced schema (no namespace parameter)
\$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
\$schemaSet.Add(\$null, "path\to\yaml-schema-no-namespace.xsd")
\$settings.Schemas = \$schemaSet

# Validate
\$reader = [System.Xml.XmlReader]::Create("path\to\non-namespaced.yaml.xml", \$settings)
try {
    while (\$reader.Read()) { }
    Write-Host "Validation successful!"
}
catch {
    Write-Host "Validation error: \$(\$_.Exception.Message)"
}
finally {
    \$reader.Close()
}
"@

Write-Host $validationCode -ForegroundColor Gray
Write-Host

# XPath examples
Write-Host "3. XPath Query Examples" -ForegroundColor Yellow
Write-Host   "---------------------" -ForegroundColor Yellow

$xpathCode = @"
# Query namespaced XML
[xml]\$doc = Get-Content "path\to\namespaced.yaml.xml"

# Create namespace manager
\$nsManager = New-Object System.Xml.XmlNamespaceManager(\$doc.NameTable)
\$nsManager.AddNamespace("y", "http://yaml.org/xml/1.2")

# Find hostname
\$hostnameNode = \$doc.SelectSingleNode("//y:mapping/y:entry/y:key[y:scalar='hostname']/following-sibling::y:value/y:scalar", \$nsManager)
\$hostname = \$hostnameNode.InnerText  # example.com

# Find features
\$featuresNodes = \$doc.SelectNodes("//y:key[y:scalar='features']/following-sibling::y:value/y:sequence/y:item/y:scalar", \$nsManager)
\$features = \$featuresNodes | ForEach-Object { \$_.InnerText }  # ssl, http2, compression

# Query non-namespaced XML
[xml]\$doc = Get-Content "path\to\non-namespaced.yaml.xml"

# Find hostname (much simpler XPath)
\$hostnameNode = \$doc.SelectSingleNode("//mapping/entry/key[scalar='hostname']/following-sibling::value/scalar")
\$hostname = \$hostnameNode.InnerText  # example.com

# Find features (much simpler XPath)
\$featuresNodes = \$doc.SelectNodes("//key[scalar='features']/following-sibling::value/sequence/item/scalar")
\$features = \$featuresNodes | ForEach-Object { \$_.InnerText }  # ssl, http2, compression
"@

Write-Host $xpathCode -ForegroundColor Gray
Write-Host

# Programmatic XML creation
Write-Host "4. Creating YAML XML Programmatically" -ForegroundColor Yellow
Write-Host   "----------------------------------" -ForegroundColor Yellow

$createCode = @"
# Create namespaced XML
\$xmlDoc = New-Object System.Xml.XmlDocument
\$nsURI = "http://yaml.org/xml/1.2"

# Create XML declaration and root element
\$xmlDecl = \$xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", \$null)
\$xmlDoc.AppendChild(\$xmlDecl) | Out-Null

# Create root with namespace
\$rootElem = \$xmlDoc.CreateElement("yaml", "document", \$nsURI)
\$nsAttr = \$xmlDoc.CreateAttribute("xmlns", "yaml", "http://www.w3.org/2000/xmlns/")
\$nsAttr.Value = \$nsURI
\$rootElem.Attributes.Append(\$nsAttr) | Out-Null
\$xmlDoc.AppendChild(\$rootElem) | Out-Null

# Create a scalar element
\$scalarElem = \$xmlDoc.CreateElement("yaml", "scalar", \$nsURI)
\$scalarElem.InnerText = "Hello World"
\$rootElem.AppendChild(\$scalarElem) | Out-Null

# Save the document
\$xmlDoc.Save("path\to\output.yaml.xml")

# Create non-namespaced XML
\$xmlDoc = New-Object System.Xml.XmlDocument

# Create XML declaration and root element
\$xmlDecl = \$xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", \$null)
\$xmlDoc.AppendChild(\$xmlDecl) | Out-Null

# Create root (much simpler)
\$rootElem = \$xmlDoc.CreateElement("document")
\$xmlDoc.AppendChild(\$rootElem) | Out-Null

# Create a scalar element (much simpler)
\$scalarElem = \$xmlDoc.CreateElement("scalar")
\$scalarElem.InnerText = "Hello World"
\$rootElem.AppendChild(\$scalarElem) | Out-Null

# Save the document
\$xmlDoc.Save("path\to\output-simple.yaml.xml")
"@

Write-Host $createCode -ForegroundColor Gray
Write-Host

# Converting between formats
Write-Host "5. Converting Between Formats" -ForegroundColor Yellow
Write-Host   "--------------------------" -ForegroundColor Yellow

$convertCode = @"
# Convert namespaced XML to non-namespaced XML
function Convert-NamespacedToNonNamespaced {
    param([string]\$InputXmlPath, [string]\$OutputXmlPath)
    
    # Load the XML
    [xml]\$xmlDoc = Get-Content -Path \$InputXmlPath -Raw
    
    # Create a new document
    \$outputDoc = New-Object System.Xml.XmlDocument
    \$xmlDecl = \$outputDoc.CreateXmlDeclaration("1.0", "UTF-8", \$null)
    \$outputDoc.AppendChild(\$xmlDecl) | Out-Null
    
    # Helper function to process nodes
    function Process-Node {
        param(\$SourceNode, \$TargetParent)
        
        if (\$SourceNode.NodeType -eq [System.Xml.XmlNodeType]::Element) {
            # Create element without namespace
            \$newName = \$SourceNode.LocalName
            \$newNode = \$outputDoc.CreateElement(\$newName)
            \$TargetParent.AppendChild(\$newNode) | Out-Null
            
            # Copy attributes
            foreach (\$attr in \$SourceNode.Attributes) {
                if (\$attr.Name -ne "xmlns:yaml" -and -not \$attr.Name.StartsWith("yaml:")) {
                    \$newAttr = \$outputDoc.CreateAttribute(\$attr.Name)
                    \$newAttr.Value = \$attr.Value
                    \$newNode.Attributes.Append(\$newAttr) | Out-Null
                }
            }
            
            # Process child nodes
            foreach (\$childNode in \$SourceNode.ChildNodes) {
                Process-Node -SourceNode \$childNode -TargetParent \$newNode
            }
        } 
        elseif (\$SourceNode.NodeType -eq [System.Xml.XmlNodeType]::Text) {
            # Copy text node
            \$newTextNode = \$outputDoc.CreateTextNode(\$SourceNode.InnerText)
            \$TargetParent.AppendChild(\$newTextNode) | Out-Null
        }
    }
    
    # Start processing from root
    Process-Node -SourceNode \$xmlDoc.DocumentElement -TargetParent \$outputDoc
    
    # Save the output
    \$outputDoc.Save(\$OutputXmlPath)
    Write-Host "Conversion complete. Output saved to \$OutputXmlPath"
}

# Example usage
Convert-NamespacedToNonNamespaced -InputXmlPath "path\to\namespaced.yaml.xml" -OutputXmlPath "path\to\non-namespaced.yaml.xml"

# Use the project's Convert-NamespacedSchema.ps1 script for schema conversion
& ".\Convert-NamespacedSchema.ps1" -InputSchemaPath "..\schemas\yaml-schema.xsd" -OutputSchemaPath "..\schemas\yaml-schema-no-namespace.xsd" -GenerateReport
"@

Write-Host $convertCode -ForegroundColor Gray
Write-Host

# Summary
Write-Host "Summary" -ForegroundColor Yellow
Write-Host "-------" -ForegroundColor Yellow
Write-Host "Both namespaced and non-namespaced YAML XML formats represent the same data,"
Write-Host "but the non-namespaced version is often easier to work with, particularly"
Write-Host "in tools and environments with limited namespace support."
Write-Host
Write-Host "The conversion scripts in this project allow you to:"
Write-Host "1. Convert XML schemas between namespaced and non-namespaced formats"
Write-Host "2. Validate both XML formats against their appropriate schemas"
Write-Host "3. Process YAML data in the format most suitable for your needs"
Write-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                   Cheat Sheet End" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
