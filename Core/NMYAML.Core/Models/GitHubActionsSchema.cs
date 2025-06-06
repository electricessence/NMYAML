using System.Collections.Frozen;
using System.Collections.Immutable;

namespace NMYAML.CLI.Models;

public static class GitHubActionsSchema
{
	public static readonly FrozenSet<string> RequiredTopLevel =
	[
		"name", "on"
	];

	public static readonly FrozenSet<string> OptionalTopLevel =
	[
		"env", "defaults", "concurrency", "jobs", "permissions", "run-name"
	];

	public static readonly FrozenSet<string> JobProperties =
	[
		"runs-on", "steps", "needs", "if", "name", "permissions", "environment",
		"concurrency", "outputs", "env", "defaults", "timeout-minutes", "strategy",
		"continue-on-error", "container", "services"
	];

	public static readonly FrozenSet<string> StepProperties =
	[
		"name", "id", "if", "run", "uses", "with", "env", "continue-on-error",
		"timeout-minutes", "shell", "working-directory"
	];

	public static readonly FrozenSet<string> TriggerEvents =
	[
		"push", "pull_request", "pull_request_target", "workflow_dispatch", "workflow_call",
		"schedule", "repository_dispatch", "release", "issues", "issue_comment", "watch",
		"fork", "create", "delete", "deployment", "deployment_status", "page_build",
		"public", "status", "gollum", "member", "membership", "project", "project_card",
		"project_column", "milestone", "label", "discussion", "discussion_comment",
		"check_run", "check_suite"
	];

	public static readonly FrozenSet<string> RunnerLabels =
	[
		"ubuntu-latest", "ubuntu-20.04", "ubuntu-18.04", "ubuntu-22.04",
		"windows-latest", "windows-2022", "windows-2019",
		"macos-latest", "macos-12", "macos-11", "self-hosted"
	];

	public static readonly FrozenSet<string> Shells =
	[
		"bash", "pwsh", "powershell", "cmd", "sh", "python"
	];

	public static readonly ImmutableArray<string> SecurityPatterns =
	[
		@"secrets\.", @"\$\{\{\s*secrets\."
	];

	public static readonly FrozenSet<string> ReservedWords =
	[
		"env", "secrets", "github", "runner", "job", "steps", "matrix",
		"strategy", "needs", "inputs", "outputs"
	];
}
