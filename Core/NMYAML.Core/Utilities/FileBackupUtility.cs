using System;
using System.IO;

namespace NMYAML.Core.Utilities;

/// <summary>
/// Utility for creating automatic backups of existing files
/// </summary>
public static class FileBackupUtility
{
    /// <summary>
    /// Creates a backup of an existing file if it exists, with timestamp
    /// </summary>
    /// <param name="filePath">Path to the file to backup</param>
    /// <returns>Path to the backup file if created, null if original file didn't exist</returns>
    public static string? CreateBackupIfExists(string filePath)
    {
        if (!File.Exists(filePath))
            return null;

        var directory = Path.GetDirectoryName(filePath) ?? string.Empty;
        var fileName = Path.GetFileNameWithoutExtension(filePath);
        var extension = Path.GetExtension(filePath);
        var timestamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
        
        var backupPath = Path.Combine(directory, $"{fileName}{extension}.{timestamp}.bak");
        
        // Ensure we don't overwrite an existing backup (in case of rapid successive calls)
        var counter = 1;
        var originalBackupPath = backupPath;
        while (File.Exists(backupPath))
        {
            backupPath = Path.Combine(directory, $"{fileName}{extension}.{timestamp}-{counter:D2}.bak");
            counter++;
        }
        
        File.Copy(filePath, backupPath);
        return backupPath;
    }

    /// <summary>
    /// Creates a backup with a custom suffix instead of timestamp
    /// </summary>
    /// <param name="filePath">Path to the file to backup</param>
    /// <param name="suffix">Custom suffix for the backup file</param>
    /// <returns>Path to the backup file if created, null if original file didn't exist</returns>
    public static string? CreateBackupWithSuffix(string filePath, string suffix)
    {
        if (!File.Exists(filePath))
            return null;

        var directory = Path.GetDirectoryName(filePath) ?? string.Empty;
        var fileName = Path.GetFileNameWithoutExtension(filePath);
        var extension = Path.GetExtension(filePath);
        
        var backupPath = Path.Combine(directory, $"{fileName}{extension}.{suffix}.bak");
        
        // Ensure we don't overwrite an existing backup
        var counter = 1;
        while (File.Exists(backupPath))
        {
            backupPath = Path.Combine(directory, $"{fileName}{extension}.{suffix}-{counter:D2}.bak");
            counter++;
        }
        
        File.Copy(filePath, backupPath);
        return backupPath;
    }

    /// <summary>
    /// Handles file output with automatic backup if file exists and overwrite is false
    /// </summary>
    /// <param name="outputPath">Path where output will be written</param>
    /// <param name="overwrite">If true, overwrite without backup. If false, create backup first.</param>
    /// <returns>Information about the backup operation</returns>
    public static BackupResult HandleOutputFile(string outputPath, bool overwrite = false)
    {
        if (!File.Exists(outputPath))
        {
            return new BackupResult { ShouldProceed = true, BackupCreated = false };
        }

        if (overwrite)
        {
            return new BackupResult { ShouldProceed = true, BackupCreated = false };
        }

        // Create backup
        var backupPath = CreateBackupIfExists(outputPath);
        return new BackupResult 
        { 
            ShouldProceed = true, 
            BackupCreated = true, 
            BackupPath = backupPath 
        };
    }
}

/// <summary>
/// Result of backup operation
/// </summary>
public class BackupResult
{
    /// <summary>
    /// Whether the operation should proceed
    /// </summary>
    public bool ShouldProceed { get; set; }
    
    /// <summary>
    /// Whether a backup was created
    /// </summary>
    public bool BackupCreated { get; set; }
    
    /// <summary>
    /// Path to the backup file (if created)
    /// </summary>
    public string? BackupPath { get; set; }
}
