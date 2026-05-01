param(
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Args
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'workflow_utils.ps1')

function Show-Usage {
  Write-Error 'Usage: tag_search.ps1 "tag1 && tag2 | tag3" or tag_search.ps1 --and|--or tag1 [tag2 ...]'
}

function Test-TagListContains([string[]]$Tags, [string]$Needle) {
  return $Tags -contains $Needle.ToLowerInvariant()
}

function Test-ModeMatch([string[]]$Tags, [string]$Mode, [string[]]$Query) {
  if ($Mode -eq 'and') {
    foreach ($q in $Query) { if (-not (Test-TagListContains $Tags $q)) { return $false } }
    return $true
  }
  foreach ($q in $Query) { if (Test-TagListContains $Tags $q) { return $true } }
  return $false
}

function ConvertTo-Tokens([string]$Expr) {
  $tokens = New-Object System.Collections.Generic.List[string]
  $pattern = '\s*(&&|\|)\s*|\s*([a-zA-Z0-9_-]+)\s*'
  $pos = 0
  while ($pos -lt $Expr.Length) {
    $m = [regex]::Match($Expr.Substring($pos), $pattern)
    if (-not $m.Success -or $m.Length -eq 0) { throw "Invalid token near: $($Expr.Substring($pos))" }
    if ($m.Groups[1].Success) { $tokens.Add($m.Groups[1].Value) | Out-Null }
    elseif ($m.Groups[2].Success) { $tokens.Add($m.Groups[2].Value.ToLowerInvariant()) | Out-Null }
    $pos += $m.Length
  }
  return @($tokens)
}

function Test-ExprMatch([string[]]$Tags, [string[]]$Tokens) {
  $ok = $null
  $op = $null
  foreach ($tok in $Tokens) {
    if ($tok -eq '&&' -or $tok -eq '|') { $op = $tok; continue }
    $val = Test-TagListContains $Tags $tok
    if ($null -eq $ok) { $ok = $val }
    elseif ($op -eq '&&') { $ok = $ok -and $val }
    else { $ok = $ok -or $val }
    $op = $null
  }
  return [bool]$ok
}

if (-not $Args -or $Args.Count -lt 1 -or $Args[0] -in @('-h','--help')) {
  Show-Usage
  exit 1
}

$rootPrefix = Get-ShellGhostWorkspaceRoot
$allowedRoots = Get-ShellGhostAllowedRoots $rootPrefix
$files = Get-ShellGhostMemoryFiles -RootPrefix $rootPrefix -AllowedRoots $allowedRoots

$mode = 'expr'
$query = @()
if ($Args[0] -eq '--and' -or $Args[0] -eq '--or') {
  $mode = $Args[0].Substring(2)
  $query = @($Args[1..($Args.Count - 1)] | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
  if (-not $query -or $query.Count -eq 0) { Show-Usage; exit 1 }
} else {
  $query = ConvertTo-Tokens ($Args -join ' ')
  if (-not $query -or $query.Count -eq 0) { Show-Usage; exit 1 }
}

foreach ($file in $files) {
  $tags = Get-ShellGhostTagsFromFile $file
  if ($null -eq $tags) { continue }
  $match = if ($mode -eq 'expr') { Test-ExprMatch $tags $query } else { Test-ModeMatch $tags $mode $query }
  if ($match) {
    $out = ConvertTo-ShellGhostMemoryPath -Path $file -RootPrefix $rootPrefix
    if ($out) { Write-Output $out }
  }
}
