using NMYAML.Core.Models;

namespace NMYAML.CLI.Utilities;

/// <summary>
/// Utility for displaying validation results in the console
/// </summary>
/// <remarks>
/// Initializes a new instance of the ValidationResultsDisplay
/// </remarks>
/// <param name="console">The console to display output to</param>
public class ValidationResultsDisplay(IAnsiConsole console)
{
	/// <summary>
	/// Displays validation results in a formatted table with optional detailed output
	/// </summary>
	/// <param name="results">The validation results to display</param>
	/// <param name="summary">Summary statistics of the validation</param>
	/// <param name="detailed">Whether to show detailed issue information</param>
	public void DisplayResults(IEnumerable<ValidationResult> results, ValidationSummary summary, bool detailed = false)
	{
		var table = new Table()
			.AddColumn("Category")
			.AddColumn("Count")
			.Border(TableBorder.Rounded);

		table.AddRow("Total Issues", summary.TotalIssues.ToString());
		table.AddRow("[red]Errors[/]", summary.Errors.ToString());
		table.AddRow("[yellow]Warnings[/]", summary.Warnings.ToString());
		table.AddRow("[blue]Info[/]", summary.Info.ToString());
		table.AddRow("Duration", $"{summary.Duration.TotalMilliseconds:F0}ms");

		console.Write(table);

		if (detailed && results.Any())
		{
			console.WriteLine();
			console.Write(new Rule("[yellow]Detailed Issues[/]"));

			foreach (var group in results.GroupBy(r => r.Type))
			{
				console.WriteLine();
				console.MarkupLine($"[bold]{group.Key}[/]");

				foreach (var result in group.OrderBy(r => r.LineNumber))
				{
					var color = result.Severity switch
					{
						ValidationSeverity.Error => "red",
						ValidationSeverity.Warning => "yellow",
						ValidationSeverity.Info => "blue",
						_ => "white"
					};

					console.MarkupLine($"  [{color}]Line {result.LineNumber}: {result.Message.EscapeMarkup()}[/]");
					if (!string.IsNullOrEmpty(result.Context?.ToString()))
					{
						console.MarkupLine($"    [dim]{result.Context.ToString()?.EscapeMarkup()}[/]");
					}
				}
			}
		}
	}

	/// <summary>
	/// Displays a simplified validation summary in a formatted table
	/// </summary>
	/// <param name="summary">The validation summary to display</param>
	public void DisplaySummary(ValidationSummary summary)
	{
		var table = new Table()
			.AddColumn("Metric")
			.AddColumn("Count")
			.Border(TableBorder.Simple);

		table.AddRow("Total Issues", summary.TotalIssues.ToString());

		if (summary.Errors > 0)
			table.AddRow("[red]Errors[/]", summary.Errors.ToString());

		if (summary.Warnings > 0)
			table.AddRow("[yellow]Warnings[/]", summary.Warnings.ToString());

		if (summary.Info > 0)
			table.AddRow("[blue]Info[/]", summary.Info.ToString());

		table.AddRow("Valid", summary.IsValid ? "[green]Yes[/]" : "[red]No[/]");
		table.AddRow("Duration", $"{summary.Duration.TotalMilliseconds:F0}ms");

		console.Write(table);
	}
}