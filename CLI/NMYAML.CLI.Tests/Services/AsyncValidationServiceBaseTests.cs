using NMYAML.CLI.Models;
using NMYAML.CLI.Services;

namespace NMYAML.CLI.Tests;

public class AsyncValidationServiceBaseTests
{
	private class TestInput
	{
		public string? Value { get; set; }
	}

	private class TestValidationService(IEnumerable<ValidationResult?> results) : AsyncValidationServiceBase<TestInput>
	{
		protected override async IAsyncEnumerable<ValidationResult?> AsyncValidations(TestInput item)
		{
			foreach (var result in results)
			{
				yield return result;
				await Task.Yield();
			}
		}

		public ValidationResult? TestValidateFileExists(string path, string description)
		{
			return ValidateFileExists(path, description);
		}
	}

	[Fact]
	public async Task ValidateAsync_FiltersNullResults()
	{
		// Arrange
		var results = new ValidationResult?[]
		{
			new("Test", ValidationSeverity.Error, "Error 1"),
			null,
			new("Test", ValidationSeverity.Warning, "Warning 1"),
			null,
			new("Test", ValidationSeverity.Info, "Info 1")
		};

		var service = new TestValidationService(results);

		// Act
		var actualResults = await service.ValidateAsync(new TestInput()).ToListAsync();

		// Assert
		Assert.Equal(3, actualResults.Count);
		Assert.Equal("Error 1", actualResults[0].Message);
		Assert.Equal("Warning 1", actualResults[1].Message);
		Assert.Equal("Info 1", actualResults[2].Message);
	}

	[Fact]
	public void ValidateFileExists_FileExistsReturnsNull()
	{
		// Arrange
		var service = new TestValidationService([]);
		var tempFile = Path.GetTempFileName();

		try
		{
			// Act
			var result = service.TestValidateFileExists(tempFile, "Test");

			// Assert
			Assert.Null(result);
		}
		finally
		{
			if (File.Exists(tempFile))
			{
				File.Delete(tempFile);
			}
		}
	}

	[Fact]
	public void ValidateFileExists_FileDoesNotExistReturnsError()
	{
		// Arrange
		var service = new TestValidationService([]);
		var nonExistentPath = Path.Combine(Path.GetTempPath(), $"nonexistent-{Guid.NewGuid()}");

		// Act
		var result = service.TestValidateFileExists(nonExistentPath, "Test");

		// Assert
		Assert.NotNull(result);
		Assert.Equal("File", result.Type);
		Assert.Equal(ValidationSeverity.Error, result.Severity);
		Assert.Equal("Test file not found", result.Message);
	}
}