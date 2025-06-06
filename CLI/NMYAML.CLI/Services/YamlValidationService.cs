using NMYAML.CLI.Models;
using YamlDotNet.Core;
using YamlDotNet.Serialization;

namespace NMYAML.CLI.Services;

/// <summary>
/// Service for validating YAML files using async validation pattern
/// </summary>
public class YamlValidationService : AsyncValidationServiceBase<YamlValidationService.YamlValidationParams>
{
	/// <summary>
	/// Parameters for YAML validation
	/// </summary>
	public readonly record struct YamlValidationParams
	{
		/// <summary>
		/// Path to the YAML file (optional if Content is provided)
		/// </summary>
		public string YamlPath { get; init; }
		
		/// <summary>
		/// Direct YAML content to validate (optional if YamlPath is provided)
		/// </summary>
		public string? Content { get; init; }
		
		/// <summary>
		/// Creates a new instance of YamlValidationParams with a file path
		/// </summary>
		public YamlValidationParams(string yamlPath)
		{
			YamlPath = yamlPath;
			Content = null;
		}
		
		/// <summary>
		/// Creates a new instance of YamlValidationParams with direct content
		/// </summary>
		/// <param name="content">The YAML content to validate</param>
		/// <returns>A new YamlValidationParams instance</returns>
		public static YamlValidationParams FromContent(string content)
		{
			return new YamlValidationParams
			{
				YamlPath = "content",
				Content = content
			};
		}
	}

	private YamlValidationService() { }

	public static YamlValidationService Instance { get; } = new();

	/// <summary>
	/// Performs YAML validation
	/// </summary>
	/// <param name="input">The YAML validation parameters</param>
	/// <returns>Async enumerable of validation results (null = success, ValidationResult = failure)</returns>
	protected override async IAsyncEnumerable<ValidationResult?> AsyncValidations(YamlValidationParams input)
	{
		if (input.Content != null)
		{
			// Validate direct YAML content
			yield return await ValidateYamlSyntax(input.Content);
		}
		else
		{
			// Validate YAML file
			var file = ValidateFileExists(input.YamlPath, "YAML");
			yield return file;
			if (file is null) 
			{
				string content = await File.ReadAllTextAsync(input.YamlPath);
				yield return await ValidateYamlSyntax(content);
			}
		}
	}
	
	/// <summary>
	/// Validates the syntax of a YAML file
	/// </summary>
	/// <param name="yamlPath">Path to the YAML file</param>
	public IAsyncEnumerable<ValidationResult> ValidateAsync(string yamlPath)
		=> ValidateAsync(new YamlValidationParams(yamlPath));
		
	/// <summary>
	/// Validates the syntax of YAML content directly
	/// </summary>
	/// <param name="yamlContent">The YAML content to validate</param>
	public IAsyncEnumerable<ValidationResult> ValidateContentAsync(string yamlContent)
		=> ValidateAsync(YamlValidationParams.FromContent(yamlContent));

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
