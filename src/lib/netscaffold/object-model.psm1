enum CodeLanguage {
  Unknown     = 0

  CSharp      = 1
  VisualBasic = 2
  JavaScript  = 3
  TypeScript  = 4
  PowerShell  = 5
  SQL         = 6
  FSharp      = 7
  CPlusPlus   = 8
}

class ProjectInfo {
  [string]$Name
  [guid]$TypeGuid
  [CodeLanguage]$Language
  [System.Func[string,bool]] hidden $TestDelegate

  ProjectInfo([string]$Name, [guid]$TypeGuid, [CodeLanguage]$Language, [System.Func[string,bool]]$Test) {
    $this.Name = $Name
    $this.TypeGuid = $TypeGuid
    $this.Language = $Language
    $this.TestDelegate = $Test
  }

  [bool]Test([string]$ProjectFilePath) {
    return $this.TestDelegate.Invoke($ProjectFilePath)
  } 

  [ProjectInfo]Clone() {
    return [ProjectInfo]::new($this.Name, $this.TypeGuid, $this.Language, $null)
  }
}

class DynamicProjectInfo : ProjectInfo {

  [bool]$IsDynamic = $true
  [System.Action[string,ProjectInfo]] hidden $FactoryDelegate

  DynamicProjectInfo(
    [string]$Name,
    [guid]$TypeGuid, 
    [CodeLanguage]$Language, 
    [System.Func[string,bool]]$Test,
    [System.Action[string,ProjectInfo]]$Factory) 
  : base($Name, $TypeGuid, $Language, $Test) {
    $this.Name = $Name
    $this.TypeGuid = $TypeGuid
    $this.Language = $Language
    $this.TestDelegate = $Test
    $this.FactoryDelegate = $Factory
  }

  [ProjectInfo]Create([string]$ProjectFilePath) {
    $projectInfo = [ProjectInfo]::new(
      $this.Name,
      $this.TypeGuid,
      $this.Language,
      $this.TestDelegate
    )

    $this.FactoryDelegate.Invoke($ProjectFilePath, $projectInfo)
    return $projectInfo
  }
}