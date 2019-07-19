param(
  [ValidateSet('common-utils', 'fs-utils', $null)]
  [string]$Module
)

$modules = @()
if([string]::IsNullOrEmpty($Module)) {
  $modules = @('common-utils', 'fs-utils')
} else {
  $modules = @($Module)
}

$testDir = [System.IO.Path]::Combine($PSScriptRoot, 'tests', 'lib')

foreach($mName in $modules) {
  $testFile =  (Join-Path $testDir "$mName.tests.ps1")
  if(Test-Path $testFile) {
    Write-Host "Testing module $mName"

    pwsh -f $testFile
  } else {
    Write-Warning "Test file $testFile not found"
  }
  
}
