using NMYAML.CLI.Models;
using YamlDotNet.Core;
using YamlDotNet.Serialization;
using static NMYAML.CLI.Validators.FilePath;

namespace NMYAML.CLI.Validators;

/// <summary>
/// Static class providing YAML validation methods
/// </summary>
public static class YAML
{
	/// <summary>
	/// Validates the syntax of a YAML file
	/// </summary>
	/// <param name="yamlPath">Path to the YAML file</param>
	public static async IAsyncEnumerable<ValidationResult> ValidateAsync(string yamlPath)
	{
		// Validate file exists
		var fileError = ValidateExists(yamlPath, "YAML");
		if (fileError is not null)
		{
			yield return fileError;
			yield break;
		}

		// Read and validate content
		string content = await File.ReadAllTextAsync(yamlPath);
		var contentError = await ValidateYamlSyntax(content);
		if (contentError is not null)
		{
			yield return contentError;
		}
	}

	/// <summary>
	/// Validates the syntax of YAML content directly
	/// </summary>
	/// <param name="yamlContent">The YAML content to validate</param>
	public static async IAsyncEnumerable<ValidationResult> ValidateContentAsync(string yamlContent)
	{
		var result = await ValidateYamlSyntax(yamlContent);
		if (result is not null)
		{
			yield return result;
		}
	}

	/// <summary>
	/// Validates YAML syntax
	/// </summary>
	private static Task<ValidationResult?> ValidateYamlSyntax(string yamlContent)
	{
		try
		{
			if (string.IsNullOrEmpty(yamlContent))
			{
				return Task.FromResult<ValidationResult?>(new ValidationResult("Syntax", ValidationSeverity.Error, "YAML content is empty", 0, ""));
			}

			var deserializer = new DeserializerBuilder().Build();
			deserializer.Deserialize(yamlContent);
			return Task.FromResult<ValidationResult?>(null); // Success
		}
		catch (YamlException ex)
		{
			return Task.FromResult<ValidationResult?>(new ValidationResult("Syntax", ValidationSeverity.Error,
				$"YAML syntax error: {ex.Message}", ex.Start.Line, ""));
		}
		catch (Exception ex)
		{
			return Task.FromResult<ValidationResult?>(new ValidationResult("Exception", ValidationSeverity.Error,
				$"Error reading YAML content: {ex.Message}", 0, ""));
		}
	}
}