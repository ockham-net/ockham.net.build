
param(
  [string]$ProjectName,

  [ValidateSet('C#', 'VB')]
  [string]$Language = 'C#'
)

Import-Module (Join-Path $PSScriptRoot (Join-Path netscaffold netscaffold.psd1))
Import-Module (Join-Path $PSScriptRoot (Join-Path psutil psutil.psd1))

$baseProjectName = $ProjectName.ToLower().Replace('Ockham.Net.', '').Replace('Ockham.', '')
$baseProjectName = $baseProjectName.Substring(0, 1).ToUpper() + $baseProjectName.Substring(1)
$ProjectName = 'Ockham.' + $baseProjectName

$opColor = 'Green'

Write-Host "`r`nScaffolding new project $ProjectName`r`n" -f $opColor

$callingDir = Get-CurrentDirectory

$solutionDir = Join-Path $callingDir ('ockham.net.' + $baseProjectName.ToLower())

$ext = 'csproj'
if('VB' -eq $Language) { $ext = 'vbproj' }

$libFrameworks = @('netstandard2.0', 'netcoreapp2.2', 'net472')
$tstFrameworks = @('netcoreapp2.2', 'net472')

# ==========================================
#  Solution File
# ==========================================
# Create the solution
$solutionFile = New-Solution -SolutionDir $solutionDir -SolutionName $ProjectName

Set-CurrentDirectory $solutionDir

# Add the solution folders 
Write-Host "`r`n  Initializing solution folders"  -f $opColor 

foreach($fldr in @('_build', 'api', 'src', 'tests')) {
  $baseFldr = $fldr.Replace('_', '')
  Write-Host "    Creating solution folder $baseFldr"  -f $opColor
  if(!(Test-Path $baseFldr)) { mkdir $baseFldr | Out-Null }
  Add-SolutionFolder $solutionFile $fldr | Out-Null
} 

# ==========================================
#  git
# ==========================================
# Init git
Write-Host "`r`n  Initializing git repository`r`n"  -f $opColor  
git init

# Add ref to core repo
Write-Host "    Adding submodule reference to ockham.net"  -f $opColor  
git submodule add https://github.com/ockham-net/ockham.net.git (Join-Path ref ockham.net)

Write-Host "    Adding .gitignore"  -f $opColor  
Invoke-RestMethod -Method get -Uri https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore > (Join-Path . .gitignore)

# ==========================================
#  Projects
# ==========================================
Write-Host "`r`n  Creating projects`r`n"  -f $opColor  

# shared
Write-Host "    Creating shared project"  -f $opColor  
$bldProjectDir = ([IOPath]::Combine($solutionDir, 'build'))
$bldProjectPath = Join-Path $bldProjectDir 'Build.shproj'

New-SharedProject -lang $Language -n Build -o $bldProjectDir
Add-Project $solutionFile -ProjectFile $bldProjectPath -SolutionFolder '_build'

# api
Write-Host "    Creating api project"  -f $opColor  
$apiProjectDir = ([IOPath]::Combine($solutionDir, 'api', 'lib'))
$apiProjectPath = Join-Path $apiProjectDir "$ProjectName.$ext"

dotnet new classlib -lang $Language -n $ProjectName -o $apiProjectDir
Add-Project $solutionFile -ProjectFile $apiProjectPath -SolutionFolder 'api'
Set-TargetFrameworks $apiProjectPath @('netstandard2.0')

# src
Write-Host "    Creating src project"  -f $opColor  
$srcProjectDir = ([IOPath]::Combine($solutionDir, 'src', 'lib'))
$srcProjectPath = Join-Path $srcProjectDir "$ProjectName.$ext"

dotnet new classlib -lang $Language -n $ProjectName -o $srcProjectDir
Add-Project $solutionFile -ProjectFile $srcProjectPath -SolutionFolder 'src'
Set-TargetFrameworks $apiProjectPath $libFrameworks

# test
Write-Host "    Creating test project"  -f $opColor  
$testProjectDir = ([IOPath]::Combine($solutionDir, 'tests', 'lib'))
$testProjectPath = Join-Path $testProjectDir "$ProjectName.Tests.$ext"

dotnet new xunit -lang $Language -n "$ProjectName.Tests" -o $testProjectDir
Add-Project $solutionFile -ProjectFile $testProjectPath -SolutionFolder 'tests'
Set-TargetFrameworks $apiProjectPath $tstFrameworks

dotnet add $testProjectPath reference $srcProjectPath

# ==========================================
#  Cleanup
# ==========================================
# Go back to original directory
Set-CurrentDirectory $callingDir | Out-Null
