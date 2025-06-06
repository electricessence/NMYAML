using NMYAML.CLI.Transformers;
using System.Xml;

namespace NMYAML.CLI.Tests.Services;

public class XmlTransformationTests : DisposableBase
{
	private readonly string _tempDir;
	private readonly string _xsltPath;

	public XmlTransformationTests()
	{
		_tempDir = Path.Combine(Path.GetTempPath(), $"XmlTransformationTests_{Guid.NewGuid()}");
		Directory.CreateDirectory(_tempDir);

		// Create a sample XSLT file for testing
		_xsltPath = Path.Combine(_tempDir, "test-transform.xslt");
		File.WriteAllText(_xsltPath, GetSampleXslt());
	}

	[Fact]
	public void TransformContent_ValidXml_ReturnsValidYaml()
	{
		// Arrange
		var xmlContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <workflow>
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
		var yamlContent = XmlToYaml.TransformContent(xmlContent, _xsltPath);

		// Assert
		Assert.NotNull(yamlContent);
		Assert.NotEmpty(yamlContent);

		// Validate the YAML is well-formed
		var validationResults = YAML.ValidateContentAsync(yamlContent);
		Assert.Empty(validationResults.ToBlockingEnumerable());
	}

	[Fact]
	public void TransformContent_EmptyXml_ThrowsException()
	{
		// Arrange
		var emptyXml = "";

		// Act & Assert
		Assert.Throws<XmlException>(() => XmlToYaml.TransformContent(emptyXml, _xsltPath));
	}

	[Fact]
	public void TransformContent_InvalidXml_ThrowsException()
	{
		// Arrange
		var invalidXml = """
            <?xml version="1.0" encoding="utf-8"?>
            <workflow>
              <name>Test Workflow</name>
              <on>
                <push>
                  <branches>main</branches>
                </push>
              </on>
            </workflow
            """; // Missing closing tag

		// Act & Assert
		Assert.Throws<XmlException>(() => XmlToYaml.TransformContent(invalidXml, _xsltPath));
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