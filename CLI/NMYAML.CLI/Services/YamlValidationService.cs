using NMYAML.CLI.Models;
using YamlDotNet.Core;
using YamlDotNet.Serialization;

namespace NMYAML.CLI.Services;

/// <summary>
/// Service for validating YAML files using async validation pattern
/// </summary>
public class YamlValidationService : AsyncValidationServiceBase<string>
{
	private YamlValidationService() { }

	public static YamlValidationService Instance { get; } = new();

	/// <summary>
	/// Performs YAML validation
	/// </summary>
	/// <param name="input">The YAML validation input containing file path and options</param>
	/// <returns>Async enumerable of validation results (null = success, ValidationResult = failure)</returns>
	protected override async IAsyncEnumerable<ValidationResult?> AsyncValidations(string yamlPath)
	{
		var file = ValidateFileExists(yamlPath, "YAML");
		yield return file;
		if (file is null) yield return await ValidateYamlSyntax(yamlPath);
	}

	/// <summary>
	/// Validates YAML syntax
	/// </summary>
	private static async Task<ValidationResult?> ValidateYamlSyntax(string yamlPath)
	{
		try
		{
			var yaml = await File.ReadAllTextAsync(yamlPath);
			if (string.IsNullOrEmpty(yaml))
			{
				return new ValidationResult("Syntax", ValidationSeverity.Error, "YAML file is empty", 0, "");
			}

			var deserializer = new DeserializerBuilder().Build();
			deserializer.Deserialize(yaml);
			return null; // Success
		}
		catch (YamlException ex)
		{
			return new ValidationResult("Syntax", ValidationSeverity.Error,
				$"YAML syntax error: {ex.Message}", ex.Start.Line, "");
		}
		catch (Exception ex)
		{
			return new ValidationResult("Exception", ValidationSeverity.Error,
				$"Error reading YAML file: {ex.Message}", 0, "");
		}
	}
}
