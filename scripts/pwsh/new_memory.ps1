param(
  [Alias('h')][switch]$Help,
  [string]$Path,
  [string[]]$Related = @(),
  [string[]]$Tag = @()
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'workflow_utils.ps1')

function Show-Usage {
  Write-Output 'Usage:'
  Write-Output '  new_memory.ps1 [-Path PATH] [-Related UUID|JSON_ARRAY]... [-Tag TAG|JSON_ARRAY]...'
  Write-Output '  new_memory.ps1 -Help'
  Write-Output ''
  Write-Output 'Reads body from stdin, prepends:'
  Write-Output '  guid: <uuid>'
  Write-Output '  related: [...]'
  Write-Output '  tags: [...]'
}

if ($Help) { Show-Usage; exit 0 }

$relatedItems = [System.Collections.Generic.List[string]]::new()
$tagItems = [System.Collections.Generic.List[string]]::new()
foreach ($item in $Related) { Add-ShellGhostItem -Target $relatedItems -Raw $item }
foreach ($item in $Tag) { Add-ShellGhostItem -Target $tagItems -Raw $item }

$outPath = ''
if ($Path) {
  $rootPrefix = Get-ShellGhostWorkspaceRoot
  $allowedRoots = Get-ShellGhostAllowedRoots $rootPrefix
  $outPath = Resolve-ShellGhostMemoryPath -Path $Path -RootPrefix $rootPrefix -AllowedRoots $allowedRoots
}

$guid = New-ShellGhostGuid
$relatedYaml = Format-ShellGhostList ($relatedItems.ToArray())
$tagsYaml = Format-ShellGhostList ($tagItems.ToArray())
$body = $input | Out-String
$content = "guid: $guid`nrelated: $relatedYaml`ntags: $tagsYaml`n`n$body"

if ($outPath) {
  $dir = Split-Path -Parent $outPath
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  [System.IO.File]::WriteAllText($outPath, $content, [System.Text.UTF8Encoding]::new($false))
} else {
  Write-Output $content
}
