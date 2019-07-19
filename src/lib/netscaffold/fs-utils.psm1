<#
  This module contains basic utilities for interacting with file paths
#>

Import-Module (Join-Path $PSScriptRoot common-utils.psm1)
Add-Accelerator IOFile System.IO.File
Add-Accelerator IOPath System.IO.Path
Add-Accelerator IODir  System.IO.Directory

<# 
  .SYNOPSIS
  Test whether the existing relative or absolute file system path exists. First uses Powershell Get-Item, but falls
  back to Directory.Exists and File.Exists for certain paths which Powershell cannot handle (such as paths with square brackets).
  Also verifies that $FileSystemPath is a file system path, and not another supported PowerShell path such as variable:\, function:\, etc.
#>
function Test-FSPath ($FileSystemPath) {
  if (Test-IsEmpty $FileSystemPath) { return $false }

  $result = $false
  try { 
    if (Test-Path $FileSystemPath) {
      $item = Get-Item $FileSystemPath -ErrorAction Ignore
      $result = ($null -ne $item) -and $($item.PSProvider.Name -eq 'FileSystem')        
    }
  }
  catch [Exception] {
    $ex = $_.Exception
    if ($ex.GetType().FullName -like 'System.Management.Automation.*') {
      # Path pattern that Test-Path can't handle 
      $result = $false 
    }
    else {
      throw
    } 
  }
     
  return ($result -or ([IODir]::Exists($FileSystemPath)) -or ([IOFile]::Exists($FileSystemPath)))
}

<#
  .SYNOPSIS
  Ensure PS Location and Environment.CurrentDirectory are in sync
#>
function Set-CurrentDirectory {
  param([string]$Path)

  if (Test-IsEmpty $Path) {
    if ($(Get-Location).Provider.Name -ne 'FileSystem') {
      $Path = [Environment]::CurrentDirectory
    }
    else { 
      $Path = $(Get-Location).Path
    }
  }

  Set-Location $Path
  [Environment]::CurrentDirectory = $Path
  return $Path
}

<#
  .SYNOPSIS
  Ensure PS Location and Environment.CurrentDirectory are in sync and return the current working directory
#>
function Get-CurrentDirectory {
  Set-CurrentDirectory 
}

<#
  .SYNOPSIS
  Convert an absolute path to a relative path relative to a given starting path
#>
function Get-RelativePath {

  param([string]$BasePath, [string]$AbsolutePath)

  $delDir = $false
  if (![IODir]::Exists($BasePath)) {
    if ([IOFile]::Exists($BasePath)) {
      $BasePath = Split-Path $BasePath -Parent
    }
    else {
      mkdir $BasePath | Out-Null
      $delDir = $true
    }
  }

  $d = Get-CurrentDirectory
  Set-CurrentDirectory $BasePath | Out-Null
  $result = Resolve-Path -Path $AbsolutePath -Relative
  Set-CurrentDirectory $d | Out-Null

  if ($delDir) { Remove-Item $BasePath -Force -ErrorAction SilentlyContinue }

  return $result

}

$OnRemoveScript = { 
  Remove-Accelerator IOFile
  Remove-Accelerator IOPath
  Remove-Accelerator IODir
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript

Export-ModuleMember -Function Get-CurrentDirectory, Set-CurrentDirectory, Get-RelativePath, Test-FSPath 
