#region Functions
Function InstallRequiredModules {
    $RequiredModules = 'Pester', 'platyPS', 'PSScriptAnalyzer','PowerShellGet','PackageManagement'
    $InstalledModule = @(Get-InstalledModule -Name $RequiredModules -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty Name)
    $ModuleToInstall = Compare-Object -ReferenceObject $RequiredModules -DifferenceObject $InstalledModule | Select-Object -ExpandProperty 'InputObject'
    if($ModuleToInstall.Count -gt 0){
        Install-Module -Name $ModuleToInstall -Scope 'CurrentUser' -Force -AllowClobber -ErrorAction 'Stop'
    }

    Remove-Module -Name 'PowerShellGet', 'PackageManagement' -Force
    
    $ModulesToLoad = $RequiredModules | Where-Object {$_ -notin 'PackageManagement','PowerShellGet'}
    Import-Module -Name $ModulesToLoad -Force -ErrorAction 'Stop'
    
    # Loading the latest PowerShellGet package provider
    # Ref:  https://github.com/PowerShell/PowerShellGet/issues/246#issuecomment-375693410
    $PSGetVersion = Get-PackageProvider 'PowerShellGet' -ListAvailable | Sort-Object 'Version' | Select-Object -Last 1 -ExpandProperty 'Version'
    Import-PackageProvider -Name 'PowerShellGet' -RequiredVersion $PSGetVersion -Force
}

Function RunPSScriptAnalyzer {
    param($Path)

    $Analysis = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Warning
    $Errors = $Analysis | Where-Object {$_.Severity -eq 'Error'}
    $Warnings = $Analysis | Where-Object {$_.Severity -eq 'Warning'}

    if ($null -eq $Errors -and $null -eq $Warnings) {
        'PSScriptAnalyzer passed without errors or warnings'
    }
    else{
        $Analysis
    
        if ($Errors) {
            Write-Error 'One or more Script Analyzer errors were found. Build cannot continue!'
        }
        
        if ($Warnings) {
            Write-Error 'One or more Script Analyzer warnings were found. These should be corrected.'
        }
    }
}

Function DisplaySystemInformation {
    'PowerShell Version:'
    $PSVersionTable
    ''
    'System Information:'
    [environment]::OSVersion | Format-List
}

Function UploadTestResultsToAppVeyor {
    param($TestResults)

    if (-not $env:APPVEYOR_JOB_ID) {
        return
    }

    Invoke-WebRequest "https://ci.appveyor.com/api/testresults/nunit/$env:APPVEYOR_JOB_ID" -InFile $TestResults
    #$WebClient = New-Object 'System.Net.WebClient'
    #$WebClient.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$env:APPVEYOR_JOB_ID", $TestResults)
}
#endregion

####################
#   Psake build
####################

Properties {
    $ModuleName = 'Sanitization'
    $WorkingDir = $PSScriptRoot
    
    $TestPublish = $true

    $TestsFolder = Join-Path -Path $WorkingDir -ChildPath 'Tests'
    $DocsFolder = Join-Path -Path $WorkingDir -ChildPath 'docs'
    $RefFolder = Join-Path -Path $DocsFolder -ChildPath 'reference'
    $MdHelpPath = Join-Path -Path $RefFolder -ChildPath 'functions'
    $BinFolder = Join-Path -Path $WorkingDir -ChildPath 'bin'
    $TestResultsXml = Join-Path -Path $BinFolder -ChildPath 'TestsResults.xml'
    $SourceFolder = Join-Path -Path $WorkingDir -ChildPath 'Source'
    $ManifestFile = Join-Path -Path $SourceFolder -ChildPath "$ModuleName.psd1"
    $ModuleManifest = Import-PowerShellDataFile $ManifestFile
    $ModuleVersion = $ModuleManifest.ModuleVersion
    $BinModuleFolder = Join-Path -Path $BinFolder -ChildPath $ModuleName
    $ModuleVersionFolder = Join-Path -Path $BinModuleFolder -ChildPath $ModuleVersion
    $ExternalHelpFolder = Join-Path -Path $ModuleVersionFolder -ChildPath 'en-US'
}

Task default -depends 'Publish' #'CreateExternalHelp'

FormatTaskName -format @"
-----------
{0}
-----------
"@

# To run manually
Task 'UpdateMarkdownHelp' -Depends 'Test' {
    Update-MarkdownHelpModule -Path $MdHelpPath
}

# To run manually
Task 'CreateMarkdownHelp' -depends 'Test' {
    New-MarkdownHelp -Module $ModuleName -OutputFolder $MdHelpPath
}

Task 'Publish' -Depends 'CreateExternalHelp' {
    'Publishing version [{0}] to PSGallery...' -f $ModuleVersion
    Publish-Module -Name $ModuleName -NuGetApiKey $env:PSGalleryAPIKey -Repository 'PSGallery' -Verbose -WhatIf:$TestPublish
}

Task 'CreateExternalHelp' -Depends 'Test' -Description 'Create module help from markdown files' {
    if(-not (Test-Path $MdHelpPath)){
        Write-Error 'There is no markdown help folder to create external help files from' -RecommendedAction 'Run task "CreateMarkdownHelp"'
        return
    }

    New-ExternalHelp -Path $MdHelpPath -OutputPath $ExternalHelpFolder -Force
}

# Default
Task 'Test' -Depends 'Build' {
    $PathSeparator = [IO.Path]::PathSeparator # Usually ';'
    $ModulePaths = "$BinFolder$PathSeparator$env:PSModulePath" -split $PathSeparator | Select-Object -Unique
    $env:PSModulePath = $ModulePaths -join $PathSeparator
    Import-Module -Name $ModuleName

    $TestResults = Invoke-Pester -Path $TestsFolder -PassThru -OutputFile $TestResultsXml -OutputFormat NUnitXml 

    UploadTestResultsToAppVeyor -TestResults $TestResultsXml

    if ($TestResults.FailedCount -gt 0) {
        Write-Error -Message 'One or more tests failed. Build cannot continue!'
    }
}

Task 'Build' -Depends 'PSScriptAnalyzer', 'Clean' {
    New-Item $ModuleVersionFolder -ItemType Directory -Force

    # .psm1
    $BinModuleFile = Join-Path -Path $ModuleVersionFolder -ChildPath "$ModuleName.psm1"
    Get-ChildItem $SourceFolder -Recurse -Directory | Get-ChildItem -File -Recurse | Get-Content | Out-File $BinModuleFile
    'Export-ModuleMember -Function * -Alias * -Cmdlet *' | Out-File $BinModuleFile -Append
    
    # .psd1
    Copy-Item -Path $ManifestFile -Destination $ModuleVersionFolder
    $ModuleManifestFile = Join-Path -Path $ModuleVersionFolder -ChildPath "$ModuleName.psd1"
    Test-ModuleManifest -Path $ModuleManifestFile
}

Task 'PSScriptAnalyzer' -Depends 'Init' {
    RunPSScriptAnalyzer -Path $SourceFolder
}

Task 'Clean' {
    Remove-Module -Name $ModuleName -ErrorAction SilentlyContinue
    
    if(Test-Path $BinFolder -ErrorAction SilentlyContinue){
        Remove-Item $BinFolder -Recurse -Force
    }
}

Task 'Init' {
    DisplaySystemInformation
    InstallRequiredModules
}