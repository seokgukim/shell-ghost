$ErrorActionPreference = 'Stop'

function Resolve-ShellGhostPath([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    return (Get-Item -LiteralPath $Path).FullName
  }
  return [System.IO.Path]::GetFullPath($Path)
}

function Get-ShellGhostWorkspaceRoot {
  if ($env:SHELL_GHOST_WORKSPACE) { return (Resolve-ShellGhostPath $env:SHELL_GHOST_WORKSPACE) }
  if ($env:SHELL_GHOST) { return (Resolve-ShellGhostPath $env:SHELL_GHOST) }
  if ($env:SHELL_GHOST_ROOT) { return (Resolve-ShellGhostPath $env:SHELL_GHOST_ROOT) }
  return (Get-Location).Path
}

function Get-ShellGhostRoot {
  if ($env:SHELL_GHOST_ROOT) { return (Resolve-ShellGhostPath $env:SHELL_GHOST_ROOT) }
  if ($env:SHELL_GHOST) { return (Resolve-ShellGhostPath $env:SHELL_GHOST) }
  return (Resolve-ShellGhostPath (Join-Path $PSScriptRoot '..\..'))
}

function Get-ShellGhostAllowedRoots([string]$RootPrefix) {
  $rootsFile = Join-Path $RootPrefix 'memory_root_list.txt'
  $roots = @()
  if (Test-Path -LiteralPath $rootsFile -PathType Leaf) {
    $roots = Get-Content -LiteralPath $rootsFile | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  }
  if (-not $roots -or $roots.Count -eq 0) { $roots = @('MEMORY') }
  return @($roots)
}

function Add-ShellGhostItem {
  param(
    [Parameter(Mandatory=$true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Target,
    [Parameter(Mandatory=$true)][string]$Raw
  )
  $value = $Raw.Trim()
  if (-not $value) { return }
  if ($value.StartsWith('[') -and $value.EndsWith(']')) {
    if ($value -eq '[]') { return }
    $items = @($value | ConvertFrom-Json)
    foreach ($item in $items) {
      if ($null -ne $item) {
        $text = ([string]$item).Trim()
        if ($text) { $Target.Add($text) | Out-Null }
      }
    }
  } else {
    $Target.Add($value) | Out-Null
  }
}

function Format-ShellGhostList([string[]]$Items) {
  if (-not $Items -or $Items.Count -eq 0) { return '[]' }
  return '[' + ($Items -join ', ') + ']'
}

function New-ShellGhostGuid {
  return ([guid]::NewGuid().ToString())
}

function Resolve-ShellGhostMemoryPath {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$RootPrefix,
    [Parameter(Mandatory=$true)][string[]]$AllowedRoots
  )
  $raw = $Path.Trim()
  if (-not $raw) { throw 'path is empty' }

  $rootFull = (Resolve-ShellGhostPath $RootPrefix).TrimEnd('\','/')
  if ($raw.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    $rel = $raw.Substring($rootFull.Length).TrimStart('\','/')
    return (Join-Path $rootFull $rel)
  }

  $normalized = $raw.Replace('\', '/')
  if ($normalized.StartsWith('/')) {
    $rel = $normalized.TrimStart('/')
  } else {
    $rel = $normalized
  }
  $rootName = ($rel -split '/', 2)[0]
  if ($AllowedRoots -notcontains $rootName) {
    throw "--path root '$rootName' not allowed (see $(Join-Path $rootFull 'memory_root_list.txt'))"
  }
  return (Join-Path $rootFull $rel.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
}

function Get-ShellGhostTagsFromFile([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  $lines = Get-Content -LiteralPath $Path -TotalCount 8 -ErrorAction SilentlyContinue
  foreach ($line in $lines) {
    if ($line.Trim() -match '^tags:\s*\[(.*)\]\s*$') {
      $body = $Matches[1].Trim()
      if (-not $body) { return @() }
      return @($body -split ',' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
    }
  }
  return $null
}

function Get-ShellGhostMemoryFiles {
  param(
    [Parameter(Mandatory=$true)][string]$RootPrefix,
    [Parameter(Mandatory=$true)][string[]]$AllowedRoots
  )
  $files = New-Object System.Collections.Generic.List[string]
  $index = Join-Path $RootPrefix 'MEMORY.md'
  if (Test-Path -LiteralPath $index -PathType Leaf) { $files.Add((Resolve-ShellGhostPath $index)) | Out-Null }
  foreach ($root in $AllowedRoots) {
    $base = Join-Path $RootPrefix $root
    if (Test-Path -LiteralPath $base -PathType Container) {
      Get-ChildItem -LiteralPath $base -Recurse -File -Filter '*.md' | ForEach-Object { $files.Add($_.FullName) | Out-Null }
    }
  }
  return @($files)
}

function ConvertTo-ShellGhostMemoryPath {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$RootPrefix
  )
  $root = (Resolve-ShellGhostPath $RootPrefix).TrimEnd('\','/')
  $full = (Resolve-ShellGhostPath $Path)
  if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return '/' + $full.Substring($root.Length).TrimStart('\','/').Replace('\','/')
  }
  return $null
}
