using NMYAML.CLI.Models;
using NMYAML.CLI.Services;
using NMYAML.CLI.Utilities;
using Spectre.Console.Cli;
using System.ComponentModel;
using System.Diagnostics;

namespace NMYAML.CLI.Commands;

[Description("Transform XML to YAML using XSLT")]
public class TransformCommand : AsyncCommand<TransformSettings>
{
	private readonly XmlTransformationService _transformer;
	private readonly ValidationResultsDisplay _resultsDisplay;

	public TransformCommand()
	{
		var console = AnsiConsole.Console;
		_transformer = new XmlTransformationService();
		_resultsDisplay = new ValidationResultsDisplay(console);
	}

	public override async Task<int> ExecuteAsync(CommandContext context, TransformSettings settings)
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
			if (!File.Exists(settings.InputPath))
			{
				AnsiConsole.MarkupLine($"[red]Error: Input file not found: {settings.InputPath}[/]");
				return 1;
			}

			// Check if output file exists and handle force overwrite
			if (File.Exists(settings.OutputPath) && !settings.ForceOverwrite)
			{
				if (!AnsiConsole.Confirm($"Output file exists: {settings.OutputPath}. Overwrite?"))
				{
					AnsiConsole.MarkupLine("[yellow]Operation cancelled.[/]");
					return 0;
				}
			}

			// Create output directory if it doesn't exist
			var outputDir = Path.GetDirectoryName(settings.OutputPath);
			if (!string.IsNullOrEmpty(outputDir) && !Directory.Exists(outputDir))
			{
				Directory.CreateDirectory(outputDir);
			}

			// Determine XSD schema path
			var xsdPath = GetDefaultSchemaPath();
			if (settings.Verbose)
			{
				AnsiConsole.MarkupLine($"[blue]Using XSD schema: {xsdPath}[/]");
			}

			// Step 1: Validate XML against XSD schema
			var xmlValidationResults = new List<ValidationResult>();
			await AnsiConsole.Status()
				.StartAsync("Validating XML against schema...", async ctx =>
				{
					var xmlValidationStart = Stopwatch.StartNew();

					await foreach (var result in XmlValidationService.Instance.ValidateAsync(settings.InputPath, xsdPath))
					{
						xmlValidationResults.Add(result);
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

					xmlValidationStart.Stop();
					var xmlSummary = ValidationSummary.FromResults(xmlValidationResults, xmlValidationStart.Elapsed);

					if (xmlSummary.Errors > 0)
					{
						AnsiConsole.MarkupLine($"[red]XML validation failed with {xmlSummary.Errors} errors[/]");
						_resultsDisplay.DisplayResults(xmlValidationResults, xmlSummary, settings.Verbose);
						throw new InvalidOperationException("XML validation failed");
					}

					if (settings.Verbose && xmlSummary.TotalIssues > 0)
					{
						_resultsDisplay.DisplayResults(xmlValidationResults, xmlSummary, true);
					}
				});

			// Step 2: Transform XML to YAML
			string? yamlContent = null;
			await AnsiConsole.Status()
				.StartAsync("Transforming XML to YAML...", async ctx =>
				{
					var xsltPath = settings.XsltPath ?? GetDefaultXsltPath();
					if (settings.Verbose)
					{
						AnsiConsole.MarkupLine($"[blue]Using XSLT transform: {xsltPath}[/]");
					}

					yamlContent = XmlTransformationService.TransformAsync(settings.InputPath, xsltPath);
					await Task.CompletedTask; // Make this properly async
				});

			if (string.IsNullOrEmpty(yamlContent))
			{
				AnsiConsole.MarkupLine("[red]Failed to transform XML to YAML[/]");
				return 1;
			}

			// Step 3: Write YAML output
			await File.WriteAllTextAsync(settings.OutputPath, yamlContent);

			// Step 4: Validate generated YAML
			var yamlValidationResults = new List<ValidationResult>();
			await AnsiConsole.Status()
				.StartAsync("Validating generated YAML...", async ctx =>
				{
					var yamlValidationStart = Stopwatch.StartNew();

					await foreach (var result in YamlValidationService.Instance.ValidateAsync(settings.OutputPath))
					{
						yamlValidationResults.Add(result);
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

					yamlValidationStart.Stop();
					var yamlSummary = ValidationSummary.FromResults(yamlValidationResults, yamlValidationStart.Elapsed);

					if (settings.Verbose && yamlSummary.TotalIssues > 0)
					{
						_resultsDisplay.DisplayResults(yamlValidationResults, yamlSummary, true);
					}

					if (yamlSummary.Errors > 0)
					{
						AnsiConsole.MarkupLine($"[yellow]Warning: Generated YAML has {yamlSummary.Errors} errors[/]");
					}
				});

			stopwatch.Stop();

			// Success message
			AnsiConsole.MarkupLine($"[green]✓[/] Successfully transformed XML to YAML");
			AnsiConsole.MarkupLine($"[blue]Input:[/]  {settings.InputPath}");
			AnsiConsole.MarkupLine($"[blue]Output:[/] {settings.OutputPath}");
			AnsiConsole.MarkupLine($"[dim]Completed in {stopwatch.ElapsedMilliseconds}ms[/]");

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

	private static string GetDefaultSchemaPath()
	{
		var baseDir = AppDomain.CurrentDomain.BaseDirectory;
		return Path.Combine(baseDir, "github-actions-schema.xsd");
	}

	private static string GetDefaultXsltPath()
	{
		var baseDir = AppDomain.CurrentDomain.BaseDirectory;
		return Path.Combine(baseDir, "github-actions-transform.xslt");
	}
}
