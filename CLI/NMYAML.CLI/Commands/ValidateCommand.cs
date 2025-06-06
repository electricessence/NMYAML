using NMYAML.CLI.Models;
using NMYAML.CLI.Services;
using NMYAML.CLI.Utilities;
using Spectre.Console.Cli;
using System.ComponentModel;
using System.Diagnostics;

namespace NMYAML.CLI.Commands;

[Description("Validate XML or YAML files")]
public class ValidateCommand : AsyncCommand<ValidateSettings>
{
	private readonly ValidationResultsDisplay _resultsDisplay;

	public ValidateCommand()
	{
		var console = AnsiConsole.Console;
		_resultsDisplay = new ValidationResultsDisplay(console);
	}

	public override async Task<int> ExecuteAsync(CommandContext context, ValidateSettings settings)
	{
		var stopwatch = Stopwatch.StartNew();

		try
		{
			// Configure console colors
			if (settings.NoColor)
			{
				AnsiConsole.Profile.Capabilities.ColorSystem = ColorSystem.NoColors;
			}

			// Validate input file exists
			if (!File.Exists(settings.FilePath))
			{
				AnsiConsole.MarkupLine($"[red]Error: File not found: {settings.FilePath}[/]");
				return 1;
			}

			var fileExt = Path.GetExtension(settings.FilePath).ToLowerInvariant();
			var results = new List<ValidationResult>();
			ValidationSummary summary;			if (fileExt == ".xml")
			{
				// XML Validation
				var schemaPath = settings.SchemaPath;
				if (settings.Verbose)
				{
					AnsiConsole.MarkupLine($"[blue]Validating XML file: {settings.FilePath}[/]");
					if (schemaPath != null)
					{
						AnsiConsole.MarkupLine($"[blue]Using XSD schema: {schemaPath}[/]");
					}
					else
					{
						AnsiConsole.MarkupLine($"[blue]Validating XML syntax only (no schema provided)[/]");
					}
				}

				await AnsiConsole.Status()
					.StartAsync("Validating XML...", async ctx =>
					{
						await foreach (var result in XmlValidationService.Instance.ValidateAsync(settings.FilePath, schemaPath))
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
				summary = ValidationSummary.FromResults(results, stopwatch.Elapsed);

				AnsiConsole.MarkupLine($"[blue]XML Validation Results[/]");
				_resultsDisplay.DisplayResults(results, summary, settings.Detailed);
			}
			else if (fileExt is ".yml" or ".yaml")
			{
				// YAML Validation
				if (settings.Verbose)
				{
					AnsiConsole.MarkupLine($"[blue]Validating YAML file: {settings.FilePath}[/]");
				}

				await AnsiConsole.Status()
					.StartAsync("Validating YAML...", async ctx =>
					{
						await foreach (var result in YamlValidationService.Instance.ValidateAsync(settings.FilePath))
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
				summary = ValidationSummary.FromResults(results, stopwatch.Elapsed);
				AnsiConsole.MarkupLine($"[blue]YAML Validation Results[/]");
				_resultsDisplay.DisplayResults(results, summary, settings.Detailed);
			}
			else
			{
				AnsiConsole.MarkupLine($"[red]Error: Unsupported file type: {fileExt}[/]");
				AnsiConsole.MarkupLine("[yellow]Supported extensions: .xml, .yml, .yaml[/]");
				return 1;
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
				AnsiConsole.MarkupLine("[green]✅ Validation passed successfully[/]");
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

			return 1;		}
	}
}
