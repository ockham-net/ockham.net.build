
Import-Module (Join-Path $PSScriptRoot common-utils.psm1)
Import-Module (Join-Path $PSScriptRoot fs-utils.psm1)

# ==========================================
#  Internal functions
# ==========================================

 #Map of MSBuild operations to corresponding PowerShell operation
# Note: *the keys are regular expressions*
# See https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-conditions

# Note, '!' operator is not replaced because it is identical in powershell

$_buildOps = @( 
  @('=='    , ' -eq ' ),
  @('\!='   , ' -ne ' ),
  @(' And ' , ' -and '),
  @(' Or '  , ' -or ' ),
  @('&gt;=' , ' -ge ' ),
  @('&lt;=' , ' -le ' ),
  @('&gt;'  , ' -gt ' ),
  @('&lt;'  , ' -lt ' ),
  @('>='    , ' -ge ' ),
  @('<='    , ' -le ' ),
  @('>'     , ' -gt ' ),
  @('<'     , ' -lt ' ), 
  @('Exists\s*\(\s*((''[^'']*'')|("[^"]*"))\s*\)', '(Test-Path $1)'),
  @('HasTrailingSlash\s*\(\s*((''[^'']*'')|("[^"]*"))\s*\)', '(($1).EndsWith(''/'') -or ($1).EndsWith(''\''))')
)



# ==========================================
#  Exported functions
# ==========================================

<#
    .SYNOPSIS 
    Substitute current values of existing build properties into a raw build property value expression
#>
function Convert-BuildExpression {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RawString, 
        
    [Parameter(Mandatory = $false)]
    [hashtable]$BuildProps
  )

  if (Test-IsEmpty $RawString) { return $null }
  $result = $RawString
  foreach ($k in $BuildProps.Keys) {
    $result = $result.Replace('$(' + $k + ')', $BuildProps[$k])
  }

  # Now remove any remaining property expressions (they refer to undefined properties)
  $result = [regex]::Replace($result, '\$\(\w*\)', '')

  return $result
}

<#
    .SYNOPSIS 
    Invoke an msbuild condition expression to determine if it is true or false    
#>
function Invoke-BuildExpression {
  param([string]$Expression) 

  foreach ($pair in $_buildOps) {
    $Expression = [regex]::Replace($Expression, $pair[0], $pair[1], 'IgnoreCase') # $Expression.Replace($k, $_buildOps[$k], [StringComparer]::InvariantCultureIgnoreCase)
  }

  $result = $null
  try {
    Write-Debug $Expression
    $result = Invoke-Expression $Expression
  }
  catch { <# ignore #> }

  return $result
}
 
<#
    .SYNOPSIS
    Test an msbuild element condition expression. *Returns true if expression is $null, false if expression is non-null but empty*
#>
function Test-BuildCondition {
  param([object]$Source, [hashtable]$BuildProps)

  if ($null -eq $Source) { return $true; } # No condition, so do include element
  if ($Source -is [System.Xml.XmlElement]) { return Test-BuildCondition $Source.Condition $BuildProps }
  if ($Source -is [string]) {
    $convertedExpression = Convert-BuildExpression $Source $BuildProps
    return Invoke-BuildExpression $convertedExpression
  }
  throw (New-Object System.ArgumentException "Source")
}

<#
    .SYNOPSIS
    Get the resolved build properties from a project, walking all references, substituting
    values in expressions, and evaluating conditions on both property groups and properties
#>
function Get-ProjectProperties {
  param([string]$ProjectPath, [hashtable]$BuildProps)

  $props = @{ }
  $x = New-Object xml
  $x.Load($ProjectPath)
  if ($null -eq $BuildProps) { 
    $BuildProps = @{ }
  }
     
  foreach ($childNode in $x.DocumentElement.ChildNodes) {
    if ($childNode -isnot [System.Xml.XmlElement]) { continue; }
    if (!(Test-BuildCondition $childNode $BuildProps)) { continue; } 

    if ($childNode.Name -eq 'PropertyGroup') { 
      foreach ($propNode in $childNode.ChildNodes) {
        if ($propNode -isnot [System.Xml.XmlElement]) { continue; }
        if (!(Test-BuildCondition $propNode $BuildProps)) { continue; } 
        $BuildProps[$propNode.Name] = $props[$propNode.Name] = Convert-BuildExpression $propNode.InnerText $BuildProps
      }
    }
    elseif ($childNode.Name -eq 'Import') { 
      $relativePath = $childNode.Project
      $fullPath = $(Join-Path $(Split-Path $ProjectPath -Parent) $relativePath -Resolve -ErrorAction SilentlyContinue)
      if (Test-FSPath $fullPath) {
        $subProps = Get-ProjectProperties $fullPath -BuildProps $BuildProps
        foreach ($key in $subProps.Keys) {
          $BuildProps[$key] = $props[$key] = $subProps[$key]
        }
      }
    }
  } 

  return $props
}

Export-ModuleMember Convert-BuildExpression, Invoke-BuildExpression, Test-BuildCondition, Get-ProjectProperties
