using NMYAML.CLI.Models;
using Open.Disposable;

namespace NMYAML.CLI.Services.Tests;

public class XmlValidationServiceTests : DisposableBase
{
	private readonly string _tempDir;
	public XmlValidationServiceTests()
	{
		_tempDir = Path.Combine(Path.GetTempPath(), $"XmlValidationServiceTests_{Guid.NewGuid()}");
		Directory.CreateDirectory(_tempDir);
	}

	[Fact]
	public async Task ValidateAsync_WithNullXmlPath_ReturnsError()
	{
		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(null!).ToListAsync();

		// Assert
		Assert.Single(results);
		Assert.Equal("Input", results[0].Type);
		Assert.Equal(ValidationSeverity.Error, results[0].Severity);
		Assert.Equal("XML path cannot be null", results[0].Message);
	}

	[Fact]
	public async Task ValidateAsync_WithEmptyXmlPath_ReturnsError()
	{
		// Act
		var results = await XmlValidationService.Instance.ValidateAsync("").ToListAsync();

		// Assert
		Assert.Single(results);
		Assert.Equal("Input", results[0].Type);
		Assert.Equal(ValidationSeverity.Error, results[0].Severity);
		Assert.Equal("XML path cannot be empty", results[0].Message);
	}

	[Fact]
	public async Task ValidateAsync_WithBlankXmlPath_ReturnsError()
	{
		// Act
		var results = await XmlValidationService.Instance.ValidateAsync("   ").ToListAsync();

		// Assert
		Assert.Single(results);
		Assert.Equal("Input", results[0].Type);
		Assert.Equal(ValidationSeverity.Error, results[0].Severity);
		Assert.Equal("XML path cannot be blank", results[0].Message);
	}

	[Fact]
	public async Task ValidateAsync_WithNonExistentXmlPath_ReturnsError()
	{
		// Act
		var results = await XmlValidationService.Instance.ValidateAsync("nonexistent.xml").ToListAsync();

		// Assert
		Assert.Single(results);
		Assert.Equal("File", results[0].Type);
		Assert.Equal(ValidationSeverity.Error, results[0].Severity);
		Assert.Equal("XML file not found", results[0].Message);
	}
	[Fact]
	public async Task ValidateAsync_WithNonExistentXsdPath_ReturnsError()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, "nonexistent.xsd").ToListAsync();

		// Assert
		Assert.Single(results);
		Assert.Contains(results, r => r.Type == "File" && r.Severity == ValidationSeverity.Error && r.Message == "XSD schema file not found");
	}

	[Fact]
	public async Task ValidateAsync_WithInvalidXmlSyntax_ReturnsError()
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
	public async Task ValidateAsync_WithValidXmlNoSchema_ReturnsNoError()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath).ToListAsync();

		// Assert
		Assert.Empty(results);
	}

	[Fact]
	public async Task ValidateAsync_WithValidXmlAndSchema_ReturnsNoError()
	{
		// Arrange
		var xmlPath = CreateValidXmlFile();
		var xsdPath = CreateMatchingXsdFile();

		// Act
		var results = await XmlValidationService.Instance.ValidateAsync(xmlPath, xsdPath).ToListAsync();

		// Assert
		Assert.Empty(results);
	}

	[Fact]
	public async Task ValidateAsync_WithValidXmlAndInvalidSchema_ReturnsError()
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
	public async Task ValidateAsync_WithInvalidXmlAgainstSchema_ReturnsError()
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
			""";
		File.WriteAllText(xmlPath, xml);
		return xmlPath;
	}

	private string CreateNonConformingXmlFile()
	{
		var xmlPath = Path.Combine(_tempDir, "nonconforming.xml");
		var xml = """
			<?xml version="1.0" encoding="utf-8"?>
			<root>
			  <wrongElement>This element doesn't match the schema</wrongElement>
			</root>
			""";
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

public static class AsyncEnumerableExtensions
{
	public static async Task<List<T>> ToListAsync<T>(this IAsyncEnumerable<T> asyncEnumerable)
	{
		var results = new List<T>();
		await foreach (var item in asyncEnumerable)
		{
			results.Add(item);
		}

		return results;
	}
}