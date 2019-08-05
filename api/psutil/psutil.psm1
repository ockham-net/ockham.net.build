<#
  Test whether the input value is null, or an empty or whitespace string
#>  
function Test-IsEmpty ([string]$Value) { }

<#
  Test whether the input value is a non-null string with no-whitespace characters
#>  
function Test-IsNotEmpty ([string]$Value) { }

<#
  Create a new PSObject with properties initialized from the provided hashtable
#>
function New-PSObject ([hashtable]$Property) { }

<#
  Define a new type accelerator (type alias)
#>
function Add-Accelerator ([string]$Alias, $Type, [switch]$Force) { }

<# 
  .SYNOPSIS
  Test whether the existing relative or absolute file system path exists. First uses Powershell Get-Item, but falls
  back to Directory.Exists and File.Exists for certain paths which Powershell cannot handle (such as paths with square brackets).
  Also verifies that $FileSystemPath is a file system path, and not another supported PowerShell path such as variable:\, function:\, etc.
#>
function Test-FSPath ($FileSystemPath) { }

<#
  .SYNOPSIS
  Ensure PS Location and Environment.CurrentDirectory are in sync
#>
function Set-CurrentDirectory ([string]$Path) { }

<#
  .SYNOPSIS
  Ensure PS Location and Environment.CurrentDirectory are in sync and return the current working directory
#>
function Get-CurrentDirectory { }

<#
  .SYNOPSIS
  Convert an absolute path to a relative path relative to a given starting path
#>
function Get-RelativePath([string]$BasePath, [string]$AbsolutePath) { }
