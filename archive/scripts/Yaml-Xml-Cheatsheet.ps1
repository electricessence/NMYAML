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

# Validation examples - Use syntax highlighting and comments instead of raw code
Write-Host "2. Schema Validation" -ForegroundColor Yellow
Write-Host   "------------------" -ForegroundColor Yellow

# We'll display this as formatted documentation with syntax highlighting
Write-Host "# Validate namespaced XML with namespaced schema" -ForegroundColor DarkGreen
Write-Host '$settings = New-Object System.Xml.XmlReaderSettings' -ForegroundColor Gray
Write-Host '$settings.ValidationType = [System.Xml.ValidationType]::Schema' -ForegroundColor Gray
Write-Host '$settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints' -ForegroundColor Gray
Write-Host
Write-Host '# Add namespaced schema' -ForegroundColor DarkGreen
Write-Host '$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet' -ForegroundColor Gray
Write-Host '$schemaSet.Add("http://yaml.org/xml/1.2", "path\to\yaml-schema.xsd")' -ForegroundColor Gray
Write-Host '$settings.Schemas = $schemaSet' -ForegroundColor Gray
Write-Host
Write-Host '# Validate' -ForegroundColor DarkGreen
Write-Host '$reader = [System.Xml.XmlReader]::Create("path\to\namespaced.yaml.xml", $settings)' -ForegroundColor Gray
Write-Host 'try {' -ForegroundColor Gray
Write-Host '    while ($reader.Read()) { }' -ForegroundColor Gray
Write-Host '    Write-Host "Validation successful!"' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host 'catch {' -ForegroundColor Gray
Write-Host '    Write-Host "Validation error: $($_.Exception.Message)"' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host 'finally {' -ForegroundColor Gray
Write-Host '    $reader.Close()' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host

Write-Host "# Validate non-namespaced XML with non-namespaced schema" -ForegroundColor DarkGreen
Write-Host '$settings = New-Object System.Xml.XmlReaderSettings' -ForegroundColor Gray
Write-Host '$settings.ValidationType = [System.Xml.ValidationType]::Schema' -ForegroundColor Gray
Write-Host '$settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints' -ForegroundColor Gray
Write-Host
Write-Host '# Add non-namespaced schema (no namespace parameter)' -ForegroundColor DarkGreen
Write-Host '$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet' -ForegroundColor Gray
Write-Host '$schemaSet.Add($null, "path\to\yaml-schema-no-namespace.xsd")' -ForegroundColor Gray
Write-Host '$settings.Schemas = $schemaSet' -ForegroundColor Gray
Write-Host
Write-Host '# Validate' -ForegroundColor DarkGreen
Write-Host '$reader = [System.Xml.XmlReader]::Create("path\to\non-namespaced.yaml.xml", $settings)' -ForegroundColor Gray
Write-Host 'try {' -ForegroundColor Gray
Write-Host '    while ($reader.Read()) { }' -ForegroundColor Gray
Write-Host '    Write-Host "Validation successful!"' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host 'catch {' -ForegroundColor Gray
Write-Host '    Write-Host "Validation error: $($_.Exception.Message)"' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host 'finally {' -ForegroundColor Gray
Write-Host '    $reader.Close()' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host

# XPath examples
Write-Host "3. XPath Query Examples" -ForegroundColor Yellow
Write-Host   "---------------------" -ForegroundColor Yellow

Write-Host "# Query namespaced XML" -ForegroundColor DarkGreen
Write-Host '[xml]$doc = Get-Content "path\to\namespaced.yaml.xml"' -ForegroundColor Gray
Write-Host
Write-Host '# Create namespace manager' -ForegroundColor DarkGreen
Write-Host '$nsManager = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)' -ForegroundColor Gray
Write-Host '$nsManager.AddNamespace("y", "http://yaml.org/xml/1.2")' -ForegroundColor Gray
Write-Host
Write-Host '# Find hostname' -ForegroundColor DarkGreen
Write-Host '$hostnameNode = $doc.SelectSingleNode("//y:mapping/y:entry/y:key[y:scalar=''hostname'']/following-sibling::y:value/y:scalar", $nsManager)' -ForegroundColor Gray
Write-Host '$hostname = $hostnameNode.InnerText  # example.com' -ForegroundColor Gray
Write-Host
Write-Host '# Find features' -ForegroundColor DarkGreen
Write-Host '$featuresNodes = $doc.SelectNodes("//y:key[y:scalar=''features'']/following-sibling::y:value/y:sequence/y:item/y:scalar", $nsManager)' -ForegroundColor Gray
Write-Host '$features = $featuresNodes | ForEach-Object { $_.InnerText }  # ssl, http2, compression' -ForegroundColor Gray
Write-Host

Write-Host "# Query non-namespaced XML" -ForegroundColor DarkGreen
Write-Host '[xml]$doc = Get-Content "path\to\non-namespaced.yaml.xml"' -ForegroundColor Gray
Write-Host
Write-Host '# Find hostname (much simpler XPath)' -ForegroundColor DarkGreen
Write-Host '$hostnameNode = $doc.SelectSingleNode("//mapping/entry/key[scalar=''hostname'']/following-sibling::value/scalar")' -ForegroundColor Gray
Write-Host '$hostname = $hostnameNode.InnerText  # example.com' -ForegroundColor Gray
Write-Host
Write-Host '# Find features (much simpler XPath)' -ForegroundColor DarkGreen
Write-Host '$featuresNodes = $doc.SelectNodes("//key[scalar=''features'']/following-sibling::value/sequence/item/scalar")' -ForegroundColor Gray
Write-Host '$features = $featuresNodes | ForEach-Object { $_.InnerText }  # ssl, http2, compression' -ForegroundColor Gray
Write-Host

# Programmatic XML creation
Write-Host "4. Creating YAML XML Programmatically" -ForegroundColor Yellow
Write-Host   "----------------------------------" -ForegroundColor Yellow

Write-Host "# Create namespaced XML" -ForegroundColor DarkGreen
Write-Host '$xmlDoc = New-Object System.Xml.XmlDocument' -ForegroundColor Gray
Write-Host '$nsURI = "http://yaml.org/xml/1.2"' -ForegroundColor Gray
Write-Host
Write-Host '# Create XML declaration and root element' -ForegroundColor DarkGreen
Write-Host '$xmlDecl = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)' -ForegroundColor Gray
Write-Host '$xmlDoc.AppendChild($xmlDecl) | Out-Null' -ForegroundColor Gray
Write-Host
Write-Host '# Create root with namespace' -ForegroundColor DarkGreen
Write-Host '$rootElem = $xmlDoc.CreateElement("yaml", "document", $nsURI)' -ForegroundColor Gray
Write-Host '$nsAttr = $xmlDoc.CreateAttribute("xmlns", "yaml", "http://www.w3.org/2000/xmlns/")' -ForegroundColor Gray
Write-Host '$nsAttr.Value = $nsURI' -ForegroundColor Gray
Write-Host '$rootElem.Attributes.Append($nsAttr) | Out-Null' -ForegroundColor Gray
Write-Host '$xmlDoc.AppendChild($rootElem) | Out-Null' -ForegroundColor Gray
Write-Host
Write-Host '# Create a scalar element' -ForegroundColor DarkGreen
Write-Host '$scalarElem = $xmlDoc.CreateElement("yaml", "scalar", $nsURI)' -ForegroundColor Gray
Write-Host '$scalarElem.InnerText = "Hello World"' -ForegroundColor Gray
Write-Host '$rootElem.AppendChild($scalarElem) | Out-Null' -ForegroundColor Gray
Write-Host
Write-Host '# Save the document' -ForegroundColor DarkGreen
Write-Host '$xmlDoc.Save("path\to\output.yaml.xml")' -ForegroundColor Gray
Write-Host

Write-Host "# Create non-namespaced XML" -ForegroundColor DarkGreen
Write-Host '$xmlDoc = New-Object System.Xml.XmlDocument' -ForegroundColor Gray
Write-Host
Write-Host '# Create XML declaration and root element' -ForegroundColor DarkGreen
Write-Host '$xmlDecl = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)' -ForegroundColor Gray
Write-Host '$xmlDoc.AppendChild($xmlDecl) | Out-Null' -ForegroundColor Gray
Write-Host
Write-Host '# Create root (much simpler)' -ForegroundColor DarkGreen
Write-Host '$rootElem = $xmlDoc.CreateElement("document")' -ForegroundColor Gray
Write-Host '$xmlDoc.AppendChild($rootElem) | Out-Null' -ForegroundColor Gray
Write-Host
Write-Host '# Create a scalar element (much simpler)' -ForegroundColor DarkGreen
Write-Host '$scalarElem = $xmlDoc.CreateElement("scalar")' -ForegroundColor Gray
Write-Host '$scalarElem.InnerText = "Hello World"' -ForegroundColor Gray
Write-Host '$rootElem.AppendChild($scalarElem) | Out-Null' -ForegroundColor Gray
Write-Host
Write-Host '# Save the document' -ForegroundColor DarkGreen
Write-Host '$xmlDoc.Save("path\to\output-simple.yaml.xml")' -ForegroundColor Gray
Write-Host

# Converting between formats
Write-Host "5. Converting Between Formats" -ForegroundColor Yellow
Write-Host   "--------------------------" -ForegroundColor Yellow

Write-Host "# Convert namespaced XML to non-namespaced XML" -ForegroundColor DarkGreen
Write-Host 'function Convert-NamespacedToNonNamespaced {' -ForegroundColor Gray
Write-Host '    param([string]$InputXmlPath, [string]$OutputXmlPath)' -ForegroundColor Gray
Write-Host '    ' -ForegroundColor Gray
Write-Host '    # Load the XML' -ForegroundColor Gray
Write-Host '    [xml]$xmlDoc = Get-Content -Path $InputXmlPath -Raw' -ForegroundColor Gray
Write-Host '    ' -ForegroundColor Gray
Write-Host '    # Create a new document' -ForegroundColor Gray
Write-Host '    $outputDoc = New-Object System.Xml.XmlDocument' -ForegroundColor Gray
Write-Host '    $xmlDecl = $outputDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)' -ForegroundColor Gray
Write-Host '    $outputDoc.AppendChild($xmlDecl) | Out-Null' -ForegroundColor Gray
Write-Host '    ' -ForegroundColor Gray
Write-Host '    # Helper function to process nodes' -ForegroundColor Gray
Write-Host '    function Process-Node {' -ForegroundColor Gray
Write-Host '        param($SourceNode, $TargetParent)' -ForegroundColor Gray
Write-Host '        ' -ForegroundColor Gray
Write-Host '        if ($SourceNode.NodeType -eq [System.Xml.XmlNodeType]::Element) {' -ForegroundColor Gray
Write-Host '            # Create element without namespace' -ForegroundColor Gray
Write-Host '            $newName = $SourceNode.LocalName' -ForegroundColor Gray
Write-Host '            $newNode = $outputDoc.CreateElement($newName)' -ForegroundColor Gray
Write-Host '            $TargetParent.AppendChild($newNode) | Out-Null' -ForegroundColor Gray
Write-Host '            ' -ForegroundColor Gray
Write-Host '            # Copy attributes' -ForegroundColor Gray
Write-Host '            foreach ($attr in $SourceNode.Attributes) {' -ForegroundColor Gray
Write-Host '                if ($attr.Name -ne "xmlns:yaml" -and -not $attr.Name.StartsWith("yaml:")) {' -ForegroundColor Gray
Write-Host '                    $newAttr = $outputDoc.CreateAttribute($attr.Name)' -ForegroundColor Gray
Write-Host '                    $newAttr.Value = $attr.Value' -ForegroundColor Gray
Write-Host '                    $newNode.Attributes.Append($newAttr) | Out-Null' -ForegroundColor Gray
Write-Host '                }' -ForegroundColor Gray
Write-Host '            }' -ForegroundColor Gray
Write-Host '            ' -ForegroundColor Gray
Write-Host '            # Process child nodes' -ForegroundColor Gray
Write-Host '            foreach ($childNode in $SourceNode.ChildNodes) {' -ForegroundColor Gray
Write-Host '                Process-Node -SourceNode $childNode -TargetParent $newNode' -ForegroundColor Gray
Write-Host '            }' -ForegroundColor Gray
Write-Host '        }' -ForegroundColor Gray
Write-Host '        elseif ($SourceNode.NodeType -eq [System.Xml.XmlNodeType]::Text) {' -ForegroundColor Gray
Write-Host '            # Copy text node' -ForegroundColor Gray
Write-Host '            $newTextNode = $outputDoc.CreateTextNode($SourceNode.InnerText)' -ForegroundColor Gray
Write-Host '            $TargetParent.AppendChild($newTextNode) | Out-Null' -ForegroundColor Gray
Write-Host '        }' -ForegroundColor Gray
Write-Host '    }' -ForegroundColor Gray
Write-Host '    ' -ForegroundColor Gray
Write-Host '    # Start processing from root' -ForegroundColor Gray
Write-Host '    Process-Node -SourceNode $xmlDoc.DocumentElement -TargetParent $outputDoc' -ForegroundColor Gray
Write-Host '    ' -ForegroundColor Gray
Write-Host '    # Save the output' -ForegroundColor Gray
Write-Host '    $outputDoc.Save($OutputXmlPath)' -ForegroundColor Gray
Write-Host '    Write-Host "Conversion complete. Output saved to $OutputXmlPath"' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host
Write-Host '# Example usage' -ForegroundColor DarkGreen
Write-Host 'Convert-NamespacedToNonNamespaced -InputXmlPath "path\to\namespaced.yaml.xml" -OutputXmlPath "path\to\non-namespaced.yaml.xml"' -ForegroundColor Gray
Write-Host
Write-Host '# Use the project''s Convert-NamespacedSchema.ps1 script for schema conversion' -ForegroundColor DarkGreen
Write-Host '& ".\Convert-NamespacedSchema.ps1" -InputSchemaPath "..\schemas\yaml-schema.xsd" -OutputSchemaPath "..\schemas\yaml-schema-no-namespace.xsd" -GenerateReport' -ForegroundColor Gray
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
