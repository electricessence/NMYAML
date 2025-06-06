using NMYAML.CLI.Models;
using System.Diagnostics;
using System.Xml.Schema;
using static NMYAML.CLI.Services.XmlValidationService;

namespace NMYAML.CLI.Services;

/// <summary>
/// Service for validating XML files against XSD schemas using async validation pattern
/// </summary>
public sealed class XmlValidationService : AsyncValidationServiceBase<Params>
{
	/// <summary>
	/// Represents XML validation input containing the XML file path and optional XSD schema path
	/// </summary>
	/// <param name="XmlPath">Path to the XML file to validate</param>
	/// <param name="XsdPath">Optional path to the XSD schema file for validation</param>
	public readonly record struct Params(string XmlPath, string? XsdPath = null);

	private XmlValidationService() { }

	public static XmlValidationService Instance { get; } = new();

	/// <summary>
	/// Performs XML validation against XSD schema
	/// </summary>
	/// <param name="input">The XML validation input containing file paths</param>
	/// <returns>Async enumerable of validation results (null = success, ValidationResult = failure)</returns>
	protected override async IAsyncEnumerable<ValidationResult?> AsyncValidations(Params input)
	{
		// Step 1: Validate XML file path is present and valid.
		var xml = ValidateXmlPath(input.XmlPath);
		yield return xml;

		// Step 2: Validate the XML if it exists.
		string? xmlContent = xml is null ? File.ReadAllText(input.XmlPath) : null;
		if (xmlContent is not null) yield return await ValidateXmlSyntaxOnlyAsync(xmlContent).ConfigureAwait(false);

		// Step 3: If an XSD path is provided, validate it exists.
		var xsd = ValidateXsdPath(input.XsdPath);
		yield return xsd;

		// Step 4: If XML is valid and XSD exists, validate XML against XSD schema.
		yield return await ValidateXmlAgainstSchema(xmlContent, input.XsdPath);
	}

	/// <inheritdoc cref="AsyncValidationServiceBase{T}.ValidateAsync(T)"/>
	public IAsyncEnumerable<ValidationResult> ValidateAsync(string xmlPath, string? xsdPath = null)
		=> ValidateAsync(new Params(xmlPath, xsdPath));

	#region Input & File Path Validation
	private ValidationResult? ValidateFile(string filePath, string description)
	{
		Debug.Assert(filePath is not null);
		Debug.Assert(description is not null);

		if (filePath.Length == 0) return new("Input", ValidationSeverity.Error, $"{description} path cannot be empty");
		if (filePath.AsSpan().Trim().Length == 0) return new("Input", ValidationSeverity.Error, $"{description} path cannot be blank");
		return ValidateFileExists(filePath, description);
	}

	private ValidationResult? ValidateXmlPath(string xmlPath)
	{
		if (xmlPath is null) return new("Input", ValidationSeverity.Error, "XML path cannot be null");
		return ValidateFile(xmlPath, "XML");
	}

	private ValidationResult? ValidateXsdPath(string? xsdPath)
	{
		if (xsdPath is null) return ValidationResult.Success;
		return ValidateFile(xsdPath, "XML");
	}
	#endregion

	/// <summary>
	/// Helper method to validate XML syntax without yielding in try-catch
	/// </summary>
	private static async Task<ValidationResult?> ValidateXmlSyntaxOnlyAsync(string xmlContents)
	{
		try
		{
			var readerSettings = new XmlReaderSettings
			{
				ValidationType = ValidationType.None,
				Async = true
			};

			using var stringReader = new StringReader(xmlContents);
			using var xmlReader = XmlReader.Create(stringReader, readerSettings);
			while (await xmlReader.ReadAsync())
			{
				// Reading validates syntax
				await Task.Yield(); // Allow other work to proceed
			}

			return null; // XML syntax is valid
		}
		catch (XmlException ex)
		{
			return new ValidationResult("Syntax", ValidationSeverity.Error,
				$"XML syntax error: {ex.Message}", ex.LineNumber, "");
		}
		catch (Exception ex)
		{
			return new ValidationResult("Exception", ValidationSeverity.Error,
				$"Error reading XML file: {ex.Message}", 0, "");
		}
	}

	/// <summary>
	/// Validates XML against XSD schema if XSD path is provided
	/// </summary>
	private static async Task<ValidationResult?> ValidateXmlAgainstSchema(string? xmlContent, string? xsdPath)
	{
		if (xmlContent is null) return null; // No XML content to validate
		if (xsdPath is null) return null; // No XSD path provided, no validation needed

		var readerSettings = new XmlReaderSettings
		{
			ValidationType = ValidationType.Schema,
			ValidationFlags
			= XmlSchemaValidationFlags.ProcessInlineSchema
			| XmlSchemaValidationFlags.ProcessSchemaLocation
			| XmlSchemaValidationFlags.ReportValidationWarnings,
			Async = true
		};

		var schemaLoadResult = await LoadXsdSchemaAsync(xsdPath, readerSettings);
		if (schemaLoadResult != null)
		{
			return schemaLoadResult;
		}

		return await ValidateXmlWithReaderAsync(xmlContent, readerSettings);
	}

	/// <summary>
	/// Loads XSD schema into reader settings
	/// </summary>
	private static Task<ValidationResult?> LoadXsdSchemaAsync(string xsdPath, XmlReaderSettings readerSettings)
	{
		try
		{
			using var schemaStream = File.OpenRead(xsdPath);
			var schema = XmlSchema.Read(schemaStream, null);
			if (schema != null)
			{
				readerSettings.Schemas.Add(schema);
				return Task.FromResult<ValidationResult?>(null); // Success
			}
			else
			{
				return Task.FromResult<ValidationResult?>(new ValidationResult("Schema", ValidationSeverity.Error,
					"Failed to load XSD schema", 0, ""));
			}
		}
		catch (Exception ex)
		{
			return Task.FromResult<ValidationResult?>(new ValidationResult("Schema", ValidationSeverity.Error,
				$"Error loading XSD schema: {ex.Message}", 0, ""));
		}
	}

	/// <summary>
	/// Validates XML using the configured reader settings
	/// </summary>
	private static async Task<ValidationResult?> ValidateXmlWithReaderAsync(string xmlContent, XmlReaderSettings readerSettings)
	{
		try
		{
			using var stringReader = new StringReader(xmlContent);
			using var xmlReader = XmlReader.Create(stringReader, readerSettings);
			while (await xmlReader.ReadAsync())
			{
				// Reading triggers validation events
				await Task.Yield(); // Allow other work to proceed
			}

			return null; // Success
		}
		catch (Exception ex)
		{
			return new ValidationResult("Exception", ValidationSeverity.Error,
				$"XML validation failed: {ex.Message}", 0, "");
		}
	}
}
