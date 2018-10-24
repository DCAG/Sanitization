Properties {
    $ModuleName = 'Sanitization'
    $WorkingDir = $PSScriptRoot
}

TaskSetup {
    "Executing task setup"
}

TaskTearDown {
    "Executing task tear down"
}

Task default -depends test
#Task default -depends build

Task publish {

}

Task test -depends deploy {
    Invoke-Pester "$WorkingDir\Tests"
}

Task deploy -depends build {
    Import-Module "$WorkingDir\bin\$ModuleName"
}

Task build -depends psscriptanalyzer, clean {
    $SourceFolder = "$WorkingDir\Source\"
    $ManifestFile = "$SourceFolder\$ModuleName.psd1"
    
    $ModuleManifest = Test-ModuleManifest -Path $ManifestFile
    $ModuleVersion = $ModuleManifest.Version
    $OutputFolder = "$WorkingDir\bin\$ModuleName\$ModuleVersion"
    mkdir $OutputFolder -Force
    Copy-Item -Path "$SourceFolder\*" -Destination "$OutputFolder\" -Recurse
}

Task psscriptanalyzer {
    Invoke-ScriptAnalyzer -Path "$WorkingDir\Source" -Recurse
}

Task clean {
    Remove-Module ModuleName -ErrorAction SilentlyContinue
    $binFolder = "$WorkingDir\bin"
    if(Test-Path $binFolder -ErrorAction SilentlyContinue){
        Remove-Item "$WorkingDir\bin" -Recurse -Force
    }
}