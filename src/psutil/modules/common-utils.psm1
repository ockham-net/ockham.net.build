$Accelerators = [PowerShell].Assembly.GetType("System.Management.Automation.TypeAccelerators")

# $CompletionCompleters = [System.Management.Automation.CompletionCompleters]
# $mClearCache = $CompletionCompleters.GetMethod('UpdateTypeCacheOnAssemblyLoad', [System.Reflection.BindingFlags]'NonPublic,Static')

# function Clear-TypeCache {
#   $mClearCache.Invoke($null, @( `
#     [System.AppDomain]::CurrentDomain, `
#     [System.AssemblyLoadEventArgs]::new([powershell].Assembly) `
#   ))
# }

<#
  Test whether the input value is null, or an empty or whitespace string
#>  
function Test-IsEmpty ([string]$Value) { return [string]::IsNullOrWhiteSpace($Value) }
 
<#
  Test whether the input value is a non-null string with no-whitespace characters
#>  
function Test-IsNotEmpty ([string]$Value) { return ![string]::IsNullOrWhiteSpace($Value) }

<#
  Define a new type accelerator (type alias)
#>
function Add-Accelerator {

  [cmdletbinding()]
  param([string]$Alias, $Type, [switch]$Force) 

  $existing   = ($Accelerators::Get)
  $targetType = ([type]$Type)
  if ($existing.ContainsKey($Alias)) {
    if ($Force) {
      $Accelerators::Remove($Alias)
    }
    else {
      if($targetType -eq $existing[$Alias]) {
        # Ignore adding the same alias-type pair again. 
        Write-Debug "Key '$Alias' is already associated with requested type $($targetType.FullName)"
        return
      }
      
      Write-Error "A type accelerator with the key '$Alias' already exists"
      return
    }
  }
  $Accelerators::Add($Alias, ([type]$Type))
}

function New-PSObject {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)][HashTable]$Property)

  return New-Object psobject -Property $Property
}

<#
Removing accelerators is not yet supported, despite the existence
of the [TypeAccelerators]::Remove method.

https://github.com/PowerShell/PowerShell/blob/b768d87081bbd04c361a9d27c23782726d4ecf12/src/System.Management.Automation/engine/parser/TypeResolver.cs#L850

function Remove-Accelerator   {
  
  [cmdletbinding()]
  param([string]$Alias)

  if (($Accelerators::Get).ContainsKey($Alias)) {
    $Accelerators::Remove($Alias)
    Clear-TypeCache
  } else {
    Write-Error "Cannot find an acceleator with name '$Alias'"
  }
}
 
Add-Accelerator list 'System.Collections.Generic.List`1'
Add-Accelerator ienumerable 'System.Collections.Generic.IEnumerable`1'

$OnRemoveScript = { 
  Remove-Accelerator list
  Remove-Accelerator ienumerable
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
#>

Export-ModuleMember Test-IsEmpty, Test-IsNotEmpty, Add-Accelerator, New-PSObject #, Remove-Accelerator
