$srcRoot = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'src', 'lib', 'netscaffold')
Import-Module Pester

if($null -ne (Get-Module project-registry)) { 
  Write-Host "Unloading existing project-registry module" -ForegroundColor Cyan
  Remove-Module project-registry
}
Import-Module (Join-Path $srcRoot 'project-registry.psm1')

. (Join-Path $srcRoot 'project-types.ps1') | Out-Null

$projectsDir = [System.IO.Path]::Combine($PSScriptRoot, 'fixtures', 'project-types')

<#
$projectFiles = Get-ChildItem (Join-Path $PSScriptRoot fixtures) -Recurse -Filter *.*proj

$type $projectFiles | ForEach-Object {
  $fullPath = $_.FullName
  $info = Resolve-ProjectType $fullPath -ErrorAction SilentlyContinue
  if($null -eq $info) {
    $info = New-Object psobject -Property @{
      FileName = $_.Name
      Name     = 'Not found'
    }
  } else {
    Add-Member -InputObject $info -NotePropertyName FileName -NotePropertyValue $_.Name
  }
  $info
} | Select-Object FileName, Name, Language, TypeGuid
#>

Describe project-registry {
  Context Resolve-ProjectType {

    It 'detects C# ASP.NET Core' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'CSharpAspNetCore.csproj')
      $info.Name | Should -BeExactly 'C# ASP.NET Core'
    }

    It 'detects C# Shared Project' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'CSharpShared.shproj')
      $info.Name | Should -BeExactly 'C# Shared Project'
    }

    It 'detects C# .NET Framework Library' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'CSharpLibFmk.csproj')
      $info.Name | Should -BeExactly 'C# .NET Framework Library'
    }

    It 'detects C# .NET Framework Console' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'CSharpConsoleFmk.csproj')
      $info.Name | Should -BeExactly 'C# .NET Framework Console'
    }

    It 'detects C# .NET Core Library' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'CSharpLibCore.csproj')
      $info.Name | Should -BeExactly 'C# .NET Core Library'
    }

    It 'detects C# .NET Core Console' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'CSharpConsoleCore.csproj')
      $info.Name | Should -BeExactly 'C# .NET Core Console'
    }

    It 'detects VB.NET Shared Project' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'VBShared.shproj')
      $info.Name | Should -BeExactly 'VB.NET Shared Project'
    }

    It 'detects VB .NET Framework Library' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'VBLibFmk.vbproj')
      $info.Name | Should -BeExactly 'VB .NET Framework Library'
    }

    It 'detects VB .NET Framework Console' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'VBConsoleFmk.vbproj')
      $info.Name | Should -BeExactly 'VB .NET Framework Console'
    }

    It 'detects VB .NET Core Library' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'VBLibCore.vbproj')
      $info.Name | Should -BeExactly 'VB .NET Core Library'
    }

    It 'detects VB .NET Core Console' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'VBConsoleCore.vbproj')
      $info.Name | Should -BeExactly 'VB .NET Core Console'
    }

    It 'detects SQL Server Project' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'SqlServer.sqlproj')
      $info.Name | Should -BeExactly 'SQL Server Project'
    }

    It 'detects Nodejs JavaScript project' {
      $info = Resolve-ProjectType (Join-Path $projectsDir 'NodeJsConsole.njsproj')
      $info.Name | Should -BeExactly 'Nodejs'
      $info.Language | Should -Be JavaScript
    }

    It 'detects Nodejs TypeScript project' {
      $info = Resolve-ProjectType (Join-Path $projectsDir (Join-Path 'NodejsTSConsole' 'NodejsTSConsole.njsproj'))
      $info.Name | Should -BeExactly 'Nodejs'
      $info.Language | Should -Be TypeScript
    }
  }
}