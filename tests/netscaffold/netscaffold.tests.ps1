$srcRoot = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'src', 'netscaffold')
Import-Module Pester

if($null -ne (Get-Module netscaffold)) { 
  Write-Host "Unloading existing netscaffold module" -ForegroundColor Cyan
  Remove-Module netscaffold
}
Import-Module (Join-Path $srcRoot 'netscaffold.psm1')

Describe netscaffold {
  Context 'Verify function exports' {
    It 'Exports Get-ProjectProperties' {
      Test-Path function:\Get-ProjectProperties | Should -BeTrue
    }

    It 'Exports Add-ProjectType' {
      Test-Path function:\Add-ProjectType | Should -BeTrue
    }

    It 'Exports Get-ProjectType' {
      Test-Path function:\Get-ProjectType | Should -BeTrue
    }

    It 'Exports Resolve-ProjectType' {
      Test-Path function:\Resolve-ProjectType | Should -BeTrue
    }

    It 'Exports New-Solution' {
      Test-Path function:\New-Solution | Should -BeTrue
    }

    It 'Exports Get-ProjectGraph' {
      Test-Path function:\Get-ProjectGraph | Should -BeTrue
    }

    It 'Exports Add-SolutionFolder' {
      Test-Path function:\Add-SolutionFolder | Should -BeTrue
    }

    It 'Exports Add-Project' {
      Test-Path function:\Add-Project | Should -BeTrue
    }
  }
}