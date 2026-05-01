param(
  [ValidateSet('min','normal','full')][string]$Mode = 'normal'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'workflow_utils.ps1')

function Emit-File([string]$Path) {
  if (Test-Path -LiteralPath $Path -PathType Leaf) {
    Write-Output (Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
  }
}

function Emit-BaseContext([string]$Root) {
  foreach ($name in @('AGENTS.md','TOOLS.md')) {
    Emit-File (Join-Path $Root $name)
  }
}

function Print-EnvSnapshot {
  Write-Output ''
  Write-Output '# SHELL GHOST ENV (load mode)'
  foreach ($key in @('SHELL_GHOST_ROOT','SHELL_GHOST','SHELL_GHOST_ENV','SHELL_GHOST_MEMORY','SHELL_GHOST_QUEUE','SHELL_GHOST_WORKSPACE','PROJECTS','HOME')) {
    $value = [Environment]::GetEnvironmentVariable($key)
    if ($value) { Write-Output "$key=$value" }
  }
}

$root = Get-ShellGhostRoot
if ($Mode -eq 'min') {
  Emit-File (Join-Path $root 'AGENTS.md')
  exit 0
}

Emit-BaseContext $root

if ($Mode -eq 'normal') {
  Print-EnvSnapshot
  exit 0
}

Write-Output ''
Write-Output '# MEMORY INDEX (full mode)'
Emit-File (Join-Path $root 'MEMORY.md')

Write-Output ''
Write-Output '# MEMORY HUBS (full mode)'
$memoryDir = Join-Path $root 'MEMORY'
$hubs = @()
if (Test-Path -LiteralPath $memoryDir -PathType Container) {
  $hubs = @(Get-ChildItem -LiteralPath $memoryDir -File -Filter 'HUB_*.md' | Sort-Object FullName)
}
if ($hubs.Count -eq 0) {
  [Console]::Error.WriteLine('[load-context] no hubs found')
}
foreach ($hub in $hubs) {
  Emit-File $hub.FullName
}
Print-EnvSnapshot
