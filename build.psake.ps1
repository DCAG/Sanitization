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

Task default -depends psscriptanalyzer
#Task default -depends build

Task clean {
    Remove-Item "$WorkingDir\bin"
}

Task test -depends build {
    $ModuleManifest = Test-ModuleManifest -Path "$ModuleName.psd1"
    $ModuleManifest | fl * -Force
    mkdir "$WorkingDir\bin\$ModuleName\$ModuleManifest" -Force
}

Task build -depends psscriptanalyzer {
}



Task deploy -depends test {

}

Task psscriptanalyzer {
    Invoke-ScriptAnalyzer -Path "$WorkingDir\Source" -Recurse
}