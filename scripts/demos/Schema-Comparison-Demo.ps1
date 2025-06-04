# Schema-Comparison-Demo.ps1
# A simple demonstration that shows the benefits of namespaced vs non-namespaced schemas

# Define text styling for consistent output
function Write-Title {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Yellow
    Write-Host ("=" * $Text.Length) -ForegroundColor Yellow
}

function Write-SubTitle {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Magenta
    Write-Host ("-" * $Text.Length) -ForegroundColor Magenta
}

# Banner
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "          XML Schema Namespace Comparison Demo" -ForegroundColor Cyan  
Write-Host "=========================================================" -ForegroundColor Cyan

# Define example XML files
$namespaced_xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>server</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:scalar>example.com</yaml:scalar>
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
"@

$non_namespaced_xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<document>
  <mapping>
    <entry>
      <key>
        <scalar>server</scalar>
      </key>
      <value>
        <scalar>example.com</scalar>
      </value>
    </entry>
  </mapping>
</document>
"@

# Show the XML examples
Write-Title "1. XML Document Comparison"
Write-SubTitle "Namespaced XML"
Write-Host $namespaced_xml

Write-SubTitle "Non-namespaced XML"
Write-Host $non_namespaced_xml

# Explain schema conversion
Write-Title "2. Schema Conversion Process"
Write-Host "The schema conversion process involves these key steps:"
Write-Host "  1. Remove the 'targetNamespace' attribute from the root schema element"
Write-Host "  2. Remove namespace declarations (xmlns:yaml)"
Write-Host "  3. Remove 'yaml:' prefix from all element references"
Write-Host "  4. Ensure consistent structure between both schemas"
Write-Host "`nThis conversion allows the same XML data to be represented in both formats"
Write-Host "while maintaining validation capabilities."

# XPath comparison
Write-Title "3. Real-world Benefit: XPath Query Simplicity"

Write-SubTitle "XPath with Namespaces (Complex)"
Write-Host 'To query the server value in namespaced XML with XPath:'
Write-Host '$nsManager = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)' -ForegroundColor Gray
Write-Host '$nsManager.AddNamespace("y", "http://yaml.org/xml/1.2")' -ForegroundColor Gray
Write-Host '$serverNode = $doc.SelectSingleNode("//y:mapping/y:entry/y:key[y:scalar=''server'']/following-sibling::y:value/y:scalar", $nsManager)' -ForegroundColor Gray

Write-SubTitle "XPath without Namespaces (Simple)"
Write-Host 'To query the server value in non-namespaced XML with XPath:'
Write-Host '$serverNode = $doc.SelectSingleNode("//mapping/entry/key[scalar=''server'']/following-sibling::value/scalar")' -ForegroundColor Gray

# Tools compatibility
Write-Title "4. Benefits of Non-namespaced Schema"
Write-Host "1. ✅ Easier integration with tools that don't handle namespaces well"
Write-Host "2. ✅ Simpler XPath queries without namespace management"
Write-Host "3. ✅ Reduced XML document size without namespace declarations"
Write-Host "4. ✅ Identical structure and semantics between versions"
Write-Host "5. ✅ Improved readability for developers and systems"
Write-Host "6. ✅ Still validates against properly converted schemas"

# Demonstration of validation
Write-Title "5. Schema Validation"
Write-Host "Both schemas can validate their respective XML formats:"
Write-Host "  • Namespaced schema → Validates namespaced XML"
Write-Host "  • Non-namespaced schema → Validates non-namespaced XML"
Write-Host "`nThe conversion script in this project ensures these validations remain intact."

# Summary
Write-Title "6. Summary"
Write-Host "The non-namespaced schema conversion provides a more accessible"
Write-Host "alternative to the standard namespaced YAML XML representation."
Write-Host "This is particularly valuable when working with systems that have"
Write-Host "limited namespace support or when simplifying document processing."
Write-Host "`nBoth formats maintain the same data structure and semantics,"
Write-Host "allowing for flexible implementation choices based on system requirements."

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "                  Demo Completed" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
