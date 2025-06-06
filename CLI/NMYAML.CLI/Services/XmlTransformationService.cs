using NMYAML.CLI.Models;

namespace NMYAML.CLI.Services;

public partial class XmlTransformationService
{
	public static async Task<TransformationResult> TransformAsync(ConversionOptions options)
	{
		var startTime = DateTime.UtcNow;

		try
		{
			AnsiConsole.MarkupLine("[cyan]Starting XML to YAML transformation...[/]");

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
			}            // Step 1: XML Validation (optional)

			ValidationSummary? xmlValidation = null;
			if (!options.SkipXmlValidation && !string.IsNullOrEmpty(options.XsdSchemaPath))
			{
				AnsiConsole.MarkupLine("[yellow]Step 1: Validating XML against schema...[/]");

				var xmlValidationStart = DateTime.UtcNow;
				var xmlResults = new List<ValidationResult>();

				await foreach (var result in XmlValidationService.Instance.ValidateAsync(options.InputPath, options.XsdSchemaPath))
				{
					xmlResults.Add(result);
				}

				xmlValidation = ValidationSummary.FromResults(xmlResults, DateTime.UtcNow - xmlValidationStart);

				if (!xmlValidation.IsValid)
				{
					AnsiConsole.MarkupLine("[red]XML validation failed![/]");
					if (options.DetailedOutput)
					{
						// TODO: Display Validation Summary.
					}

					return new TransformationResult(
						Success: false,
						OutputPath: null,
						XmlValidation: xmlValidation,
						YamlValidation: null,
						ErrorMessage: "XML validation failed. Fix errors before transformation.",
						Duration: DateTime.UtcNow - startTime
					);
				}

				AnsiConsole.MarkupLine("[green]✓ XML validation passed[/]");
			}

			// Step 2: XSLT Transformation
			AnsiConsole.MarkupLine("[yellow]Step 2: Transforming XML to YAML...[/]");
			await PerformTransformation(options.InputPath, xsltPath, options.OutputPath);
			AnsiConsole.MarkupLine("[green]✓ Transformation completed[/]");            // Step 3: YAML Validation (optional)
			ValidationSummary? yamlValidation = null;
			if (!options.SkipYamlValidation && File.Exists(options.OutputPath))
			{
				AnsiConsole.MarkupLine("[yellow]Step 3: Validating generated YAML...[/]");
				var yamlValidationStart = DateTime.UtcNow;
				var yamlResults = new List<ValidationResult>();

				await foreach (var result in YamlValidationService.Instance.ValidateAsync(options.OutputPath))
				{
					yamlResults.Add(result);
				}

				yamlValidation = ValidationSummary.FromResults(yamlResults, DateTime.UtcNow - yamlValidationStart);

				if (options.DetailedOutput)
				{
					// TODO: Display YAML Validation Summary.
				}
				else if (yamlValidation.Errors > 0)
				{
					AnsiConsole.MarkupLine($"[yellow]⚠ YAML validation found {yamlValidation.Errors} errors and {yamlValidation.Warnings} warnings[/]");
				}
				else
				{
					AnsiConsole.MarkupLine("[green]✓ YAML validation passed[/]");
				}
			}

			var duration = DateTime.UtcNow - startTime;
			AnsiConsole.MarkupLine($"[green]✓ Conversion completed successfully in {duration.TotalMilliseconds:F0}ms[/]");

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
	}    /// <summary>
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

		// Clean up YAML output
		yamlContent = CleanYamlOutput(yamlContent);

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

		// Clean up YAML output
		yamlContent = CleanYamlOutput(yamlContent);

		// Write to output file
		await File.WriteAllTextAsync(outputPath, yamlContent, Encoding.UTF8);
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

	[GeneratedRegex(@"\s+$", RegexOptions.Multiline)]
	private static partial Regex EndOfLineWhiteSpacePattern();
	[GeneratedRegex(@"\n\s*\n\s*\n+")]
	private static partial Regex ExtraWhiteSpaceNewLinePattern();
	[GeneratedRegex(@":\s*$", RegexOptions.Multiline)]
	private static partial Regex ColonLineEndingPattern();
}
