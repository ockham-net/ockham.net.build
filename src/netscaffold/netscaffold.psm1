Import-Module (Join-Path $PSScriptRoot (Join-Path modules msbuild-evaluator.psm1))
Import-Module (Join-Path $PSScriptRoot (Join-Path modules project-registry.psm1))
Import-Module (Join-Path $PSScriptRoot (Join-Path modules solution-file.psm1))

. (Join-Path $PSScriptRoot (Join-Path scripts project-types.ps1)) | Out-Null

# Export-ModuleMember -Function `
#   Get-ProjectProperties, `
#   Add-ProjectType, `
#   Get-ProjectType, `
#   Resolve-ProjectType, `
#   New-Solution, `
#   Get-ProjectGraph, `
#   Add-SolutionFolder, `
#   Add-Project
