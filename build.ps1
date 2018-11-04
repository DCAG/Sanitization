#Requires -Modules psake

# Builds the module by invoking psake on the build.psake.ps1 script.
$BuildFile = Join-Path -Path $PSScriptRoot -ChildPath 'build.psake.ps1'
Invoke-PSake -buildFile $BuildFile -ErrorAction Stop
#Invoke-PSake -buildFile $BuildFile -taskList Clean
#Invoke-PSake -buildFile $BuildFile -taskList CreateMarkdownHelp
#Invoke-PSake -buildFile $BuildFile -taskList UpdateMarkdownHelp
#Invoke-PSake -buildFile $BuildFile -taskList CreateExternalHelp -ErrorAction Stop
