Import-Module ([System.IO.Path]::Combine([string[]]@($PSScriptRoot, '..', '..', 'psutil', 'psutil.psd1')))
Import-Module ([System.IO.Path]::Combine([string[]]@($PSScriptRoot, '..', 'modules', 'project-registry.psm1')))
Import-Module ([System.IO.Path]::Combine([string[]]@($PSScriptRoot, '..', 'modules', 'msbuild-evaluator.psm1')))
 
# See https://www.codeproject.com/Reference/720512/List-of-Visual-Studio-Project-Type-GUIDs for future reference

$GUIDS = @{
  SolutionFolder  = '2150E333-8FDC-42A3-9474-1A3956D46DE8'

  # In fact a very contentious issue: https://github.com/dotnet/project-system/issues/1821
  CSharpFramework = 'FAE04EC0-301F-11D3-BF4B-00C04F79EFBC'
  CSharpCore      = '9A19103F-16F7-4668-BE54-9A1E7A4F7556'

  VBFrameWork     = 'F184B08F-C81C-45F6-A57F-5ABD9991F28F'
  VBCore          = '778DAE3C-4631-46EA-AA77-85C1314464D9'

  # Yes, same GUID is for both C# and VB shard projects
  Shared          = 'D954291E-2A0B-460D-934E-DC6B0785DB48'

  SqlServer       = '00D1A9C2-B5F0-4AF3-8072-F6C62B433612'

  Nodejs          = '9092AA53-FB77-4645-B42D-1CCCA6BD08BD'
}

# From https://www.codeproject.com/Reference/720512/List-of-Visual-Studio-Project-Type-GUIDs,
# https://stackoverflow.com/a/53485177/842685
$GUIDMap = @{
  '06A35CCD-C46D-44D5-987B-CF40FF872267' = 'Deployment Merge Module'
  '14822709-B5A1-4724-98CA-57A101D1B079' = 'Workflow (C#)'
  '20D4826A-C6FA-45DB-90F4-C717570B9F32' = 'Legacy (2003) Smart Device (C#)'
  '2150E333-8FDC-42A3-9474-1A3956D46DE8' = 'Solution Folder'
  '262852C6-CD72-467D-83FE-5EEB1973A190' = 'JScript'
  '2DF5C3F4-5A5F-47a9-8E94-23B4456F55E2' = 'XNA (XBox)'
  '32F31D43-81CC-4C15-9DE6-3FC5453562B6' = 'Workflow Foundation'
  '349C5851-65DF-11DA-9384-00065B846F21' = 'ASP.NET MVC 5 / Web Application'
  '3AC096D0-A1C2-E12C-1390-A8335801FDAB' = 'Test'
  '3D9AD99F-2412-4246-B90B-4EAA41C64699' = 'Windows Communication Foundation (WCF)'
  '3EA9E505-35AC-4774-B492-AD1749C4943A' = 'Deployment Cab'
  '4D628B5B-2FBC-4AA6-8C16-197242AEB884' = 'Smart Device (C#)'
  '4F174C21-8C12-11D0-8340-0000F80270F8' = 'Database (other project types)'
  '54435603-DBB4-11D2-8724-00A0C9A8B90C' = 'Visual Studio 2015 Installer Project Extension'
  '581633EB-B896-402F-8E60-36F3DA191C85' = 'LightSwitch Project'
  '593B0543-81F6-4436-BA1E-4747859CAAE2' = 'SharePoint (C#)'
  '603C0E0B-DB56-11DC-BE95-000D561079B0' = 'ASP.NET MVC 1'
  '60DC8134-EBA5-43B8-BCC9-BB4BC16C2548' = 'Windows Presentation Foundation (WPF)'
  '66A26720-8FB5-11D2-AA7E-00C04F688DDE' = 'Project Folders'
  '68B1623D-7FB9-47D8-8664-7ECEA3297D4F' = 'Smart Device (VB.NET)'
  '6BC8ED88-2882-458C-8E55-DFD12B67127B' = 'Xamarin.iOS / MonoTouch'
  '6D335F3A-9D43-41b4-9D22-F6F17C4BE596' = 'XNA (Windows)'
  '6EC3EE1D-3C4E-46DD-8F32-0CC8E7565705' = 'F# (forces use of SDK project system)'
  '76F1466A-8B6D-4E39-A767-685A06062A39' = 'Windows Phone 8/8.1 Blank/Hub/Webview App'
  '778DAE3C-4631-46EA-AA77-85C1314464D9' = 'VB.NET (forces use of SDK project system)'
  '786C830F-07A1-408B-BD7F-6EE04809D6DB' = 'Portable Class Library'
  '82B43B9B-A64C-4715-B499-D71E9CA2BD60' = 'Extensibility'
  '8BB0C5E8-0616-4F60-8E55-A43933E57E9C' = 'LightSwitch'
  '8BB2217D-0F2D-49D1-97BC-3654ED321F3B' = 'ASP.NET 5'
  '8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942' = 'C++'
  '95DFC527-4DC1-495E-97D7-E94EE1F7140D' = 'IL project'
  '978C614F-708E-4E1A-B201-565925725DBA' = 'Deployment Setup'
  '9A19103F-16F7-4668-BE54-9A1E7A4F7556' = 'C# (forces use of SDK project system)'
  'A1591282-1198-4647-A2B1-27E5FF5F6F3B' = 'Silverlight'
  'A5A43C5B-DE2A-4C0C-9213-0A381AF9435A' = 'Universal Windows Class Library'
  'A860303F-1F3F-4691-B57E-529FC101A107' = 'Visual Studio Tools for Applications (VSTA)'
  'A9ACE9BB-CECE-4E62-9AA4-C7E7C5BD2124' = 'Database'
  'AB322303-2255-48EF-A496-5904EB18DA55' = 'Deployment Smart Device Cab'
  'B69E3092-B931-443C-ABE7-7E7B65F2A37F' = 'Micro Framework'
  'BAA0C2D2-18E2-41B9-852F-F413020CAA33' = 'Visual Studio Tools for Office (VSTO)'
  'BC8A1FFA-BEE3-4634-8014-F334798102B3' = 'Windows Store (Metro) Apps & Components'
  'BF6F8E12-879D-49E7-ADF0-5503146B24B8' = 'Dynamics 2012 AX C# in AOT'
  'C089C8C0-30E0-4E22-80C0-CE093F111A43' = 'Windows Phone 8/8.1 App (C#)'
  'C1CDDADD-2546-481F-9697-4EA41081F2FC' = 'Office/SharePoint App'
  'C252FEB5-A946-4202-B1D4-9916A0590387' = 'Visual Database Tools'
  'CB4CE8C6-1BDB-4DC7-A4D3-65A1999772F8' = 'Legacy (2003) Smart Device (VB.NET)'
  'D399B71A-8929-442a-A9AC-8BEC78BB2433' = 'XNA (Zune)'
  'D59BE175-2ED0-4C54-BE3D-CDAA9F3214C8' = 'Workflow (VB.NET)'
  'D954291E-2A0B-460D-934E-DC6B0785DB48' = 'Windows Store App Universal'
  'DB03555F-0C8B-43BE-9FF9-57896B3C5E56' = 'Windows Phone 8/8.1 App (VB.NET)'
  'E24C65DC-7377-472B-9ABA-BC803B73C61A' = 'Web Site'
  'E3E379DF-F4C6-4180-9B81-6769533ABE47' = 'ASP.NET MVC 4'
  'E53F8FEA-EAE0-44A6-8774-FFD645390401' = 'ASP.NET MVC 3'
  'E6FDF86B-F3D1-11D4-8576-0002A516ECE8' = 'J#'
  'EC05E597-79D4-47f3-ADA0-324C4F7C7484' = 'SharePoint (VB.NET)'
  'EFBA0AD7-5A72-4C68-AF49-83D382785DCF' = 'Xamarin.Android / Mono for Android'
  'F135691A-BF7E-435D-8960-F99683D2D49C' = 'Distributed System'
  'F184B08F-C81C-45F6-A57F-5ABD9991F28F' = 'VB.NET'
  'F2A71F9B-5D33-465A-A702-920D77279786' = 'F#'
  'F5B4F3BC-B597-4E2B-B552-EF5D8A32436F' = 'MonoTouch Binding'
  'F85E285D-A4E0-4152-9332-AB1D724D3325' = 'ASP.NET MVC 2'
  'F8810EC1-6754-47FC-A15F-DFABD2E3FA90' = 'SharePoint Workflow'
  'FAE04EC0-301F-11D3-BF4B-00C04F79EFBC' = 'C#'
}

# ==========================================
#  Shared projects
# ==========================================
Add-ProjectType 'C# Shared Project' 'D954291E-2A0B-460D-934E-DC6B0785DB48' CSharp {
  param([string]$ProjectPath)

  # File extension must be 'shproj'
  if ([System.IO.Path]::GetExtension($ProjectPath).ToLower() -ne '.shproj') {
    return $false
  }

  # File contents must include 'Microsoft.CodeSharing.CSharp.targets'
  $contents = [System.IO.File]::ReadAllText($ProjectPath)
  if ($contents.IndexOf('Microsoft.CodeSharing.CSharp.targets') -eq -1) {
    return $false
  }

  return $true
}

Add-ProjectType 'VB.NET Shared Project' 'D954291E-2A0B-460D-934E-DC6B0785DB48' VisualBasic {
  param([string]$ProjectPath)

  # File extension must be 'shproj'
  if ([System.IO.Path]::GetExtension($ProjectPath).ToLower() -ne '.shproj') {
    return $false
  }

  # File contents must include 'Microsoft.CodeSharing.CSharp.targets'
  $contents = [System.IO.File]::ReadAllText($ProjectPath)
  if ($contents.IndexOf('Microsoft.CodeSharing.VisualBasic.targets') -eq -1) {
    return $false
  }

  return $true
}

# ==========================================
#  Basic C# Projects
# ==========================================
Add-ProjectType 'C# .NET Framework Library' $GUIDS.CSharpFramework CSharp {
  param([string]$ProjectPath)

  # File extension must be '.csproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.csproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $toolsVersion = $projectElement.ToolsVersion
  $xmlns = $projectElement.xmlns

  if (Test-IsEmpty $toolsVersion) { return $false }
  if (Test-IsEmpty $xmlns       ) { return $false }

  # Must NOT have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $false }

  return $true
}
 
Add-ProjectType 'C# .NET Framework Console' $GUIDS.CSharpFramework CSharp {
  param([string]$ProjectPath)

  # File extension must be '.csproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.csproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $toolsVersion = $projectElement.ToolsVersion
  $xmlns = $projectElement.xmlns

  if (Test-IsEmpty $toolsVersion) { return $false }
  if (Test-IsEmpty $xmlns       ) { return $false }

  # Must have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $true }

  return $false
}

Add-ProjectType 'C# .NET Core Library' $GUIDS.CSharpCore CSharp {
  param([string]$ProjectPath)

  # File extension must be '.csproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.csproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $sdk = $projectElement.Sdk

  # Must have Microsoft.NET.Sdk
  if (Test-IsEmpty $sdk) { return $false }
  if ('Microsoft.NET.Sdk' -ne $sdk) { return $false }

  # Must NOT have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $false }

  return $true
}

Add-ProjectType 'C# .NET Core Console' $GUIDS.CSharpCore CSharp {
  param([string]$ProjectPath)

  # File extension must be '.csproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.csproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $sdk = $projectElement.Sdk

  # Must have Microsoft.NET.Sdk
  if (Test-IsEmpty $sdk) { return $false }
  if ('Microsoft.NET.Sdk' -ne $sdk) { return $false }

  # Must have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $true }

  return $false
}

Add-ProjectType 'C# ASP.NET Core' $GUIDS.CSharpCore CSharp {
  param([string]$ProjectPath)

  # File extension must be '.csproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.csproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $sdk = $projectElement.Sdk

  if (Test-IsEmpty $sdk) { return $false }

  # Assuming anything with Microsoft.NET.Sdk.Web is ASP.NET
  if ('Microsoft.NET.Sdk.Web' -eq $sdk) { return $true } 

  return $false
}

# ==========================================
#  Basic VB Projects
# ==========================================
Add-ProjectType 'VB .NET Framework Library' $GUIDS.VBFrameWork VisualBasic {
  param([string]$ProjectPath)

  # File extension must be '.vbproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.vbproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $toolsVersion = $projectElement.ToolsVersion
  $xmlns = $projectElement.xmlns

  if (Test-IsEmpty $toolsVersion) { return $false }
  if (Test-IsEmpty $xmlns       ) { return $false }

  # Must NOT have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $false }

  return $true
}

Add-ProjectType 'VB .NET Framework Console' $GUIDS.VBFrameWork VisualBasic {
  param([string]$ProjectPath)

  # File extension must be '.vbproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.vbproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $toolsVersion = $projectElement.ToolsVersion
  $xmlns = $projectElement.xmlns

  if (Test-IsEmpty $toolsVersion) { return $false }
  if (Test-IsEmpty $xmlns       ) { return $false }

  # Must have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $true }

  return $false
}

Add-ProjectType 'VB .NET Core Library' $GUIDS.VBCore VisualBasic {
  param([string]$ProjectPath)

  # File extension must be '.vbproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.vbproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $sdk = $projectElement.Sdk

  # Must have Microsoft.NET.Sdk
  if (Test-IsEmpty $sdk) { return $false }
  if ('Microsoft.NET.Sdk' -ne $sdk) { return $false }

  # Must NOT have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $false }

  return $true
}

Add-ProjectType 'VB .NET Core Console' $GUIDS.VBCore VisualBasic {
  param([string]$ProjectPath)

  # File extension must be '.vbproj'
  if ([IOPath]::GetExtension($ProjectPath) -ne '.vbproj') { return $false }

  $xml = [xml]::new()
  $xml.Load($ProjectPath)

  $projectElement = $xml.DocumentElement
  if ($projectElement.LocalName -ne 'Project') { return $false }
  $sdk = $projectElement.Sdk

  # Must have Microsoft.NET.Sdk
  if (Test-IsEmpty $sdk) { return $false }
  if ('Microsoft.NET.Sdk' -ne $sdk) { return $false }

  # Must have OutputType = 'exe' property
  $projectProps = Get-ProjectProperties $ProjectPath
  if ($projectProps['OutputType'] -eq 'exe') { return $true }

  return $false
}
 
# ==========================================
#  SQL projects
# ==========================================

Add-ProjectType 'SQL Server Project' $GUIDS.SqlServer SQL {
  param([string]$ProjectPath)

  # File extension must be '.sqlproj'
  return ([IOPath]::GetExtension($ProjectPath) -eq '.sqlproj')
}
  
# ==========================================
#  Nodejs projects
# ==========================================
Add-ProjectType 'Nodejs' $GUIDS.Nodejs JavaScript -Test {
  param([string]$ProjectPath)

  # File extension must be '.njsproj'
  return ([IOPath]::GetExtension($ProjectPath) -eq '.njsproj')
} -Factory {
  param([string]$ProjectPath, $ProjectInfo)
  $projectDir = Split-Path $ProjectPath -Parent
  $tsconfig   = Get-ChildItem $projectDir -Filter 'tsconfig.json'

  if($null -ne $tsconfig) {
    $ProjectInfo.Language = 'TypeScript'
  }
}
  
# ==========================================
#  Miscellaneous projects
# ==========================================
# Detect by embedded project type guid
Add-ProjectType 'Embedded Guid' -Language Unknown -Test {
  param([string]$ProjectPath)
  $projectProps = Get-ProjectProperties $ProjectPath
  $typeGuids = $projectProps.ProjectTypeGuids
  if (Test-IsEmpty $typeGuids) { return $false }

  $strGuids = $typeGuids.Split(';')
  $lastGuid = $strGuids | Select-Object -Last 1
  $guid = [guid]::Empty

  return ([guid]::TryParse($lastGuid, [ref]$guid)) 
} -Factory {
  param([string]$ProjectPath, $ProjectInfo)

  $projectProps = Get-ProjectProperties $ProjectPath
  $typeGuids = $projectProps.ProjectTypeGuids
  if (Test-IsEmpty $typeGuids) { return $false }

  $strGuids = $typeGuids.Split(';')
  $lastGuid = $strGuids | Select-Object -Last 1
  $realGuid = [guid]$lastGuid
  $normalizedGuid = $realGuid.ToString('B').ToUpper()

  $ProjectInfo.TypeGuid = $realGuid
  $ProjectInfo.Name = $GUIDMap[$normalizedGuid]

  $ext = [IOPath]::GetExtension($ProjectPath)
  if (($ProjectInfo.Name -contains 'C#') -or ($ext -eq '.csproj')) {
    $ProjectInfo.Language = 'CSharp'
  }
  elseif (($ProjectInfo.Name -contains 'VB.NET') -or ($ext -eq '.vbproj')) {
    $ProjectInfo.Language = 'VisualBasic'
  } 
}