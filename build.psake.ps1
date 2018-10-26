Properties {
    $ModuleName = 'Sanitization'
    $WorkingDir = $PSScriptRoot
    $WorkingDir = Resolve-Path .
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
    $SourceFolder = "$WorkingDir\Source"
    $ManifestFile = "$SourceFolder\$ModuleName.psd1"
    
    $obj = "$WorkingDir\obj"
    mkdir $obj -Force
    Copy-Item -Path $ManifestFile -Destination "$obj\"
    Get-ChildItem $SourceFolder\*\* | Get-Content | Out-File "$obj\$ModuleName.psm1"
    'Export-ModuleMember -Function * -Alias * -Cmdlet *' | Out-File "$obj\$ModuleName.psm1" -Append
    
    $ModuleManifest = Test-ModuleManifest -Path "$obj\$ModuleName.psd1"
    $ModuleVersion  = $ModuleManifest.Version
    $OutputFolder   = "$WorkingDir\bin\$ModuleName\$ModuleVersion"
    mkdir $OutputFolder -Force
    
    Copy-Item -Path "$obj\$ModuleName.psm1" -Destination "$OutputFolder\" -Recurse
    Copy-Item -Path $ManifestFile -Destination "$OutputFolder\" -Recurse
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