using NMYAML.CLI.Services;

namespace NMYAML.CLI.Tests;

/// <summary>
/// Integration tests covering the key requirements:
/// a) Valid YAML passes validation.
/// b) Valid XML passes schema validation.
/// c) Invalid XML fails schema validation.
/// d) Valid XML transforms into valid YAML.
/// </summary>
public class ContentValidationIntegrationTests : DisposableBase
{
	private readonly string _tempDir;
	private readonly string _xsltPath;
	private readonly string _xsdPath;

	public ContentValidationIntegrationTests()
	{
		// Setup test directory and files
		_tempDir = Path.Combine(Path.GetTempPath(), $"ContentValidationIntegrationTests_{Guid.NewGuid()}");
		Directory.CreateDirectory(_tempDir);

		// Create the sample XSD schema
		_xsdPath = Path.Combine(_tempDir, "workflow.xsd");
		File.WriteAllText(_xsdPath, GetSampleXsd());

		// Create the sample XSLT transform
		_xsltPath = Path.Combine(_tempDir, "workflow-transform.xslt");
		File.WriteAllText(_xsltPath, GetSampleXslt());
	}

	[Fact]
	public async Task Requirement_A_ValidYaml_PassesValidation()
	{
		// Arrange
		var validYaml = """
            name: Test Workflow
            on:
              push:
                branches: [ main ]
            
            jobs:
              build:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v3
                  - name: Build
                    run: echo Building...
            """;

		// Act
		var results = await YAML.ValidateContentAsync(validYaml).ToListAsync();

		// Assert
		Assert.Empty(results);
	}

	[Fact]
	public async Task Requirement_B_ValidXml_PassesSchemaValidation()
	{
		// Arrange
		var validXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <workflow xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <name>Test Workflow</name>
              <on>
                <push>
                  <branches>main</branches>
                </push>
              </on>
              <jobs>
                <build>
                  <runs-on>ubuntu-latest</runs-on>
                  <steps>
                    <step>
                      <uses>actions/checkout@v3</uses>
                    </step>
                    <step>
                      <name>Build</name>
                      <run>echo Building...</run>
                    </step>
                  </steps>
                </build>
              </jobs>
            </workflow>
            """;

		// Act
		var results = await XML.ValidateContentAsync(validXml, _xsdPath).ToListAsync();

		// Assert
		Assert.Empty(results);
	}

	[Fact]
	public async Task Requirement_C_InvalidXml_FailsSchemaValidation()
	{
		// Arrange
		var invalidXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <workflow xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <name>Test Workflow</name>
              <on>
                <push>
                  <branches>main</branches>
                </push>
              </on>
              <jobs>
                <build>
                  <runs-on>invalid-runner</runs-on>
                  <steps>
                    <invalid-step>  <!-- This element doesn't conform to the schema -->
                      <uses>actions/checkout@v3</uses>
                    </invalid-step>
                  </steps>
                </build>
              </jobs>
            </workflow>
            """;

		// Act
		var results = await XML.ValidateContentAsync(invalidXml, _xsdPath).ToListAsync();

		// Assert
		Assert.NotEmpty(results);
		Assert.Contains(results, r => r.Type == "XSD" && r.Severity == ValidationSeverity.Error);
	}

	[Fact]
	public async Task Requirement_D_ValidXml_TransformsToValidYaml()
	{
		// Arrange
		var validXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <workflow xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <name>Test Workflow</name>
              <on>
                <push>
                  <branches>main</branches>
                </push>
              </on>
              <jobs>
                <build>
                  <runs-on>ubuntu-latest</runs-on>
                  <steps>
                    <step>
                      <uses>actions/checkout@v3</uses>
                    </step>
                    <step>
                      <name>Build</name>
                      <run>echo Building...</run>
                    </step>
                  </steps>
                </build>
              </jobs>
            </workflow>
            """;

		// Act - Step 1: Validate XML is valid
		var xmlResults = await XML.ValidateContentAsync(validXml, _xsdPath).ToListAsync();

		// Assert - Step 1
		Assert.Empty(xmlResults);

		// Act - Step 2: Transform XML to YAML
		var yaml = XmlTransformationService.TransformContentAsync(validXml, _xsltPath);

		// Act - Step 3: Validate generated YAML
		var yamlResults = await YAML.ValidateContentAsync(yaml).ToListAsync();

		// Assert - Step 3
		Assert.Empty(yamlResults);
	}

	private static string GetSampleXsd()
	{
		return """
            <?xml version="1.0" encoding="UTF-8"?>
            <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
              
              <xs:element name="workflow">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="name" type="xs:string" />
                    <xs:element name="on">
                      <xs:complexType>
                        <xs:sequence>
                          <xs:element name="push">
                            <xs:complexType>
                              <xs:sequence>
                                <xs:element name="branches" type="xs:string" />
                              </xs:sequence>
                            </xs:complexType>
                          </xs:element>
                        </xs:sequence>
                      </xs:complexType>
                    </xs:element>
                    <xs:element name="jobs">
                      <xs:complexType>
                        <xs:sequence>
                          <xs:element name="build">
                            <xs:complexType>
                              <xs:sequence>
                                <xs:element name="runs-on">
                                  <xs:simpleType>
                                    <xs:restriction base="xs:string">
                                      <xs:enumeration value="ubuntu-latest" />
                                      <xs:enumeration value="windows-latest" />
                                      <xs:enumeration value="macos-latest" />
                                    </xs:restriction>
                                  </xs:simpleType>
                                </xs:element>
                                <xs:element name="steps">
                                  <xs:complexType>
                                    <xs:sequence>
                                      <xs:element name="step" maxOccurs="unbounded">
                                        <xs:complexType>
                                          <xs:sequence>
                                            <xs:element name="uses" type="xs:string" minOccurs="0" />
                                            <xs:element name="name" type="xs:string" minOccurs="0" />
                                            <xs:element name="run" type="xs:string" minOccurs="0" />
                                          </xs:sequence>
                                        </xs:complexType>
                                      </xs:element>
                                    </xs:sequence>
                                  </xs:complexType>
                                </xs:element>
                              </xs:sequence>
                            </xs:complexType>
                          </xs:element>
                        </xs:sequence>
                      </xs:complexType>
                    </xs:element>
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
              
            </xs:schema>
            """;
	}

	private static string GetSampleXslt()
	{
		return """
            <?xml version="1.0" encoding="UTF-8"?>
            <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
              <xsl:output method="text" indent="no" />
              
              <!-- Root template -->
              <xsl:template match="/workflow">
                <xsl:text>name: </xsl:text>
                <xsl:value-of select="name" />
                <xsl:text>&#xa;</xsl:text>
                
                <!-- On section -->
                <xsl:text>on:&#xa;</xsl:text>
                <xsl:apply-templates select="on" />
                
                <!-- Jobs section -->
                <xsl:text>jobs:&#xa;</xsl:text>
                <xsl:apply-templates select="jobs" />
              </xsl:template>
              
              <!-- On section templates -->
              <xsl:template match="on">
                <xsl:apply-templates select="push" />
              </xsl:template>
              
              <xsl:template match="push">
                <xsl:text>  push:&#xa;</xsl:text>
                <xsl:text>    branches: [ </xsl:text>
                <xsl:value-of select="branches" />
                <xsl:text> ]&#xa;</xsl:text>
              </xsl:template>
              
              <!-- Jobs section templates -->
              <xsl:template match="jobs">
                <xsl:apply-templates select="build" />
              </xsl:template>
              
              <xsl:template match="build">
                <xsl:text>  build:&#xa;</xsl:text>
                <xsl:text>    runs-on: </xsl:text>
                <xsl:value-of select="runs-on" />
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>    steps:&#xa;</xsl:text>
                <xsl:apply-templates select="steps/step" />
              </xsl:template>
              
              <!-- Steps templates -->
              <xsl:template match="step">
                <xsl:text>      - </xsl:text>
                <xsl:if test="uses">
                  <xsl:text>uses: </xsl:text>
                  <xsl:value-of select="uses" />
                  <xsl:text>&#xa;</xsl:text>
                </xsl:if>
                <xsl:if test="name">
                  <xsl:text>name: </xsl:text>
                  <xsl:value-of select="name" />
                  <xsl:text>&#xa;</xsl:text>
                </xsl:if>
                <xsl:if test="run">
                  <xsl:text>        run: </xsl:text>
                  <xsl:value-of select="run" />
                  <xsl:text>&#xa;</xsl:text>
                </xsl:if>
              </xsl:template>
            </xsl:stylesheet>
            """;
	}

	protected override void OnDispose()
	{
		if (Directory.Exists(_tempDir))
		{
			Directory.Delete(_tempDir, true);
		}
	}
}