using NMYAML.Core.Models;

namespace NMYAML.Core.Utilities;

public static class ValidationExtensions
{
	/// <summary>
	/// Materializes an IAsyncEnumerable of ValidationResult into a List for scenarios where all results are needed
	/// </summary>
	public static async Task<List<ValidationResult>> ToListAsync(this IAsyncEnumerable<ValidationResult> source)
	{
		var results = new List<ValidationResult>();
		await foreach (var result in source)
		{
			results.Add(result);
		}

		return results;
	}

	/// <summary>
	/// Creates a ValidationSummary and materializes results from an IAsyncEnumerable
	/// </summary>
	public static async Task<(List<ValidationResult> Results, ValidationSummary Summary)> MaterializeWithSummaryAsync(
		this IAsyncEnumerable<ValidationResult> source,
		TimeSpan duration)
	{
		var results = await source.ToListAsync();
		var summary = ValidationSummary.FromResults(results, duration);
		return (results, summary);
	}
}
