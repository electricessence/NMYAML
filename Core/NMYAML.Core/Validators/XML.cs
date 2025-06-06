using NMYAML.Core.Models;
using System.Xml.Schema;
using static NMYAML.Core.Validators.FilePath;

namespace NMYAML.Core.Validators;

/// <summary>
/// Static class providing XML validation methods
/// </summary>
public static class XML
{
	/// <summary>
	/// Validates XML syntax and optionally against an XSD schema
	/// </summary>
	/// <param name="xmlPath">Path to the XML file to validate</param>
	/// <param name="xsdPath">Optional path to the XSD schema file for validation</param>
	/// <returns>Async enumerable of validation results</returns>
	public static async IAsyncEnumerable<ValidationResult> ValidateAsync(string xmlPath, string? xsdPath = null)
	{
		// Step 1: Validate XML file path is present and valid.
		var xmlPathError = ValidateXmlPath(xmlPath);
		if (xmlPathError is not null)
		{
			yield return xmlPathError;
			yield break;
		}

		// Step 2: Load XML content and validate syntax
		string xmlContent = await File.ReadAllTextAsync(xmlPath);
		var syntaxError = await ValidateXmlSyntaxOnlyAsync(xmlContent);
		if (syntaxError is not null)
		{
			yield return syntaxError;
			yield break;
		}

		// Step 3: If an XSD path is provided, validate it exists.
		if (xsdPath is not null)
		{
			var xsdPathError = ValidateXsdPath(xsdPath);
			if (xsdPathError is not null)
			{
				yield return xsdPathError;
				yield break;
			}

			// Step 4: Validate XML against XSD schema
			var schemaError = await ValidateXmlAgainstSchema(xmlContent, xsdPath);
			if (schemaError is not null)
			{
				yield return schemaError;
			}
		}
	}

	/// <summary>
	/// Validates XML content directly instead of from a file path
	/// </summary>
	/// <param name="xmlContent">The XML content to validate</param>
	/// <param name="xsdPath">Optional path to the XSD schema file for validation</param>
	/// <returns>Async enumerable of validation results</returns>
	public static async IAsyncEnumerable<ValidationResult> ValidateContentAsync(string xmlContent, string? xsdPath = null)
	{
		// Step 1: Validate XML syntax
		var syntaxError = await ValidateXmlSyntaxOnlyAsync(xmlContent);
		if (syntaxError is not null)
		{
			yield return syntaxError;
			yield break;
		}

		// Step 2: If an XSD path is provided, validate it exists and then validate XML against it
		if (xsdPath is not null)
		{
			var xsdPathError = ValidateXsdPath(xsdPath);
			if (xsdPathError is not null)
			{
				yield return xsdPathError;
				yield break;
			}

			var schemaError = await ValidateXmlAgainstSchema(xmlContent, xsdPath);
			if (schemaError is not null)
			{
				yield return schemaError;
			}
		}
	}

	#region Input & File Path Validation
	private static ValidationResult? ValidateXmlPath(string xmlPath)
	{
		if (xmlPath is null) return new("Input", ValidationSeverity.Error, "XML path cannot be null");
		return Validate(xmlPath, "XML");
	}

	private static ValidationResult? ValidateXsdPath(string? xsdPath)
	{
		if (xsdPath is null) return null; // XSD is optional
		return Validate(xsdPath, "XSD schema");
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
	private static async Task<ValidationResult?> ValidateXmlAgainstSchema(string xmlContent, string xsdPath)
	{
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