# ==========================================
#  Project file parsing
# ==========================================
# Get the resolved build properties from a project, walking all references, substituting
# values in expressions, and evaluating conditions on both property groups and properties
function Get-ProjectProperties ([string]$ProjectPath, [hashtable]$BuildProps) { }

# Used to register a new project type. Used by Add-Project to detect the project type
function Add-ProjectType(
  [string]$ProjectTypeName,
  [guid]$ProjectTypeGuid,
  [string]$Language,
  [scriptblock]$Detect
) { }

function Get-ProjectType {}

# Determine the project type for a given project file
function Resolve-ProjectType ([string]$ProjectFilePath, [switch]$GuidOnly) { }

# ==========================================
#  Solution file manipulation
# ==========================================
# Create a blank Visual Studio solution file 
function New-Solution([string]$SolutionDir, [string]$SolutionName) { }

# Get the tree of all projects in a solution
function Get-ProjectGraph([string]$SolutionFile) { }

# Add a new solution folder to an existing solution file 
function Add-SolutionFolder([string]$SolutionFile, [string]$FolderPath, [switch]$IgnoreExisting) { }
 
# Add an existing project to an existing solution. Equivalent to Add > Existing Project in Visual Studio
function Add-Project(
  [string]$SolutionFile,
  [string]$ProjectFile, 
  [string]$SolutionFolder,
  [string]$TypeGuid
) { }
