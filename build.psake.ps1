Properties {
    $ModuleName = 'Sanitization'
    $WorkingDir = $PSScriptRoot
}

Task default -depends updatedocumentation
#Task default -depends build

Task publish {

}

Task updatedocumentation -depends test {
    New-MarkdownHelp -Module $ModuleName -OutputFolder "$WorkingDir\docs"
}

Task test -depends build {
    $ModulePaths = "$WorkingDir\bin;$env:PSModulePath" -split ';' | Select-Object -Unique
    $env:PSModulePath = $ModulePaths -join ';'
    
    Import-Module Sanitization

    Invoke-Pester "$WorkingDir\Tests"
}

Task build -depends psscriptanalyzer, clean {
    $SourceFolder = "$WorkingDir\Source\"
    $ManifestFile = "$SourceFolder\$ModuleName.psd1"
    
    $ModuleManifest = Test-ModuleManifest -Path $ManifestFile
    $ModuleVersion  = $ModuleManifest.Version
    $OutputFolder   = "$WorkingDir\bin\$ModuleName\$ModuleVersion"
    mkdir $OutputFolder -Force
    
    Copy-Item -Path $ManifestFile -Destination "$OutputFolder\" -Recurse
    Get-ChildItem $SourceFolder\*\* | Get-Content | Out-File "$OutputFolder\$ModuleName.psm1"

    $ExportedAliases = $ModuleManifest.ExportedAliases.Keys -join ''','''
    $ExportedFunctions = $ModuleManifest.ExportedFunctions.Keys -join ''','''
    'Export-ModuleMember -Function ''{0}'' -Alias ''{1}''' -f $ExportedFunctions, $ExportedAliases | Out-File "$OutputFolder\$ModuleName.psm1" -Append
}

Task psscriptanalyzer {
    Invoke-ScriptAnalyzer -Path "$WorkingDir\Source" -Recurse
}

Task clean {
    Remove-Module $ModuleName -ErrorAction SilentlyContinue
    
    $binFolder = "$WorkingDir\bin"
    if(Test-Path $binFolder -ErrorAction SilentlyContinue){
        Remove-Item $binFolder -Recurse -Force
    }

    $docsFolder = "$WorkingDir\docs"
    if(Test-Path $docsFolder -ErrorAction SilentlyContinue){
        Remove-Item $docsFolder -Recurse -Force
    }
}