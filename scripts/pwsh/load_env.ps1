param(
  [ValidateSet('none','powershell','json')][string]$Format = 'none'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'workflow_utils.ps1')

$root = Resolve-ShellGhostPath (Join-Path $PSScriptRoot '..\..')

$envMap = [ordered]@{
  SHELL_GHOST_ROOT = $root
  SHELL_GHOST = $root
  SHELL_GHOST_ENV = '1'
  SHELL_GHOST_MEMORY = (Join-Path $root 'MEMORY')
  SHELL_GHOST_QUEUE = (Join-Path $root 'queue')
}

$scriptsRoot = Join-Path $root 'scripts'
$scriptsDir = Join-Path $scriptsRoot 'pwsh'
$scriptsShDir = Join-Path $scriptsRoot 'sh'
$pathParts = New-Object System.Collections.Generic.List[string]
foreach ($candidate in @($scriptsDir, $scriptsShDir, $scriptsRoot)) {
  if ((Test-Path -LiteralPath $candidate -PathType Container) -and (-not $pathParts.Contains($candidate))) {
    $pathParts.Add($candidate) | Out-Null
  }
}
foreach ($existing in (($env:PATH -split [regex]::Escape([System.IO.Path]::PathSeparator)) | Where-Object { $_ })) {
  if (-not $pathParts.Contains($existing)) { $pathParts.Add($existing) | Out-Null }
}
$envMap.PATH = ($pathParts -join [System.IO.Path]::PathSeparator)

foreach ($key in $envMap.Keys) {
  [Environment]::SetEnvironmentVariable($key, [string]$envMap[$key], 'Process')
}

if ($Format -eq 'none') {
  return
} elseif ($Format -eq 'json') {
  [pscustomobject]$envMap | ConvertTo-Json -Depth 4
} else {
  foreach ($key in $envMap.Keys) {
    $value = [string]$envMap[$key]
    if ($value) {
      $escaped = $value.Replace('`','``').Replace('"','`"')
      Write-Output "`$env:$key = `"$escaped`""
    }
  }
}
