Import-Module (Join-Path $PSScriptRoot (Join-Path netscaffold common-utils.psm1))
Import-Module (Join-Path $PSScriptRoot (Join-Path netscaffold fs-utils.psm1))
Import-Module (Join-Path $PSScriptRoot (Join-Path netscaffold msbuild-evaluator.psm1))
Import-Module (Join-Path $PSScriptRoot (Join-Path netscaffold project-registry.psm1))
Import-Module (Join-Path $PSScriptRoot (Join-Path netscaffold solution-file.psm1))

. (Join-Path $PSScriptRoot (Join-Path netscaffold project-types.ps1)) | Out-Null

Export-ModuleMember -Function `
  Get-ProjectProperties, `
  Add-ProjectType, `
  Get-ProjectType, `
  Resolve-ProjectType, `
  New-Solution, `
  Get-ProjectGraph, `
  Add-SolutionFolder, `
  Add-Project
