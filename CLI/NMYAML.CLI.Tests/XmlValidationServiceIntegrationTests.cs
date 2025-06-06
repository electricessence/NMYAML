using NMYAML.CLI.Models;
using NMYAML.CLI.Services;
using Open.Disposable;

namespace NMYAML.CLI.Tests;

public class XmlValidationServiceIntegrationTests : DisposableBase
{
	private readonly string _tempDir;

	public XmlValidationServiceIntegrationTests()
	{
		_tempDir = Path.Combine(Path.GetTempPath(), $"XmlValidationServiceIntegrationTests_{Guid.NewGuid()}");
		Directory.CreateDirectory(_tempDir);
	}

	[Fact]
	public async Task ValidateAsync_ValidXmlSyntax_ReturnsNoErrors()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath).ToListAsync();

		// Assert
		Assert.Empty(results); // No validation errors for valid XML
	}

	[Fact]
	public async Task ValidateAsync_InvalidXmlSyntax_ReturnsError()
	{
		// Arrange
		var xmlPath = CreateInvalidXmlFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath).ToListAsync();

		// Assert
		Assert.NotEmpty(results);
		Assert.Contains(results, r => r.Type == "Syntax" && r.Severity == ValidationSeverity.Error);
	}

	[Fact]
	public async Task ValidateAsync_ValidXmlWithValidSchema_ReturnsNoErrors()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();
		var xsdPath = CreateMatchingXsdFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, xsdPath).ToListAsync();

		// Assert
		Assert.Empty(results); // No validation errors for valid XML against valid schema
	}

	[Fact]
	public async Task ValidateAsync_ValidXmlWithInvalidSchema_ReturnsSchemaError()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();
		var xsdPath = CreateInvalidXsdFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, xsdPath).ToListAsync();

		// Assert
		Assert.NotEmpty(results);
		Assert.Contains(results, r => r.Type == "Schema" && r.Severity == ValidationSeverity.Error);
	}

	[Fact]
	public async Task ValidateAsync_NonConformingXmlAgainstSchema_ReturnsValidationError()
	{
		// Arrange
		var xmlPath = CreateNonConformingXmlFile();
		var xsdPath = CreateMatchingXsdFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, xsdPath).ToListAsync();

		// Assert
		Assert.NotEmpty(results);
		Assert.Contains(results, r => r.Type == "XSD" && r.Severity == ValidationSeverity.Error);
	}

	[Fact]
	public async Task ValidateAsync_ValidXmlWithNullSchema_ReturnsNoErrors()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();

		// Act - null XSD path should be allowed (optional schema validation)
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, null).ToListAsync();

		// Assert
		Assert.Empty(results); // No validation errors for valid XML with no schema
	}

	[Fact]
	public async Task ValidateAsync_NonExistentSchema_ReturnsFileNotFoundError()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();
		var nonExistentXsdPath = Path.Combine(_tempDir, "nonexistent.xsd");

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, nonExistentXsdPath).ToListAsync();

		// Assert
		Assert.NotEmpty(results);
		Assert.Contains(results, r => r.Type == "File" && r.Severity == ValidationSeverity.Error);
	}

	#region Helper Methods
	private string CreateValidXmlFile()
	{
		var xmlPath = Path.Combine(_tempDir, "valid.xml");
		var xml = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content</element>
			</root>
			""";
		File.WriteAllText(xmlPath, xml);
		return xmlPath;
	}

	private string CreateInvalidXmlFile()
	{
		var xmlPath = Path.Combine(_tempDir, "invalid.xml");
		var xml = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content
			</root>
			"""; // Missing closing tag
		File.WriteAllText(xmlPath, xml);
		return xmlPath;
	}

	private string CreateNonConformingXmlFile()
	{
		var xmlPath = Path.Combine(_tempDir, "nonconforming.xml");
		var xml = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element>content</element>
			</root>
			"""; // Missing required attribute
		File.WriteAllText(xmlPath, xml);
		return xmlPath;
	}

	private string CreateMatchingXsdFile()
	{
		var xsdPath = Path.Combine(_tempDir, "schema.xsd");
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
		return xsdPath;
	}

	private string CreateInvalidXsdFile()
	{
		var xsdPath = Path.Combine(_tempDir, "invalid.xsd");
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
			</xs:schema
			"""; // Missing closing tag
		File.WriteAllText(xsdPath, xsd);
		return xsdPath;
	}

	protected override void OnDispose()
	{
		if (Directory.Exists(_tempDir))
		{
			Directory.Delete(_tempDir, true);
		}
	}
	#endregion
}
