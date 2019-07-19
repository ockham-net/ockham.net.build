using module .\object-model.psm1
using namespace System.Collections.Generic

Import-Module (Join-Path $PSScriptRoot common-utils.psm1)
Import-Module (Join-Path $PSScriptRoot fs-utils.psm1)

$projectTypes = [List[ProjectInfo]]::new()

<#
  .SYNOPSIS
  Register a new project type that can be detected

  .PARAMETER Name
  A display name for the project type

  .PARAMETER TypeGuid
  The Visual Studio project type Guid

  .PARAMETER Test
  A script block which accepts the string path of the project file, and
  returns a boolean indicated whether the project is of this project type

  .PARAMETER Top
  Add to the beginning of the detection order. Default is to append to the end

  .EXAMPLE
  Enable detection of C# shared project

  Add-ProjectType 'C# Shared Project' 'D954291E-2A0B-460D-934E-DC6B0785DB48' {
    param([string]$ProjectPath)

    # File extension must be 'shproj'
    if([System.IO.Path]::GetExtension($ProjectPath).ToLower() -ne '.shproj') {
      return false
    }

    # File contents must include 'Microsoft.CodeSharing.CSharp.targets'
    $contents = [System.IO.File]::ReadAllText($ProjectPath)
    if($contents.IndexOf('Microsoft.CodeSharing.CSharp.targets') -eq -1) {
      return false
    }

    return true
  }

#>
function Add-ProjectType {

  [OutputType([ProjectInfo])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name, 
 
    [guid]$TypeGuid, 
    
    [ValidateSet(
      'CSharp', 'VisualBasic', 'JavaScript', 
      'TypeScript', 'PowerShell', 'SQL', 
      'Unknown', $null
    )]
    [string]$Language,

    [Parameter(Mandatory)]
    [scriptblock]$Test,
 
    [scriptblock]$Factory,

    [switch]$Top
  )

  if($null -eq $Test) { throw ([System.ArgumentNullException]::new('Test')) }
 
  if(Test-IsEmpty $Language) { $Language = 'Unkown' }
 
  $testDelegate = [System.Func[string,bool]]$Test 
  $projectInfo  = $null

  if($null -ne $Factory) {
    if($null -eq $TypeGuid) { $TypeGuid = [guid]::Empty }
    $factoryDelegate = [System.Action[string,ProjectInfo]]$Factory
    $projectInfo = [DynamicProjectInfo]::new($Name, $TypeGuid, [CodeLanguage]$Language, $testDelegate, $factoryDelegate)
  } else {
    if([guid]::Empty -eq $TypeGuid) { throw ([System.ArgumentNullException]::new('TypeGuid')) }
    $projectInfo = [ProjectInfo]::new($Name, $TypeGuid, [CodeLanguage]$Language, $testDelegate)
  }

  if($Top) {
    $projectTypes.Insert(0, $projectInfo)
  } else { 
    $projectTypes.Add($projectInfo)
  }
  
  $projectInfo
}

function Resolve-ProjectType {

  [cmdletbinding()]
  param([string]$ProjectFilePath, [switch]$GuidOnly)

  $projectInfo = $null
  for($i = 0; $i -lt $projectTypes.Count; $i++) {
    $projectInfo = $projectTypes[$i]
    if($projectInfo.Test($ProjectFilePath)) {
      break
    }
    $projectInfo = $null
  }
 
  if($null -ne $projectInfo) {
    if($projectInfo.IsDynamic) {
      $projectInfo = $projectInfo.Create($ProjectFilePath)
    }

    if($GuidOnly) {
      return $projectInfo.TypeGuid.ToString('B').ToUpper()
    } else {
      return $projectInfo.Clone()
    }
  }

  Write-Error "No matching project type found"
}

function Get-ProjectType {
  param()
  $projectTypes.GetEnumerator()
}

Export-ModuleMember Add-ProjectType, Resolve-ProjectType, Get-ProjectType
