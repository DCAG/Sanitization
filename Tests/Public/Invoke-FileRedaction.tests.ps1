Describe 'Invoke-FileRedaction' {
    Context 'Parameters Validation' {
        It 'Parameter RedactionRule should not be null' -Skip:([environment]::OSVersion.Platform -match 'Unix') {
            Invoke-Expression 'ip addr' | Out-File "TestDrive:\IPConfig.txt"
            {Invoke-FileRedaction -Path "TestDrive:\IPConfig.txt" -RedactionRule $null} | Should -Throw -ExpectedMessage "Cannot bind argument to parameter 'RedactionRule' because it is null"
        }
        It 'Parameter RedactionRule should not be null' -Skip:([environment]::OSVersion.Platform -match 'Win') {
            Invoke-Expression 'IPConfig /All' | Out-File "TestDrive:\IPConfig.txt"
            {Invoke-FileRedaction -Path "TestDrive:\IPConfig.txt" -RedactionRule $null} | Should -Throw -ExpectedMessage "Cannot bind argument to parameter 'RedactionRule' because it is null"
        }
        It 'Should be skipped' -Skip {

        }
    }    
}