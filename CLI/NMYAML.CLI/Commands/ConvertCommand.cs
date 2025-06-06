using NMYAML.Core.Models;
using NMYAML.Core.Services;
using NMYAML.Core.Utilities;
using NMYAML.CLI.Utilities;
using Spectre.Console.Cli;
using System.ComponentModel;

namespace NMYAML.CLI.Commands;

[Description("Convert XML to YAML with full validation pipeline")]
public class ConvertCommand : AsyncCommand<ConvertSettings>
{
	private readonly XmlTransformationService _transformationService;
	private readonly ValidationResultsDisplay _resultsDisplay;

	public ConvertCommand()
	{
		var console = AnsiConsole.Console;
		_transformationService = new XmlTransformationService();
		_resultsDisplay = new ValidationResultsDisplay(console);
	}

	public override async Task<int> ExecuteAsync(CommandContext context, ConvertSettings settings)
	{
		try
		{			// Configure console colors
			if (settings.NoColor)
			{
				AnsiConsole.Profile.Capabilities.ColorSystem = ColorSystem.NoColors;
			}
			
			// Create conversion options
			var options = new ConversionOptions(
				InputPath: settings.InputPath,
				OutputPath: settings.OutputPath,
				XsdSchemaPath: settings.SchemaPath ?? GetDefaultSchemaPath(),
				XsltPath: settings.XsltPath ?? GetDefaultXsltPath(),
				SkipXmlValidation: settings.SkipXmlValidation,
				SkipYamlValidation: settings.SkipYamlValidation,
				ForceOverwrite: settings.Overwrite,
				DetailedOutput: settings.DetailedOutput
			);			// Handle output file backup/overwrite
			var backupResult = FileBackupUtility.HandleOutputFile(settings.OutputPath, settings.Overwrite);
			if (!backupResult.ShouldProceed)
			{
				AnsiConsole.MarkupLine("[yellow]Operation cancelled.[/]");
				return 0;
			}
			
			if (backupResult.BackupCreated && backupResult.BackupPath != null)
			{
				AnsiConsole.MarkupLine($"[yellow]Existing file backed up to: {Path.GetFileName(backupResult.BackupPath)}[/]");
			}

			if (settings.Verbose)
			{
				AnsiConsole.MarkupLine("[blue]Conversion Configuration:[/]");
				AnsiConsole.MarkupLine($"  Input:  {options.InputPath}");
				AnsiConsole.MarkupLine($"  Output: {options.OutputPath}");
				AnsiConsole.MarkupLine($"  Schema: {options.XsdSchemaPath}");
				AnsiConsole.MarkupLine($"  XSLT:   {options.XsltPath}");
				AnsiConsole.WriteLine();
			}

			// Perform full transformation with validation
			var result = await XmlTransformationService.TransformAsync(options);

			if (result.Success)
			{
				AnsiConsole.MarkupLine("[green]✅ Conversion completed successfully![/]");
				AnsiConsole.MarkupLine($"[blue]Output file:[/] {result.OutputPath}");
				AnsiConsole.MarkupLine($"[dim]Duration: {result.Duration.TotalMilliseconds:F0}ms[/]");

				// Show validation summaries if available
				if (result.XmlValidation != null)
				{
					AnsiConsole.WriteLine();
					AnsiConsole.MarkupLine("[yellow]XML Validation Summary:[/]");
					_resultsDisplay.DisplaySummary(result.XmlValidation);
				}

				if (result.YamlValidation != null)
				{
					AnsiConsole.WriteLine();
					AnsiConsole.MarkupLine("[yellow]YAML Validation Summary:[/]");
					_resultsDisplay.DisplaySummary(result.YamlValidation);
				}

				return 0;
			}
			else
			{
				AnsiConsole.MarkupLine("[red]❌ Conversion failed![/]");
				if (!string.IsNullOrEmpty(result.ErrorMessage))
				{
					AnsiConsole.MarkupLine($"[red]Error: {result.ErrorMessage.EscapeMarkup()}[/]");
				}

				return 1;
			}
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
