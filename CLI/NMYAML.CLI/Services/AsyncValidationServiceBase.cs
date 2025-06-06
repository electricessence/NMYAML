using NMYAML.CLI.Models;

namespace NMYAML.CLI.Services;

/// <summary>
/// Base class for async validation services that provides a common pattern for validation
/// </summary>
/// <typeparam name="T">The type of object being validated</typeparam>
public abstract class AsyncValidationServiceBase<T>
{
	/// <summary>
	/// Validates an object and returns only failed validation results
	/// </summary>
	/// <param name="item">The item to validate</param>
	/// <returns>An async enumerable of validation failures (null results are filtered out)</returns>
	public async IAsyncEnumerable<ValidationResult> ValidateAsync(T item)
	{
		await foreach (var result in AsyncValidations(item))
		{
			if (result is not null)
			{
				yield return result;
			}
		}
	}

	/// <summary>
	/// Performs the actual validation logic. Return null for success, ValidationResult for failures.
	/// </summary>
	/// <param name="item">The item to validate</param>
	/// <returns>An async enumerable where null means success and ValidationResult means failure</returns>
	protected abstract IAsyncEnumerable<ValidationResult?> AsyncValidations(T item);

	/// <summary>
	/// Validates that XML file exists
	/// </summary>
	protected ValidationResult? ValidateFileExists(string path, string description)
		=> File.Exists(path) ? null : new ValidationResult(
			"File", ValidationSeverity.Error, $"{description} file not found");
}
