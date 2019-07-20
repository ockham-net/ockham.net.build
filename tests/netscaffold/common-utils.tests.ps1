$srcRoot = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'src', 'netscaffold', 'modules')
Import-Module Pester

if($null -ne (Get-Module common-utils)) { 
  Write-Host "Unloading existing common-utils module" -ForegroundColor Cyan
  Remove-Module common-utils
}
Import-Module (Join-Path $srcRoot 'common-utils.psm1')

Describe 'common-utils' {

  Context Test-IsEmpty {
    It 'returns true for $null' {
      $result = Test-IsEmpty $null
      $result | Should -Be $true
    }

    It 'returns true for empty string' {
      $result = Test-IsEmpty $([string]::Empty)
      $result | Should -Be $true
    }

    It 'returns true for whitespace string' {
      $result = Test-IsEmpty " `r`n `t "
      $result | Should -Be $true
    }

    It 'returns false for non-empty string' {
      $result = Test-IsEmpty a
      $result | Should -Be $false
    } 
  }

  Context Test-IsNotEmpty {
    It 'returns false for $null' {
      $result = Test-IsNotEmpty $null
      $result | Should -Be $false
    }

    It 'returns false for empty string' {
      $result = Test-IsNotEmpty $([string]::Empty)
      $result | Should -Be $false
    }

    It 'returns false for whitespace string' {
      $result = Test-IsNotEmpty " `r`n `t "
      $result | Should -Be $false
    }

    It 'returns true for non-empty string' {
      $result = Test-IsNotEmpty a
      $result | Should -Be $true
    } 
  } 

  Context Add-Accelerator {
    It 'adds a new accelerator' {
      # Accelerator does not exist yet
      { [type]'map' } | Should -Throw

      Add-Accelerator map 'System.Collections.Generic.Dictionary[String,Object]'

      $expected = [System.Collections.Generic.Dictionary`2].MakeGenericType(@([string], [object]))
      [type]'map' | Should -Be $expected
    }

    It 'adds does not overwrite an accelerator' {
      # psobject accelerator is already set
      [psobject].FullName | Should -Be 'System.Management.Automation.PSObject'

      { Add-Accelerator psobject [string] -ErrorAction Stop } | Should -Throw

      # psobject accelerator has not been changed
      [psobject].FullName | Should -Be 'System.Management.Automation.PSObject'
    }

    It 'ignores adding the same alias-type pair more than once' {
       # Accelerator does not exist yet
       { [type]'map2' } | Should -Throw

       Add-Accelerator map2 'System.Collections.Generic.Dictionary[String,Object]'
 
       $expected = [System.Collections.Generic.Dictionary`2].MakeGenericType(@([string], [object]))
       [type]'map2' | Should -Be $expected

       { Add-Accelerator map2 'System.Collections.Generic.Dictionary[String,Object]' } | Should -Not -Throw
       [type]'map2' | Should -Be $expected
    }

    It 'overwrites an existing accelerator if requested' {
      # psobject accelerator is already set
      [psobject].FullName | Should -Be 'System.Management.Automation.PSObject'

      { Add-Accelerator psobject [string] -ErrorAction Stop } | Should -Throw

      # psobject accelerator has not been changed
      [psobject].FullName | Should -Be 'System.Management.Automation.PSObject'
    }
  }
 
  <#
  Removing accelerators is not yet supported
  
  Context Remove-Accelerator {
    It 'Removes an existing accelerator' {
      # Accelerator does not exist yet
      { [type]'map2' } | Should -Throw

      Add-Accelerator map2 'System.Collections.Generic.Dictionary[String,Object]'

      $expected = [System.Collections.Generic.Dictionary`2].MakeGenericType(@([string], [object]))

      # Now accelerator exists as defined
      [type]'map2' | Should -Be $expected

      Remove-Accelerator map2

      # Accelerator is gone now 
      { [type]'map2' } | Should -Throw
    } 
  }
  #>
}
