param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'workflow_utils.ps1')

function Show-Usage {
  @'
[CAUTION] priority is in descending order.
job_queue.ps1 push [priority] <content...>
job_queue.ps1 peek
job_queue.ps1 pop
job_queue.ps1 list
job_queue.ps1 clear
'@ | Write-Output
}

$rootPrefix = Get-ShellGhostWorkspaceRoot
$queueDir = if ($env:SHELL_GHOST_WORKSPACE) {
  Join-Path $rootPrefix 'queue'
} elseif ($env:SHELL_GHOST_QUEUE) {
  $env:SHELL_GHOST_QUEUE
} else {
  Join-Path $rootPrefix 'queue'
}
$queueFile = Join-Path $queueDir 'queue.md'
$historyFile = Join-Path $queueDir 'history.md'
New-Item -ItemType Directory -Path $queueDir -Force | Out-Null
foreach ($file in @($queueFile, $historyFile)) {
  if (-not (Test-Path -LiteralPath $file)) { New-Item -ItemType File -Path $file -Force | Out-Null }
}

function Read-Lines([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  return @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue | Where-Object { $_ })
}

function Write-Lines([string]$Path, [string[]]$Lines) {
  if ($Lines.Count -eq 0) {
    [System.IO.File]::WriteAllText($Path, '', [System.Text.UTF8Encoding]::new($false))
  } else {
    [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
  }
}

if ($Command -in @('-h','--help','help')) { Show-Usage; exit 0 }

switch ($Command) {
  'push' {
    if (-not $Rest -or $Rest.Count -lt 1) { Show-Usage; exit 1 }
    $priority = 0
    if ($Rest[0] -match '^\d+$') {
      $priority = [int]$Rest[0]
      $Rest = @($Rest | Select-Object -Skip 1)
    }
    if (-not $Rest -or $Rest.Count -lt 1) { Show-Usage; exit 1 }
    $content = $Rest -join ' '
    $line = '{0} {1} {2}' -f $priority, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $content
    $lines = @(Read-Lines $queueFile)
    if ($lines.Count -eq 0) {
      Write-Lines -Path $queueFile -Lines @($line)
      exit 0
    }
    $insertAt = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $existingPriority = 0
      $first = ($lines[$i] -split ' ', 2)[0]
      [void][int]::TryParse($first, [ref]$existingPriority)
      if ($existingPriority -lt $priority) { $insertAt = $i; break }
    }
    $out = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $insertAt) {
      foreach ($existing in $lines) { $out.Add($existing) | Out-Null }
      $out.Add($line) | Out-Null
    } else {
      for ($i = 0; $i -lt $insertAt; $i++) { $out.Add($lines[$i]) | Out-Null }
      $out.Add($line) | Out-Null
      for ($i = $insertAt; $i -lt $lines.Count; $i++) { $out.Add($lines[$i]) | Out-Null }
    }
    Write-Lines -Path $queueFile -Lines ($out.ToArray())
  }
  'peek' {
    $lines = @(Read-Lines $queueFile)
    if ($lines.Count -eq 0) { exit 1 }
    Write-Output $lines[0]
  }
  'pop' {
    $lines = @(Read-Lines $queueFile)
    if ($lines.Count -eq 0) { exit 1 }
    $top = $lines[0]
    [System.IO.File]::AppendAllText($historyFile, ($top + "`n"), [System.Text.UTF8Encoding]::new($false))
    Write-Lines -Path $queueFile -Lines @($lines | Select-Object -Skip 1)
    Write-Output $top
  }
  'list' {
    Read-Lines $queueFile | ForEach-Object { Write-Output $_ }
  }
  'clear' {
    Write-Lines -Path $queueFile -Lines @()
  }
  default {
    Show-Usage
    exit 1
  }
}
