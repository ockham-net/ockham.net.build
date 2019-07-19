using namespace System.Collections.Generic
Import-Module (Join-Path $PSScriptRoot common-utils.psm1)
Import-Module (Join-Path $PSScriptRoot fs-utils.psm1)

# ==========================================
#  Internal functions
# ==========================================

function New-ProjectGuid {
  [Guid]::NewGuid().ToString('b').ToUpper()
}

<#
    .SYNOPSIS
    Find the first index of a string within a collection that matches the provided pattern

    .PARAMETER InputObject
    An enumerable collection of strings

    .PARAMETER Pattern
    The string pattern to match against using the -like operator

    .PARAMETER Regex
    Treat Pattern as a regular expression

    .PARAMETER Escape
    Use Regex.Escape() on Pattern before matching
#>
function Find-Line {
  param([IEnumerable[string]]$InputObject, $Pattern, [switch]$Regex, [switch]$Escape, [int]$StartIndex = 0)

  if ($Regex -and $Escape) {
    $Pattern = [regex]::Escape($Pattern)
  }

  $i = $StartIndex
  if ($StartIndex -gt 0) {
    $InputObject = [string[]]@($InputObject | Select-Object -Skip $StartIndex)
  }
  foreach ($line in $InputObject) {
    if ($Regex) {
      if ($line -match $pattern) { return $i }
    }
    else {
      if ($line -like $pattern) { return $i }
    }
    $i += 1
  } 

  return -1
}

function Set-SolutionPath {

  param($project)
    
  foreach ($childProject in $project.ChildProjects) {
    $childProject.SolutionPath = $project.SolutionPath + '\' + $childProject.SolutionPath

    Set-SolutionPath $childProject
  } 
}


<#
    .SYNOPSIS
    Get and verify the existence of a project file with the specified file name, or within the specified directory
#>
function Get-ProjectFile {
  param([string]$ProjectPath)

  if (Test-IsEmpty $ProjectPath) {
    $ProjectPath = Get-CurrentDirectory
  }
  elseif (!($ProjectPath -match '^(\\\\|[A-Z]:)')) {
    $ProjectPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($(Get-CurrentDirectory), $ProjectPath))
  }

  if (!(Test-FSPath $ProjectPath)) {
    if ([System.IO.Path]::GetExtension($ProjectPath) -notlike '*proj') {
      $projFiles = Get-ChildItem "$ProjectPath.*proj"
      if ($projFiles.Count -gt 0) {
        return $projFiles[0].FullName
      }
    }

    Write-Error "Project file $ProjectPath not found"
    return 
  }
     
  if ([System.IO.Directory]::Exists($ProjectPath)) {
    $projFiles = [System.IO.Directory]::GetFiles($ProjectPath, '*.*proj')
    if ($projFiles.Count -gt 0) {
      $ProjectPath = $projFiles[0]
      Write-Host "Using project file $ProjectPath"
    }
    else {
      Write-Error "No project file found in directory $ProjectPath"
      return
    }
  }
  elseif ([System.IO.File]::Exists($ProjectPath)) {
    return $ProjectPath
  }
  else {
    Write-Error "Path $ProjectPath not found"
    return 
  } 

  return $ProjectPath
}

# ==========================================
#  Exported functions
# ==========================================
<#
    .SYNOPSIS
    Create a blank Visual Studio solution file
#>
function New-Solution {

  param([string]$SolutionDir, [string]$SolutionName)

  if (Test-IsEmpty $SolutionDir) { 
    $SolutionDir = Get-CurrentDirectory 
  }
  else {
    $SolutionDir = [IOPath]::GetFullPath([IOPath]::Combine((Get-CurrentDirectory), $SolutionDir))
  }
     
  if (!(Test-Path $SolutionDir)) { mkdir $SolutionDir | Out-Null }
  $slnFile = [IOPath]::Combine($SolutionDir, $SolutionName + '.sln')
  $slnGuid = [Guid]::NewGuid()

  [IOFile]::WriteAllText($slnFile, @"
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 15
VisualStudioVersion = 15.0.27428.2027
MinimumVisualStudioVersion = 10.0.40219.1
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution 
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
	GlobalSection(NestedProjects) = preSolution 
	EndGlobalSection
	GlobalSection(ExtensibilityGlobals) = postSolution
		SolutionGuid = $($slnGuid.ToString('B').ToUpper())
	EndGlobalSection
EndGlobal
"@)
    
  return $slnFile
}

<#
    .SYNOPSIS
    Get the tree of all project in a solution
#>
function Get-ProjectGraph {
    
  param([string]$SolutionFile)

  $projects = @{ }

  $solutionContent = [list[string]]::new([IOFile]::ReadAllLines($SolutionFile))
  $i = Find-Line $solutionContent '^Project' -Regex
  while ($i -gt -1) {
    $line = $solutionContent[$i]
    $typeGuid = $line.Substring(9, 38)
    $info = [string[]]$(Invoke-Expression $line.Substring(51))
    $projectName = $info[0]
    $projectPath = $info[1]
    $projectGuid = $info[2]
    $projects[$projectGuid] = New-PSObject @{
      Guid          = $projectGuid
      TypeGuid      = $typeGuid
      Name          = $projectName
      Path          = $projectPath 
      ParentProject = $null
      SolutionPath  = $projectName
      ChildProjects = [list[object]]::new()
    }
         
    $i = Find-Line $solutionContent '^EndProject' -Regex -StartIndex $($i + 1)
    $i = Find-Line $solutionContent '^Project' -Regex -StartIndex $($i + 1)
  }

  $i = Find-Line $solutionContent 'GlobalSection(NestedProjects) = preSolution' -Regex -Escape

  if ($i -gt -1) {
    $j = Find-Line $solutionContent '^\s*EndGlobalSection\s*$' -Regex -StartIndex $i
    $i += 1
    while ($i -lt $j) {
      $line = $solutionContent[$i]
      $m = [regex]::Match($line, '(?<childguid>\{[^}]{36}\})\s*=\s*(?<parentguid>\{[^}]{36}\})')
      if ($m.Success) {
        $childProject = $projects[$m.Groups['childguid'].Value]
        $parentProject = $projects[$m.Groups['parentguid'].Value]
        $childProject.ParentProject = $parentProject
        $parentProject.ChildProjects.Add($childProject)
      }
      $i += 1
    }
  } 

  foreach ($project in $projects.Values) {
    if ($null -ne $project.ParentProject) { continue; }
    Set-SolutionPath $project
  }

  foreach ($project in @($projects.Values)) {
    $projects[$project.SolutionPath] = $project
  }

  return $projects
}

<#
    .SYNOPSIS 
    Add a new solution folder to a solution 
#>
function Add-SolutionFolder {

  param([string]$SolutionFile, [string]$FolderPath, [switch]$IgnoreExisting)
    
  $projects = Get-ProjectGraph $SolutionFile
  if ($projects.ContainsKey($FolderPath)) {
    if ($IgnoreExisting) { return $projects[$FolderPath].Guid }
    throw $(New-Object System.ArgumentException FolderPath "A project with path $FolderPath already exists in this solution")
  }

  $parts = $FolderPath.Split('\')
  $folderName = $parts | Select-Object -Last 1

  $parentGuid = $null
  $parentPath = $null
  if ($parts.Length -gt 1) { 
    $parentPath = [string]::Join('\', ($parts | Select-Object -First $($parts.Length - 1)))
    $parentGuid = Add-SolutionFolder $SolutionFile $parentPath -IgnoreExisting 
  } 
     
  # Add the project to the solution
  $solutionContent = [list[string]]::new([IOFile]::ReadAllLines($SolutionFile))
  $i = Find-Line $solutionContent 'Global'
  $projectGuid = New-ProjectGuid

  # Insert the project
  $solutionContent.InsertRange($i, [string[]]@(
      "Project(`"{2150E333-8FDC-42A3-9474-1A3956D46DE8}`") = `"$folderName`", `"$folderName`", `"$projectGuid`"",
      "EndProject" 
    ))

  if ($null -ne $parentGuid) {
    $i = Find-Line $solutionContent 'GlobalSection(NestedProjects) = preSolution' -Regex -Escape
    if ($i -eq -1) {
      $i = Find-Line $solutionContent 'GlobalSection(ExtensibilityGlobals) = postSolution' -Regex -Escape

      $solutionContent.InsertRange($i, [string[]]@(
          "`tGlobalSection(NestedProjects) = preSolution",
          "`tEndGlobalSection"
        ))
      $i += 1 
    }
    else {
      $i = Find-Line $solutionContent '^\s*EndGlobalSection\s*$' -Regex -StartIndex $i
    }

    $solutionContent.Insert($i, "`t`t$projectGuid = $parentGuid")
  }
     
  [IOFile]::WriteAllLines($SolutionFile, $solutionContent) 

  $projectGuid
}


<#
    .SYNOPSIS
    Add an existing project to an existing solution. Equivalent to Add > Existing Project in Visual Studio
#>
function Add-Project {
  param(
    [Parameter(Mandatory)]
    [string]$SolutionFile, 

    [string]$ProjectFile, 
    [string]$SolutionFolder,
    [string]$TypeGuid
  )

  $parentGuid = $null
  $projectGuid = $null
  $ProjectFile = Get-ProjectFile $ProjectFile
  if (!(Test-FSPath $ProjectFile)) { return }
  
  if (Test-IsEmpty $TypeGuid) { $TypeGuid = Resolve-ProjectType $ProjectFile -GuidOnly }
  if (Test-IsEmpty $TypeGuid) { 
    Write-Error 'Project type guid could not be determined'
    return
  }

  $projectName = [IOPath]::GetFileNameWithoutExtension($ProjectFile)
  $relativePath = Get-RelativePath $SolutionFile $ProjectFile

  if (Test-IsNotEmpty $SolutionFolder) {
    $parentGuid = Add-SolutionFolder -SolutionFile $SolutionFile -FolderPath $SolutionFolder -IgnoreExisting
  }

  $props = Get-ProjectProperties $ProjectFile
  if ($props.ContainsKey('ProjectGuid')) { 
    $projectGuid = $props['ProjectGuid']
  }
  else {
    $projectGuid = New-ProjectGuid
  }
     
  # Add the project to the solution
  $solutionContent = [list[string]]::new([IOFile]::ReadAllLines($SolutionFile))
  $i = Find-Line $solutionContent 'Global'

  # Insert the project
  $solutionContent.InsertRange($i, [string[]]@(
      "Project(`"$TypeGuid`") = `"$projectName`", `"$relativePath`", `"$projectGuid`"",
      "EndProject" 
    ))

  if ($null -ne $parentGuid) {
    $i = Find-Line $solutionContent 'GlobalSection(NestedProjects) = preSolution' -Regex -Escape
    if ($i -eq -1) {
      $i = Find-Line $solutionContent 'GlobalSection(ExtensibilityGlobals) = postSolution' -Regex -Escape

      $solutionContent.InsertRange($i, [string[]]@(
          "`tGlobalSection(NestedProjects) = preSolution",
          "`tEndGlobalSection"
        ))
      $i += 1 
    }
    else {
      $i = Find-Line $solutionContent '^\s*EndGlobalSection\s*$' -Regex -StartIndex $i
    }

    $solutionContent.Insert($i, "`t`t$projectGuid = $parentGuid")
  }
     
  [IOFile]::WriteAllLines($SolutionFile, $solutionContent) 
  return $projectGuid
}
 
Export-ModuleMember New-Solution, Get-ProjectGraph, Add-SolutionFolder, Add-Project
