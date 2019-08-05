param( 
  [string]$Module
)

$modules = @()
if([string]::IsNullOrEmpty($Module)) {
  $modules = @('common-utils', 'fs-utils', 'msbuild-evaluator', 'project-registry', 'netscaffold')
} else {
  $modules = @($Module)
}

$testDir = [System.IO.Path]::Combine($PSScriptRoot, 'tests', 'netscaffold')

foreach($mName in $modules) {
  $testFile =  (Join-Path $testDir "$mName.tests.ps1")
  if(Test-Path $testFile) {
    Write-Host "`r`nTesting module $mName" -ForegroundColor Yellow

    pwsh -f $testFile
  } else {
    Write-Warning "Test file $testFile not found"
  }
  
}
