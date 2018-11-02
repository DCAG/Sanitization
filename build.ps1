#Requires -Modules psake

# Builds the module by invoking psake on the build.psake.ps1 script.
$BuildFile = Join-Path -Path $PSScriptRoot -ChildPath 'build.psake.ps1'
Invoke-PSake -buildFile $BuildFile 
#Invoke-PSake -buildFile $BuildFile -taskList Clean #Build
#Invoke-PSake -buildFile $BuildFile -taskList CreateMarkdownHelp #Build
#Invoke-PSake -buildFile $BuildFile -taskList UpdateMarkdownHelp #Build
#Invoke-PSake -buildFile $BuildFile -taskList CreateExternalHelp #Build
