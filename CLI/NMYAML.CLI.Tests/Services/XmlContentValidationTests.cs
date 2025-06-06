using NMYAML.CLI.Models;
using NMYAML.CLI.Services;
using System.IO;
using System.Threading.Tasks;
using Xunit;

namespace NMYAML.CLI.Tests.Services;

public class XmlContentValidationTests
{
    [Fact]
    public async Task ValidateContentAsync_ValidXmlSyntax_ReturnsNoErrors()
    {
        // Arrange
        var validXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <root>
              <element attribute="value">content</element>
            </root>
            """;

        // Act
        var results = await XmlValidationService.Instance.ValidateContentAsync(validXml).ToListAsync();

        // Assert
        Assert.Empty(results); // No validation errors for valid XML
    }

    [Fact]
    public async Task ValidateContentAsync_InvalidXmlSyntax_ReturnsError()
    {
        // Arrange
        var invalidXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <root>
              <element attribute="value">content
            </root>
            """; // Missing closing tag

        // Act
        var results = await XmlValidationService.Instance.ValidateContentAsync(invalidXml).ToListAsync();

        // Assert
        Assert.NotEmpty(results);
        Assert.Contains(results, r => r.Type == "Syntax" && r.Severity == ValidationSeverity.Error);
    }

    [Fact]
    public async Task ValidateContentAsync_ValidXmlWithValidSchemaFile_ReturnsNoErrors()
    {
        // Arrange
        var validXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <root>
              <element attribute="value">content</element>
            </root>
            """;
        
        // Create a temporary XSD file
        var tempDir = Path.Combine(Path.GetTempPath(), $"XmlContentValidationTests_{Guid.NewGuid()}");
        Directory.CreateDirectory(tempDir);
        var xsdPath = Path.Combine(tempDir, "schema.xsd");
        
        try
        {
            var xsd = """
                <?xml version="1.0" encoding="utf-8"?>
                <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
                  <xs:element name="root">
                    <xs:complexType>
                      <xs:sequence>
                        <xs:element name="element">
                          <xs:complexType>
                            <xs:simpleContent>
                              <xs:extension base="xs:string">
                                <xs:attribute name="attribute" type="xs:string" use="required" />
                              </xs:extension>
                            </xs:simpleContent>
                          </xs:complexType>
                        </xs:element>
                      </xs:sequence>
                    </xs:complexType>
                  </xs:element>
                </xs:schema>
                """;
            File.WriteAllText(xsdPath, xsd);

            // Act
            var results = await XmlValidationService.Instance.ValidateContentAsync(validXml, xsdPath).ToListAsync();

            // Assert
            Assert.Empty(results); // No validation errors for valid XML against valid schema
        }
        finally
        {
            // Clean up
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    [Fact]
    public async Task ValidateContentAsync_NonConformingXmlAgainstSchema_ReturnsValidationError()
    {
        // Arrange
        var nonConformingXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <root>
              <wrongElement>This element doesn't match the schema</wrongElement>
            </root>
            """;

        // Create a temporary XSD file
        var tempDir = Path.Combine(Path.GetTempPath(), $"XmlContentValidationTests_{Guid.NewGuid()}");
        Directory.CreateDirectory(tempDir);
        var xsdPath = Path.Combine(tempDir, "schema.xsd");
        
        try
        {
            var xsd = """
                <?xml version="1.0" encoding="utf-8"?>
                <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
                  <xs:element name="root">
                    <xs:complexType>
                      <xs:sequence>
                        <xs:element name="element">
                          <xs:complexType>
                            <xs:simpleContent>
                              <xs:extension base="xs:string">
                                <xs:attribute name="attribute" type="xs:string" use="required" />
                              </xs:extension>
                            </xs:simpleContent>
                          </xs:complexType>
                        </xs:element>
                      </xs:sequence>
                    </xs:complexType>
                  </xs:element>
                </xs:schema>
                """;
            File.WriteAllText(xsdPath, xsd);

            // Act
            var results = await XmlValidationService.Instance.ValidateContentAsync(nonConformingXml, xsdPath).ToListAsync();

            // Assert
            Assert.NotEmpty(results);
            Assert.Contains(results, r => r.Type == "XSD" && r.Severity == ValidationSeverity.Error);
        }
        finally
        {
            // Clean up
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }
}