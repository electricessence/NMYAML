using Spectre.Console.Cli;
using System.ComponentModel;
using System.Diagnostics;
using YamlDotNet.Core;
using YamlDotNet.Serialization;

namespace NMYAML.CLI.Commands.Yaml;

[Description("Format and normalize YAML file")]
public class YamlFormatCommand : AsyncCommand<YamlFormatSettings>
{
	public override async Task<int> ExecuteAsync(CommandContext context, YamlFormatSettings settings)
	{
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

			var outputPath = settings.OutputPath ?? settings.YamlPath;

			if (settings.Verbose)
			{
				AnsiConsole.MarkupLine($"[blue]Formatting YAML: {settings.YamlPath}[/]");
				AnsiConsole.MarkupLine($"[blue]Output: {outputPath}[/]");
				AnsiConsole.MarkupLine($"[blue]Indent size: {settings.IndentSize}[/]");
				AnsiConsole.WriteLine();
			}

			// Read and parse YAML
			var yamlContent = await File.ReadAllTextAsync(settings.YamlPath);
			string? formattedYaml = null;

			await AnsiConsole.Status()
				.StartAsync("Formatting YAML...", async ctx =>
				{
					// Parse and reformat YAML
					var deserializer = new DeserializerBuilder()
						.IgnoreUnmatchedProperties()
						.Build();

					var serializer = new SerializerBuilder()
						.WithIndentedSequences()
						.ConfigureDefaultValuesHandling(DefaultValuesHandling.OmitDefaults)
						.Build();

					try
					{
						// Deserialize to object
						var yamlObject = deserializer.Deserialize(yamlContent);

						// Serialize back with proper formatting
						formattedYaml = serializer.Serialize(yamlObject);

						// Apply custom formatting rules
						formattedYaml = ApplyFormatting(formattedYaml, settings.IndentSize);
					}
					catch (YamlException ex)
					{
						throw new InvalidOperationException($"YAML parsing error: {ex.Message}", ex);
					}

					await Task.CompletedTask;
				});

			Debug.Assert(formattedYaml is not null);
			// Show differences if dry run
			if (settings.DryRun)
			{
				AnsiConsole.MarkupLine("[yellow]Dry run - showing changes that would be made:[/]");
				AnsiConsole.WriteLine();

				// Show a simple diff
				var originalLines = yamlContent.Split('\n');
				var formattedLines = formattedYaml.Split('\n');

				if (originalLines.Length != formattedLines.Length ||
					!originalLines.SequenceEqual(formattedLines))
				{
					AnsiConsole.MarkupLine("[yellow]File would be changed[/]");

					if (settings.Verbose)
					{
						AnsiConsole.WriteLine();
						AnsiConsole.MarkupLine("[dim]--- Original[/]");
						AnsiConsole.MarkupLine("[dim]+++ Formatted[/]");

						for (int i = 0; i < Math.Max(originalLines.Length, formattedLines.Length); i++)
						{
							var original = i < originalLines.Length ? originalLines[i] : "";
							var formatted = i < formattedLines.Length ? formattedLines[i] : "";

							if (original != formatted)
							{
								if (!string.IsNullOrEmpty(original))
									AnsiConsole.MarkupLine($"[red]- {original.EscapeMarkup()}[/]");
								if (!string.IsNullOrEmpty(formatted))
									AnsiConsole.MarkupLine($"[green]+ {formatted.EscapeMarkup()}[/]");
							}
						}
					}
				}
				else
				{
					AnsiConsole.MarkupLine("[green]No changes needed - file is already properly formatted[/]");
				}

				return 0;
			}

			// Write formatted content
			await File.WriteAllTextAsync(outputPath, formattedYaml, Encoding.UTF8);

			AnsiConsole.MarkupLine("[green]✅ YAML file formatted successfully[/]");
			if (outputPath != settings.YamlPath)
			{
				AnsiConsole.MarkupLine($"[blue]Formatted file saved to: {outputPath}[/]");
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

	private static string ApplyFormatting(string yaml, int indentSize)
	{
		var lines = yaml.Split('\n');
		var result = new StringBuilder();

		foreach (var line in lines)
		{
			var trimmed = line.TrimStart();
			if (string.IsNullOrEmpty(trimmed))
			{
				result.AppendLine();
				continue;
			}

			// Calculate indentation level
			var originalIndent = line.Length - line.TrimStart().Length;
			var indentLevel = originalIndent / 2; // Assuming original uses 2-space indent
			var newIndent = new string(' ', indentLevel * indentSize);

			result.AppendLine(newIndent + trimmed);
		}

		return result.ToString().TrimEnd('\r', '\n') + "\n";
	}
}
