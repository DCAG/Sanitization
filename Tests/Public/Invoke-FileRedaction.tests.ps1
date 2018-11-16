Describe 'Invoke-FileRedaction' {
    Context 'Parameters Validation' {
        if(-not $IsCoreCLR){
            $IsWindows = [environment]::OSVersion.Platform -match 'Win'
            $IsLinux = [environment]::OSVersion.Platform -match 'Unix'
        }

        It 'Parameter RedactionRule should not be null [Linux]' -Skip:(-not $IsLinux) {
            Invoke-Expression 'ip addr' | Out-File "TestDrive:\IPConfig.txt"
            {Invoke-FileRedaction -Path "TestDrive:\IPConfig.txt" -RedactionRule $null} | Should -Throw -ExpectedMessage "Cannot bind argument to parameter 'RedactionRule' because it is null"
        }

        It 'Parameter RedactionRule should not be null [Windows]' -Skip:(-not $IsWindows) {
            Invoke-Expression 'IPConfig /All' | Out-File "TestDrive:\IPConfig.txt"
            {Invoke-FileRedaction -Path "TestDrive:\IPConfig.txt" -RedactionRule $null} | Should -Throw -ExpectedMessage "Cannot bind argument to parameter 'RedactionRule' because it is null"
        }
    }    
}