param(
  [Parameter(Position=0)][string]$MemoryDir = '',
  [Alias('h')][switch]$Help
)
$ErrorActionPreference = 'Stop'

if ($Help) {
  Write-Output 'Usage: check_memory_template_integrity.ps1 [MEMORY_DIR]'
  Write-Output 'Default MEMORY_DIR: $env:SHELL_GHOST_MEMORY or $env:SHELL_GHOST/MEMORY'
  exit 0
}

if (-not $MemoryDir) {
  if ($env:SHELL_GHOST_MEMORY) {
    $MemoryDir = $env:SHELL_GHOST_MEMORY
  } elseif ($env:SHELL_GHOST) {
    $MemoryDir = Join-Path $env:SHELL_GHOST 'MEMORY'
  } else {
    [Console]::Error.WriteLine('Error: pass MEMORY_DIR or set SHELL_GHOST_MEMORY/SHELL_GHOST.')
    exit 1
  }
}

if (-not (Test-Path -LiteralPath $MemoryDir -PathType Container)) {
  [Console]::Error.WriteLine("Error: MEMORY_DIR not found: $MemoryDir")
  exit 1
}

$files = @(Get-ChildItem -LiteralPath $MemoryDir -Recurse -File -Filter '*.md' | Sort-Object FullName)
$total = 0
$failed = 0

foreach ($file in $files) {
  $normalized = $file.FullName.Replace('\', '/')
  if ($normalized -match '/(thoughts|notes)/') { continue }

  $total += 1
  $lines = @(Get-Content -LiteralPath $file.FullName -TotalCount 3 -ErrorAction SilentlyContinue)
  $line1 = if ($lines.Count -ge 1) { $lines[0] } else { '' }
  $line2 = if ($lines.Count -ge 2) { $lines[1] } else { '' }
  $line3 = if ($lines.Count -ge 3) { $lines[2] } else { '' }

  $ok = $line1.StartsWith('guid: ') -and $line2.StartsWith('related: ') -and $line3.StartsWith('tags: ')
  if (-not $ok) {
    $failed += 1
    Write-Output "FAIL $($file.FullName)"
    Write-Output "  1> $(if ($line1) { $line1 } else { '<empty>' })"
    Write-Output "  2> $(if ($line2) { $line2 } else { '<empty>' })"
    Write-Output "  3> $(if ($line3) { $line3 } else { '<empty>' })"
  }
}

Write-Output "checked=$total failed=$failed memory_dir=$MemoryDir"

if ($failed -gt 0) {
  exit 1
}
