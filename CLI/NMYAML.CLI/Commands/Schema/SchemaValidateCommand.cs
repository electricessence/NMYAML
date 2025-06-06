using NMYAML.CLI.Models;
using NMYAML.CLI.Utilities;
using NMYAML.CLI.Validators;
using Spectre.Console.Cli;
using System.ComponentModel;
using System.Diagnostics;

namespace NMYAML.CLI.Commands.Schema;

[Description("Validate XML file against XSD schema")]
public class SchemaValidateCommand : AsyncCommand<SchemaValidateSettings>
{
	private readonly ValidationResultsDisplay _resultsDisplay;

	public SchemaValidateCommand()
	{
		var console = AnsiConsole.Console;
		_resultsDisplay = new ValidationResultsDisplay(console);
	}

	public override async Task<int> ExecuteAsync(CommandContext context, SchemaValidateSettings settings)
	{
		var stopwatch = Stopwatch.StartNew();

		try
		{
			// Configure console colors
			if (settings.NoColor)
			{
				AnsiConsole.Profile.Capabilities.ColorSystem = ColorSystem.NoColors;
			}

			// Validate files exist
			if (!File.Exists(settings.XmlPath))
			{
				AnsiConsole.MarkupLine($"[red]Error: XML file not found: {settings.XmlPath}[/]");
				return 1;
			}

			if (!File.Exists(settings.SchemaPath))
			{
				AnsiConsole.MarkupLine($"[red]Error: Schema file not found: {settings.SchemaPath}[/]");
				return 1;
			}

			if (settings.Verbose)
			{
				AnsiConsole.MarkupLine($"[blue]Validating XML: {settings.XmlPath}[/]");
				AnsiConsole.MarkupLine($"[blue]Against schema: {settings.SchemaPath}[/]");
				AnsiConsole.WriteLine();
			}

			var results = new List<ValidationResult>();

			// Perform validation
			await AnsiConsole.Status()
				.StartAsync("Validating XML against schema...", async ctx =>
				{
					await foreach (var result in XML.ValidateAsync(settings.XmlPath, settings.SchemaPath))
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
			AnsiConsole.MarkupLine("[yellow]Schema Validation Results[/]");
			_resultsDisplay.DisplayResults(results, summary, settings.Detailed);

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
				AnsiConsole.MarkupLine("[green]✅ Schema validation passed successfully[/]");
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
}
