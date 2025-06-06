namespace NMYAML.CLI.Transformers;

/// <summary>
/// Static class for transforming XML to YAML
/// </summary>
public static partial class XmlToYaml
{
	/// <summary>
	/// Transforms XML file to YAML using an XSLT transformation
	/// </summary>
	/// <param name="xmlPath">Path to the XML file</param>
	/// <param name="xsltPath">Path to the XSLT file</param>
	/// <returns>The transformed YAML content</returns>
	public static string Transform(string xmlPath, string xsltPath)
	{
		// Create XSL transform
		var xslt = new XslCompiledTransform();
		var xsltSettings = new XsltSettings(enableDocumentFunction: true, enableScript: true);
		xslt.Load(xsltPath, xsltSettings, null);

		// Create XML reader
		var xmlReaderSettings = new XmlReaderSettings
		{
			DtdProcessing = DtdProcessing.Parse
		};

		using var xmlReader = XmlReader.Create(xmlPath, xmlReaderSettings);

		// Transform to string
		using var stringWriter = new StringWriter();
		using var xmlWriter = XmlWriter.Create(stringWriter, CreateXmlWriterSettings());

		xslt.Transform(xmlReader, xmlWriter);

		var yamlContent = stringWriter.ToString();

		// Clean up YAML output
		return CleanYamlOutput(yamlContent);
	}

	/// <summary>
	/// Transforms XML content to YAML using an XSLT transformation
	/// </summary>
	/// <param name="xmlContent">The XML content to transform</param>
	/// <param name="xsltPath">Path to the XSLT file</param>
	/// <returns>The transformed YAML content as a string</returns>
	public static string TransformContent(string xmlContent, string xsltPath)
	{
		// Create XSL transform
		var xslt = new XslCompiledTransform();
		var xsltSettings = new XsltSettings(enableDocumentFunction: true, enableScript: true);
		xslt.Load(xsltPath, xsltSettings, null);

		// Create XML reader from content
		var xmlReaderSettings = new XmlReaderSettings
		{
			DtdProcessing = DtdProcessing.Parse
		};

		using var stringReader = new StringReader(xmlContent);
		using var xmlReader = XmlReader.Create(stringReader, xmlReaderSettings);

		// Create output writer
		using var outputStringWriter = new StringWriter();
		using var xmlWriter = XmlWriter.Create(outputStringWriter, CreateXmlWriterSettings());

		xslt.Transform(xmlReader, xmlWriter);

		var yamlContent = outputStringWriter.ToString();

		// Clean up YAML output
		return CleanYamlOutput(yamlContent);
	}

	/// <summary>
	/// Transforms XML file to YAML and writes it to an output file
	/// </summary>
	/// <param name="xmlPath">Path to the XML file</param>
	/// <param name="xsltPath">Path to the XSLT file</param>
	/// <param name="outputPath">Path where the YAML file will be written</param>
	public static async Task TransformToFileAsync(string xmlPath, string xsltPath, string outputPath)
	{
		// Ensure output directory exists
		var outputDir = Path.GetDirectoryName(outputPath);
		if (!string.IsNullOrEmpty(outputDir) && !Directory.Exists(outputDir))
		{
			Directory.CreateDirectory(outputDir);
		}

		// Transform
		var yamlContent = Transform(xmlPath, xsltPath);

		// Write to output file
		await File.WriteAllTextAsync(outputPath, yamlContent, Encoding.UTF8);
	}

	private static XmlWriterSettings CreateXmlWriterSettings()
	{
		return new XmlWriterSettings
		{
			Indent = false,
			OmitXmlDeclaration = true,
			ConformanceLevel = ConformanceLevel.Fragment,
			Encoding = Encoding.UTF8
		};
	}

	private static string CleanYamlOutput(string yamlContent)
	{
		// Remove empty lines at the beginning
		yamlContent = yamlContent.TrimStart('\r', '\n', ' ', '\t');

		// Fix common YAML formatting issues
		yamlContent = EndOfLineWhiteSpacePattern().Replace(yamlContent, ""); // Remove trailing whitespace
		yamlContent = ExtraWhiteSpaceNewLinePattern().Replace(yamlContent, "\n\n"); // Normalize multiple empty lines

		// Fix empty values issues that might come from XSLT
		yamlContent = ColonLineEndingPattern().Replace(yamlContent, ": \"\""); // Empty values

		// Ensure proper line endings
		yamlContent = yamlContent.Replace("\r\n", "\n").Replace("\r", "\n");

		// Add final newline if missing
		if (!yamlContent.EndsWith('\n'))
		{
			yamlContent += "\n";
		}

		return yamlContent;
	}

	[GeneratedRegex(@"\s+$", RegexOptions.Multiline)]
	private static partial Regex EndOfLineWhiteSpacePattern();

	[GeneratedRegex(@"\n\s*\n\s*\n+")]
	private static partial Regex ExtraWhiteSpaceNewLinePattern();

	[GeneratedRegex(@":\s*$", RegexOptions.Multiline)]
	private static partial Regex ColonLineEndingPattern();
}