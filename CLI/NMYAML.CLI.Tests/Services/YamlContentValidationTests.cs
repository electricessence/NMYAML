using NMYAML.CLI.Models;
using NMYAML.CLI.Services;
using System.Threading.Tasks;
using Xunit;

namespace NMYAML.CLI.Tests.Services;

public class YamlContentValidationTests
{
    [Fact]
    public async Task ValidateContentAsync_ValidYaml_ReturnsNoErrors()
    {
        // Arrange
        var validYaml = """
            name: Test Workflow
            on:
              push:
                branches: [ main ]
            
            jobs:
              build:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v3
                  - name: Build
                    run: |
                      echo Building...
                      echo Done!
            """;

        // Act
        var results = await YamlValidationService.Instance.ValidateContentAsync(validYaml).ToListAsync();

        // Assert
        Assert.Empty(results); // No validation errors for valid YAML
    }

    [Fact]
    public async Task ValidateContentAsync_InvalidYaml_ReturnsError()
    {
        // Arrange
        var invalidYaml = """
            name: Test Workflow
            on:
              push:
                branches: [ main
            
            jobs:
              build:
                runs-on: ubuntu-latest
            """; // Missing closing bracket

        // Act
        var results = await YamlValidationService.Instance.ValidateContentAsync(invalidYaml).ToListAsync();

        // Assert
        Assert.NotEmpty(results);
        Assert.Contains(results, r => r.Type == "Syntax" && r.Severity == ValidationSeverity.Error);
    }

    [Fact]
    public async Task ValidateContentAsync_EmptyYaml_ReturnsError()
    {
        // Arrange
        var emptyYaml = "";

        // Act
        var results = await YamlValidationService.Instance.ValidateContentAsync(emptyYaml).ToListAsync();

        // Assert
        Assert.NotEmpty(results);
        Assert.Contains(results, r => r.Type == "Syntax" && r.Severity == ValidationSeverity.Error);
        Assert.Contains(results, r => r.Message == "YAML content is empty");
    }
}