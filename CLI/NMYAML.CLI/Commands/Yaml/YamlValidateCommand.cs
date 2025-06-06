using NMYAML.Core.Models;
using NMYAML.CLI.Utilities;
using NMYAML.Core.Validators;
using Spectre.Console.Cli;
using System.ComponentModel;
using System.Diagnostics;
using System.Text.Json;

namespace NMYAML.CLI.Commands.Yaml;

[Description("Validate YAML file syntax and structure")]
public class YamlValidateCommand : AsyncCommand<YamlValidateSettings>
{
	private readonly ValidationResultsDisplay _resultsDisplay;

	public YamlValidateCommand()
	{
		var console = AnsiConsole.Console;
		_resultsDisplay = new ValidationResultsDisplay(console);
	}

	public override async Task<int> ExecuteAsync(CommandContext context, YamlValidateSettings settings)
	{
		var stopwatch = Stopwatch.StartNew();

		try
		{
			// Configure console colors
			if (settings.NoColor)
			{
				AnsiConsole.Profile.Capabilities.ColorSystem = ColorSystem.NoColors;
			}

			// Validate file exists
			if (!File.Exists(settings.YamlPath))
			{
				AnsiConsole.MarkupLine($"[red]Error: YAML file not found: {settings.YamlPath}[/]");
				return 1;
			}

			if (settings.Verbose)
			{
				AnsiConsole.MarkupLine($"[blue]Validating YAML: {settings.YamlPath}[/]");
				if (settings.GitHubActions)
				{
					AnsiConsole.MarkupLine("[blue]Using GitHub Actions specific validation[/]");
				}

				AnsiConsole.WriteLine();
			}

			var results = new List<ValidationResult>();

			// Perform validation
			await AnsiConsole.Status()
				.StartAsync("Validating YAML file...", async ctx =>
				{
					await foreach (var result in YAML.ValidateAsync(settings.YamlPath))
					{
						results.Add(result);
						if (settings.Verbose)
						{
							var color = result.Severity switch
							{
								ValidationSeverity.Error => "red",
								ValidationSeverity.Warning => "yellow",
								ValidationSeverity.Info => "blue",
								_ => "white"
							};
							AnsiConsole.MarkupLine($"  [{color}]{result.Type}: {result.Message.EscapeMarkup()}[/]");
						}
					}
				});

			stopwatch.Stop();
			var summary = ValidationSummary.FromResults(results, stopwatch.Elapsed);

			// Display results
			AnsiConsole.WriteLine();
			AnsiConsole.MarkupLine("[yellow]YAML Validation Results[/]");
			_resultsDisplay.DisplayResults(results, summary, settings.Detailed);

			// Export report if requested
			if (settings.ExportReport)
			{
				await ExportValidationReport(results, summary, settings.YamlPath);
			}

			// Final status
			if (summary.Errors > 0)
			{
				AnsiConsole.WriteLine();
				AnsiConsole.MarkupLine($"[red]❌ Validation failed with {summary.Errors} errors[/]");
				return 1;
			}
			else if (summary.Warnings > 0)
			{
				AnsiConsole.WriteLine();
				AnsiConsole.MarkupLine($"[yellow]⚠️  Validation passed with {summary.Warnings} warnings[/]");
			}
			else
			{
				AnsiConsole.WriteLine();
				AnsiConsole.MarkupLine("[green]✅ YAML validation passed successfully[/]");
			}

			return 0;
		}
		catch (Exception ex)
		{
			AnsiConsole.MarkupLine($"[red]Error: {ex.Message.EscapeMarkup()}[/]");
			if (settings.Verbose)
			{
				AnsiConsole.WriteException(ex);
			}

			return 1;
		}
	}

	private static readonly JsonSerializerOptions CachedJsonOptions = new()
	{
		WriteIndented = true,
		PropertyNamingPolicy = JsonNamingPolicy.CamelCase
	};

	private static async Task ExportValidationReport(List<ValidationResult> results, ValidationSummary summary, string yamlPath)
	{
		var reportPath = $"validation-report-{DateTime.Now:yyyyMMdd-HHmmss}.json";

		var report = new
		{
			file = yamlPath,
			timestamp = DateTime.UtcNow,
			summary = new
			{
				totalIssues = summary.TotalIssues,
				errors = summary.Errors,
				warnings = summary.Warnings,
				info = summary.Info,
				isValid = summary.IsValid,
				duration = summary.Duration.TotalMilliseconds
			},
			results = results.Select(r => new
			{
				type = r.Type,
				severity = r.Severity.ToString(),
				message = r.Message,
				lineNumber = r.LineNumber,
				context = r.Context
			}).ToArray()
		};

		var json = JsonSerializer.Serialize(report, CachedJsonOptions);
		await File.WriteAllTextAsync(reportPath, json);

		AnsiConsole.MarkupLine($"[blue]📄 Validation report exported to: {reportPath}[/]");
	}
}
