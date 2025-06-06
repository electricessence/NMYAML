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
	public readonly record struct Params(string XmlPath, string? XsdPath = null)
	{
		public string? Content { get; init; } = null;
	}

	private XmlValidationService() { }

	public static XmlValidationService Instance { get; } = new();
	/// <summary>
	/// Performs XML validation against XSD schema
	/// </summary>
	/// <param name="input">The XML validation input containing file paths</param>
	/// <returns>Async enumerable of validation results (null = success, ValidationResult = failure)</returns>
	protected override async IAsyncEnumerable<ValidationResult?> AsyncValidations(Params input)
	{
		// Initialize content variable for either path or direct content
		string? xmlContent = input.Content;

		// If content is null, validate the path and load content from file
		if (xmlContent is null)
		{
			// Step 1: Validate XML file path is present and valid.
			var xml = ValidateXmlPath(input.XmlPath);
			yield return xml;

			// Step 2: Load XML content if path is valid
			xmlContent = xml is null ? File.ReadAllText(input.XmlPath) : null;
		}

		// Step 3: Validate the XML content if available
		if (xmlContent is not null)
			yield return await ValidateXmlSyntaxOnlyAsync(xmlContent).ConfigureAwait(false);

		// Step 4: If an XSD path is provided, validate it exists.
		var xsd = ValidateXsdPath(input.XsdPath);
		yield return xsd;
		
		// Step 5: If XML is valid and XSD exists, validate XML against XSD schema.
		if (xmlContent is not null && xsd is null && input.XsdPath is not null) // Only proceed if XML content is valid and XSD path is valid
		{
			yield return await ValidateXmlAgainstSchema(xmlContent, input.XsdPath);
		}
	}

	/// <inheritdoc cref="AsyncValidationServiceBase{T}.ValidateAsync(T)"/>
	public IAsyncEnumerable<ValidationResult> ValidateAsync(string xmlPath, string? xsdPath = null)
		=> ValidateAsync(new Params(xmlPath, xsdPath));
		
	/// <summary>
	/// Validates XML content directly instead of from a file path
	/// </summary>
	/// <param name="xmlContent">The XML content to validate</param>
	/// <param name="xsdPath">Optional path to the XSD schema file for validation</param>
	/// <returns>Async enumerable of validation results</returns>
	public IAsyncEnumerable<ValidationResult> ValidateContentAsync(string xmlContent, string? xsdPath = null)
		=> ValidateAsync(new Params("content", xsdPath) { Content = xmlContent });

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
		return ValidateFile(xsdPath, "XSD schema");
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
		ValidationResult? validationError = null;
		
		// Set up validation event handler for schema validation
		readerSettings.ValidationEventHandler += (sender, e) =>
		{
			if (validationError == null) // Only capture the first error
			{
				validationError = new ValidationResult("XSD", ValidationSeverity.Error,
					e.Message, e.Exception?.Data.Contains("LineNumber") == true ? (long)e.Exception.Data["LineNumber"]! : 0, "");
			}
		};

		try
		{
			using var stringReader = new StringReader(xmlContent);
			using var xmlReader = XmlReader.Create(stringReader, readerSettings);
			while (await xmlReader.ReadAsync())
			{
				// Reading triggers validation events
				await Task.Yield(); // Allow other work to proceed
			}

			return validationError; // Return validation error if any, null for success
		}
		catch (Exception ex)
		{
			// If we already have a validation error, return it instead of the exception
			if (validationError != null)
				return validationError;
				
			return new ValidationResult("Exception", ValidationSeverity.Error,
				$"XML validation failed: {ex.Message}", 0, "");
		}
	}
}
