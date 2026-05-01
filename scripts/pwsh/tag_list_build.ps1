param(
  [string]$Root = '',
  [string]$Output = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'workflow_utils.ps1')

if (-not $Root) {
  $Root = Get-ShellGhostWorkspaceRoot
}

$allowedRoots = Get-ShellGhostAllowedRoots $Root
$tags = New-Object System.Collections.Generic.HashSet[string]
foreach ($file in (Get-ShellGhostMemoryFiles -RootPrefix $Root -AllowedRoots $allowedRoots)) {
  $fileTags = Get-ShellGhostTagsFromFile $file
  if ($null -eq $fileTags) { continue }
  foreach ($tag in $fileTags) { [void]$tags.Add($tag) }
}

$lines = @($tags | Sort-Object)
if ($Output) {
  [System.IO.File]::WriteAllText($Output, (($lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
} else {
  $lines | ForEach-Object { Write-Output $_ }
}
