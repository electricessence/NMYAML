using NMYAML.Core.Models;
using NMYAML.Core.Validators;

namespace NMYAML.Core.Services;

public partial class XmlTransformationService
{
	public static async Task<TransformationResult> TransformAsync(ConversionOptions options)
	{
		var startTime = DateTime.UtcNow;

		try
		{
			// Validate input files
			if (!File.Exists(options.InputPath))
			{
				return new TransformationResult(
					Success: false,
					OutputPath: null,
					XmlValidation: null,
					YamlValidation: null,
					ErrorMessage: $"Input XML file not found: {options.InputPath}",
					Duration: DateTime.UtcNow - startTime
				);
			}

			var xsltPath = options.XsltPath ?? GetDefaultXsltPath();
			if (!File.Exists(xsltPath))
			{
				return new TransformationResult(
					Success: false,
					OutputPath: null,
					XmlValidation: null,
					YamlValidation: null,
					ErrorMessage: $"XSLT transform file not found: {xsltPath}",
					Duration: DateTime.UtcNow - startTime
				);
			}

			// Step 1: XML Validation (optional)
			ValidationSummary? xmlValidation = null;
			if (!options.SkipXmlValidation && !string.IsNullOrEmpty(options.XsdSchemaPath))
			{
				var xmlValidationStart = DateTime.UtcNow;
				var xmlResults = new List<ValidationResult>();

				await foreach (var result in XML.ValidateAsync(options.InputPath, options.XsdSchemaPath))
				{
					xmlResults.Add(result);
				}

				xmlValidation = ValidationSummary.FromResults(xmlResults, DateTime.UtcNow - xmlValidationStart);

				if (!xmlValidation.IsValid)
				{
					return new TransformationResult(
						Success: false,
						OutputPath: null,
						XmlValidation: xmlValidation,
						YamlValidation: null,
						ErrorMessage: "XML validation failed. Fix errors before transformation.",
						Duration: DateTime.UtcNow - startTime
					);
				}
			}

			// Step 2: XSLT Transformation
			await PerformTransformation(options.InputPath, xsltPath, options.OutputPath);

			// Step 3: YAML Validation (optional)
			ValidationSummary? yamlValidation = null;
			if (!options.SkipYamlValidation && File.Exists(options.OutputPath))
			{
				var yamlValidationStart = DateTime.UtcNow;
				var yamlResults = new List<ValidationResult>();

				await foreach (var result in YAML.ValidateAsync(options.OutputPath))
				{
					yamlResults.Add(result);
				}

				yamlValidation = ValidationSummary.FromResults(yamlResults, DateTime.UtcNow - yamlValidationStart);
			}

			var duration = DateTime.UtcNow - startTime;

			return new TransformationResult(
				Success: true,
				OutputPath: options.OutputPath,
				XmlValidation: xmlValidation,
				YamlValidation: yamlValidation,
				ErrorMessage: null,
				Duration: duration
			);
		}
		catch (Exception ex)
		{
			var duration = DateTime.UtcNow - startTime;
			return new TransformationResult(
				Success: false,
				OutputPath: null,
				XmlValidation: null,
				YamlValidation: null,
				ErrorMessage: ex.Message,
				Duration: duration
			);
		}
	}

	/// <summary>
	/// Simple transformation method that returns YAML content as string
	/// </summary>
	public static string TransformAsync(string xmlPath, string xsltPath)
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

		// Create output writer
		var writerSettings = new XmlWriterSettings
		{
			Indent = false,
			OmitXmlDeclaration = true,
			ConformanceLevel = ConformanceLevel.Fragment,
			Encoding = Encoding.UTF8
		};

		// Transform to string
		using var stringWriter = new StringWriter();
		using var xmlWriter = XmlWriter.Create(stringWriter, writerSettings);

		xslt.Transform(xmlReader, xmlWriter);
		var yamlContent = stringWriter.ToString();

		return yamlContent;
	}

	/// <summary>
	/// Transforms XML content to YAML using an XSLT transformation
	/// </summary>
	/// <param name="xmlContent">The XML content to transform</param>
	/// <param name="xsltPath">Path to the XSLT file</param>
	/// <returns>The transformed YAML content as a string</returns>
	public static string TransformContentAsync(string xmlContent, string xsltPath)
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
		var writerSettings = new XmlWriterSettings
		{
			Indent = false,
			OmitXmlDeclaration = true,
			ConformanceLevel = ConformanceLevel.Fragment,
			Encoding = Encoding.UTF8
		};

		// Transform to string
		using var outputStringWriter = new StringWriter();
		using var xmlWriter = XmlWriter.Create(outputStringWriter, writerSettings);

		xslt.Transform(xmlReader, xmlWriter);
		var yamlContent = outputStringWriter.ToString();

		return yamlContent;
	}

	private static async Task PerformTransformation(string xmlPath, string xsltPath, string outputPath)
	{
		// Ensure output directory exists
		var outputDir = Path.GetDirectoryName(outputPath);
		if (!string.IsNullOrEmpty(outputDir) && !Directory.Exists(outputDir))
		{
			Directory.CreateDirectory(outputDir);
		}

		// Create XSL transform
		var xslt = new XslCompiledTransform();
		var xsltSettings = new XsltSettings(enableDocumentFunction: true, enableScript: true);
		xslt.Load(xsltPath, xsltSettings, null);

		// Create XML reader
		var xmlReaderSettings = new XmlReaderSettings
		{
			DtdProcessing = DtdProcessing.Parse,
			Async = true
		};

		using var xmlReader = XmlReader.Create(xmlPath, xmlReaderSettings);

		// Create output writer
		var writerSettings = new XmlWriterSettings
		{
			Indent = false,
			OmitXmlDeclaration = true,
			ConformanceLevel = ConformanceLevel.Fragment,
			Encoding = Encoding.UTF8
		};

		// Transform to string first to clean up output
		using var stringWriter = new StringWriter();
		using var xmlWriter = XmlWriter.Create(stringWriter, writerSettings);

		xslt.Transform(xmlReader, xmlWriter);
		var yamlContent = stringWriter.ToString();

		// Write to output file
		await File.WriteAllTextAsync(outputPath, yamlContent, Encoding.UTF8);
	}

	private static string GetDefaultXsltPath()
	{
		// Try to find XSLT file relative to the executable
		var baseDir = AppDomain.CurrentDomain.BaseDirectory;
		var candidates = new[]
		{
			Path.Combine(baseDir, "github-actions-transform.xslt"),
			Path.Combine(baseDir, "xslt", "github-actions-transform.xslt"),
			Path.Combine(baseDir, "..", "..", "xslt", "github-actions-transform.xslt"),
			Path.Combine(Directory.GetCurrentDirectory(), "xslt", "github-actions-transform.xslt")
		};

		return candidates.FirstOrDefault(File.Exists)
			   ?? throw new FileNotFoundException("Default XSLT transform file not found. Please specify --xslt-path.");
	}
}
