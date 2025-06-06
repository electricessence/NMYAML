using NMYAML.CLI.Commands;
using NMYAML.CLI.Commands.Schema;
using NMYAML.CLI.Commands.Yaml;
using Spectre.Console.Cli;

var app = new CommandApp();

app.Configure(config =>
{
	config.SetApplicationName("nmyaml");
	config.SetApplicationVersion("1.0.0");

	// Add logo and description
	config.Settings.ApplicationName = "NMYAML";
	config.Settings.ApplicationVersion = "1.0.0";

	// Add commands
	config.AddCommand<TransformCommand>("transform")
		.WithAlias("t")
		.WithDescription("Transform XML workflow to YAML");

	config.AddCommand<ValidateCommand>("validate")
		.WithAlias("v")
		.WithDescription("Validate XML against XSD schema or YAML syntax");

	config.AddCommand<ConvertCommand>("convert")
		.WithAlias("c")
		.WithDescription("Complete XML-to-YAML conversion with validation");

	config.AddBranch("schema", schema =>
	{
		schema.SetDescription("Schema operations");
		schema.AddCommand<SchemaValidateCommand>("validate")
			.WithAlias("v")
			.WithDescription("Validate XML against XSD schema");
	});

	config.AddBranch("yaml", yaml =>
	{
		yaml.SetDescription("YAML operations");
		yaml.AddCommand<YamlValidateCommand>("validate")
			.WithAlias("v")
			.WithDescription("Validate YAML syntax and GitHub Actions structure");
		yaml.AddCommand<YamlFormatCommand>("format")
			.WithAlias("f")
			.WithDescription("Format and clean YAML files");
	});

	// Global error handling
	config.PropagateExceptions();
	config.ValidateExamples();
});

try
{
	return app.Run(args);
}
catch (Exception ex)
{
	AnsiConsole.WriteException(ex, ExceptionFormats.ShortenEverything);
	return 1;
}
