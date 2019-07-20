$srcRoot = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'src', 'lib', 'netscaffold')
Import-Module Pester

if($null -ne (Get-Module msbuild-evaluator)) { 
  Write-Host "Unloading existing msbuild-evaluator module" -ForegroundColor Cyan
  Remove-Module msbuild-evaluator
}
Import-Module (Join-Path $srcRoot 'msbuild-evaluator.psm1')

$PATHS = @{
  BuildFiles =  [System.IO.Path]::Combine($PSScriptRoot, 'fixtures', 'BuildFiles')
}

Describe 'msbuild-evaluator' {
  
  Context Convert-BuildExpression { 
    It 'replaces property values' {
      $props = @{ 
        TargetFramework = 'net45' 
        Configuration   = 'Release'
      };

      $raw = "'`$(TargetFramework)|`$(Configuration)'=='net45|Debug'"
      Convert-BuildExpression $raw $props | Should -Be "'net45|Release'=='net45|Debug'" 
    } 

    It 'removes non-existent properties' {
      $props = @{ 
        TargetFramework = 'net45' 
        Configuration   = 'Release'
      };

      $raw = "'`$(NotDefined)'==''"
      Convert-BuildExpression $raw $props | Should -Be "''==''" 
    } 
  }

  # See https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-conditions
  Context Invoke-BuildExpression {
    It 'supports == operator' { 
      Invoke-BuildExpression "'C:\Users'=='C:\Users'" | Should -BeExactly $true
      Invoke-BuildExpression "'C:\Users'=='C:\Windows'" | Should -BeExactly $false
    }

    It 'supports != operator' { 
      Invoke-BuildExpression "'C:\Users'!='C:\Users'" | Should -BeExactly $false
      Invoke-BuildExpression "'C:\Users'!='C:\Windows'" | Should -BeExactly $true
    }

    It 'supports And operator' { 
      Invoke-BuildExpression "('A'=='A') And ('B'=='B')" | Should -BeExactly $true
      Invoke-BuildExpression "('A'=='A') And ('B'=='C')" | Should -BeExactly $false
    }

    It 'supports Or operator' { 
      Invoke-BuildExpression "('A'=='A') Or ('B'=='C')" | Should -BeExactly $true
      Invoke-BuildExpression "('A'=='B') Or ('B'=='C')" | Should -BeExactly $false
    }

    It 'supports < operator' { 
      Invoke-BuildExpression "(1 < 2)" | Should -BeExactly $true
      Invoke-BuildExpression "(2 < 1)" | Should -BeExactly $false
    }

    It 'supports > operator' { 
      Invoke-BuildExpression "(2 > 1)" | Should -BeExactly $true
      Invoke-BuildExpression "(1 > 2)" | Should -BeExactly $false
    }

    It 'supports <= operator' { 
      Invoke-BuildExpression "(1 <= 2)" | Should -BeExactly $true
      Invoke-BuildExpression "(1 <= 1)" | Should -BeExactly $true
      Invoke-BuildExpression "(2 <= 1)" | Should -BeExactly $false
    }

    It 'supports >= operator' { 
      Invoke-BuildExpression "(2 >= 1)" | Should -BeExactly $true
      Invoke-BuildExpression "(2 >= 2)" | Should -BeExactly $true
      Invoke-BuildExpression "(1 >= 2)" | Should -BeExactly $false
    }

    It 'supports < operator (escaped)' { 
      Invoke-BuildExpression "(1 &lt; 2)" | Should -BeExactly $true
      Invoke-BuildExpression "(2 &lt; 1)" | Should -BeExactly $false
    }

    It 'supports > operator (escaped)' { 
      Invoke-BuildExpression "(2 &gt; 1)" | Should -BeExactly $true
      Invoke-BuildExpression "(1 &gt; 2)" | Should -BeExactly $false
    }

    It 'supports <= operator (escaped)' { 
      Invoke-BuildExpression "(1 &lt;= 2)" | Should -BeExactly $true
      Invoke-BuildExpression "(1 &lt;= 1)" | Should -BeExactly $true
      Invoke-BuildExpression "(2 &lt;= 1)" | Should -BeExactly $false
    }

    It 'supports >= operator (escaped)' { 
      Invoke-BuildExpression "(2 &gt;= 1)" | Should -BeExactly $true
      Invoke-BuildExpression "(2 &gt;= 2)" | Should -BeExactly $true
      Invoke-BuildExpression "(1 &gt;= 2)" | Should -BeExactly $false
    }

    It 'supports Exists function' { 
      Set-Location $PSScriptRoot
      Invoke-BuildExpression "Exists( '.\fixtures\test.txt')" | Should -BeExactly $true
      Invoke-BuildExpression "Exists('.\fixtures\test.txt')" | Should -BeExactly $true
      Invoke-BuildExpression "Exists( '.\fixtures\test.txt'  )" | Should -BeExactly $true
      Invoke-BuildExpression "Exists( '.\foo.bar'  )" | Should -BeExactly $false
    }

    It 'supports HasTrailingSlash function' { 
      $DebugPreference = 'Continue'
      Invoke-BuildExpression "HasTrailingSlash( '.\fixtures\test.txt\')" | Should -BeExactly $true
      Invoke-BuildExpression "HasTrailingSlash('./fixtures/')" | Should -BeExactly $true
      Invoke-BuildExpression "HasTrailingSlash( '.\fixtures\test.txt'  )" | Should -BeExactly $false
      Invoke-BuildExpression "HasTrailingSlash( './fixtures'  )" | Should -BeExactly $false
    }
  }

  Context Get-ProjectProperties {
    
    It 'walks full tree' {
      $testProj = Join-Path $PATHS.BuildFiles 'Project\test.csproj' -Resolve
      $props = Get-ProjectProperties $testProj

      $props['Product'] | Should -Be 'Test'
      $props['GrandparentProp'] | Should -Be 'grandparent'
      $props['ParentProp'] | Should -Be 'parent'
      $props['DefaultProp'] | Should -Be 'new value'
      $props['AssemblyName'] | Should -Be 'test.lib'
    }

    It 'evaluates property expressions' {
      $testProj = Join-Path $PATHS.BuildFiles 'Project\test.csproj' -Resolve
      $props = Get-ProjectProperties $testProj

      $props['SemVer'] | Should -Be '1.2.3'
      $props['FileVersion'] | Should -Be '1.2.3.98'
    }

    It 'evaluates property group condition expressions' {
      $testProj = Join-Path $PATHS.BuildFiles 'Project\test.csproj' -Resolve
        
      $props = Get-ProjectProperties $testProj 
      $props['TestProp'] | Should -Be 'Initial Value'

      $props = Get-ProjectProperties $testProj @{ ForceDefault = 'True' }
      $props['TestProp'] | Should -Be 'Default Value'

      $props = Get-ProjectProperties $testProj @{ Configuration = 'Debug' }
      $props['PackageVersion'] | Should -Be '1.2.3-rc98-debug' 
        
      $props = Get-ProjectProperties $testProj @{ Configuration = 'Release'; ReleaseMode = 'Release' }
      $props['PackageVersion'] | Should -Be '1.2.3' 
    }

    It 'evaluates property condition expressions' {
      $testProj = Join-Path $PATHS.BuildFiles 'Project\test.csproj' -Resolve

      $props = Get-ProjectProperties $testProj @{ ExcludeProp = 'True' }
      $props['TestProp'] | Should -Be 'Default Value' 
    }

    It 'evaluates import condition expressions' {
      $testProj = Join-Path $PATHS.BuildFiles 'Project\test.csproj' -Resolve

      $props = Get-ProjectProperties $testProj @{ IncludeSpecialProps = 'True' }
      $props['TestProp'] | Should -Be 'Special Value' 
    }
  }

}