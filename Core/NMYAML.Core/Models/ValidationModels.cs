namespace NMYAML.Core.Models;

public enum ValidationSeverity
{
	Info,
	Warning,
	Error
}

public record ValidationResult(
	string Type,
	ValidationSeverity Severity,
	string Message,
	long LineNumber = 0,
	object? Context = null
)
{
	public override string ToString() => $"[{Severity}] Line {LineNumber}: {Message}";

	public static ValidationResult? Success => null;
}

public record ValidationSummary(
	int TotalIssues,
	int Errors,
	int Warnings,
	int Info,
	bool IsValid,
	TimeSpan Duration
)
{
	public static ValidationSummary FromResults(IEnumerable<ValidationResult> results, TimeSpan duration)
	{
		var resultsList = results.ToList();
		return new ValidationSummary(
			TotalIssues: resultsList.Count,
			Errors: resultsList.Count(r => r.Severity == ValidationSeverity.Error),
			Warnings: resultsList.Count(r => r.Severity == ValidationSeverity.Warning),
			Info: resultsList.Count(r => r.Severity == ValidationSeverity.Info),
			IsValid: resultsList.All(r => r.Severity != ValidationSeverity.Error),
			Duration: duration
		);
	}

	public static async Task<ValidationSummary> FromResultsAsync(IAsyncEnumerable<ValidationResult> results, TimeSpan duration)
	{
		var resultsList = new List<ValidationResult>();
		await foreach (var result in results)
		{
			resultsList.Add(result);
		}

		return new ValidationSummary(
			TotalIssues: resultsList.Count,
			Errors: resultsList.Count(r => r.Severity == ValidationSeverity.Error),
			Warnings: resultsList.Count(r => r.Severity == ValidationSeverity.Warning),
			Info: resultsList.Count(r => r.Severity == ValidationSeverity.Info),
			IsValid: resultsList.All(r => r.Severity != ValidationSeverity.Error),
			Duration: duration
		);
	}
}

public record TransformationResult(
	bool Success,
	string? OutputPath,
	ValidationSummary? XmlValidation,
	ValidationSummary? YamlValidation,
	string? ErrorMessage,
	TimeSpan Duration
);

public record ConversionOptions(
	string InputPath,
	string OutputPath,
	string? XsdSchemaPath = null,
	string? XsltPath = null,
	bool SkipXmlValidation = false,
	bool SkipYamlValidation = false,
	bool ForceOverwrite = false,
	bool DetailedOutput = false
);
