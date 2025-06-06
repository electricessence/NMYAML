using NMYAML.CLI.Models;
using NMYAML.CLI.Services;
using Open.Disposable;
using System.Reflection;
using System.Xml;

namespace NMYAML.CLI.Tests;

public class XmlValidationServiceStaticTests : DisposableBase
{
	private readonly string _tempDir;

	public XmlValidationServiceStaticTests()
	{
		_tempDir = Path.Combine(Path.GetTempPath(), $"XmlValidationServiceStaticTests_{Guid.NewGuid()}");
		Directory.CreateDirectory(_tempDir);
	}

	[Fact]
	public async Task ValidateXmlSyntaxOnlyAsync_ValidXml_ReturnsNull()
	{
		// Arrange
		string xmlContent = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content</element>
			</root>
			""";

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("ValidateXmlSyntaxOnlyAsync", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xmlContent]);

		// Assert
		Assert.Null(result);
	}

	[Fact]
	public async Task ValidateXmlSyntaxOnlyAsync_InvalidXml_ReturnsError()
	{
		// Arrange
		string xmlContent = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content
			</root>
			""";

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("ValidateXmlSyntaxOnlyAsync", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xmlContent]);

		// Assert
		Assert.NotNull(result);
		Assert.Equal("Syntax", result.Type);
		Assert.Equal(ValidationSeverity.Error, result.Severity);
		Assert.Contains("XML syntax error", result.Message);
	}

	[Fact]
	public async Task LoadXsdSchemaAsync_ValidSchema_ReturnsNull()
	{
		// Arrange
		var xsdPath = CreateValidXsdFile();
		var readerSettings = new XmlReaderSettings();

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("LoadXsdSchemaAsync", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xsdPath, readerSettings]);

		// Assert
		Assert.Null(result);
		Assert.Equal(1, readerSettings.Schemas.Count);
	}

	[Fact]
	public async Task LoadXsdSchemaAsync_InvalidSchema_ReturnsError()
	{
		// Arrange
		var xsdPath = CreateInvalidXsdFile();
		var readerSettings = new XmlReaderSettings();

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("LoadXsdSchemaAsync", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xsdPath, readerSettings]);

		// Assert
		Assert.NotNull(result);
		Assert.Equal("Schema", result.Type);
		Assert.Equal(ValidationSeverity.Error, result.Severity);
		Assert.Contains("Error loading XSD schema", result.Message);
	}

	[Fact]
	public async Task ValidateXmlWithReaderAsync_ValidXml_ReturnsNull()
	{
		// Arrange
		var xmlContent = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content</element>
			</root>
			""";
		var readerSettings = new XmlReaderSettings { ValidationType = ValidationType.None };

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("ValidateXmlWithReaderAsync", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xmlContent, readerSettings]);

		// Assert
		Assert.Null(result);
	}

	[Fact]
	public async Task ValidateXmlWithReaderAsync_InvalidXml_ReturnsError()
	{
		// Arrange
		var xmlContent = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content
			</root>
			""";
		var readerSettings = new XmlReaderSettings { ValidationType = ValidationType.None };

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("ValidateXmlWithReaderAsync", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xmlContent, readerSettings]);

		// Assert
		Assert.NotNull(result);
		Assert.Equal("Exception", result.Type);
		Assert.Equal(ValidationSeverity.Error, result.Severity);
		Assert.Contains("XML validation failed", result.Message);
	}

	[Fact]
	public async Task ValidateXmlAgainstSchema_NullXmlContent_ReturnsNull()
	{
		// Arrange
		string xmlContent = null;
		string xsdPath = CreateValidXsdFile();

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("ValidateXmlAgainstSchema", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xmlContent, xsdPath]);

		// Assert
		Assert.Null(result);
	}

	[Fact]
	public async Task ValidateXmlAgainstSchema_NullXsdPath_ReturnsNull()
	{
		// Arrange
		var xmlContent = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <element attribute="value">content</element>
			</root>
			""";
		string? xsdPath = null;

		// Act
		var method = typeof(XmlValidationService)
			.GetMethod("ValidateXmlAgainstSchema", BindingFlags.NonPublic | BindingFlags.Static);
		var result = await (Task<ValidationResult?>)method.Invoke(null, [xmlContent, xsdPath]);

		// Assert
		Assert.Null(result);
	}

	#region Helper Methods
	private string CreateValidXsdFile()
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
			""";
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