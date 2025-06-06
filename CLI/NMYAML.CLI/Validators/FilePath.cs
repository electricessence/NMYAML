using NMYAML.CLI.Models;
using System.Diagnostics;

namespace NMYAML.CLI.Validators;

public static class FilePath
{
	public static ValidationResult? Validate(string filePath, string description)
	{
		Debug.Assert(filePath is not null);
		Debug.Assert(description is not null);

		if (filePath.Length == 0) return new("Input", ValidationSeverity.Error, $"{description} path cannot be empty");
		if (filePath.AsSpan().Trim().Length == 0) return new("Input", ValidationSeverity.Error, $"{description} path cannot be blank");
		return ValidateExists(filePath, description);
	}

	public static ValidationResult? ValidateExists(string path, string description)
		=> File.Exists(path) ? null : new ValidationResult(
			"File", ValidationSeverity.Error, $"{description} file not found");
}
