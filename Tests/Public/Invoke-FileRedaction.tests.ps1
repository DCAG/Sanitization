Describe 'Invoke-FileRedaction' {
    Context 'Parameters Validation' {
        It 'Parameter RedactionRule should not be null' {
            Invoke-Expression 'IPConfig /All' | Out-File "TestDrive:\IPConfig.txt"
            {Invoke-FileRedaction -Path "TestDrive:\IPConfig.txt" -RedactionRule $null} | Should -Throw -ExpectedMessage "Cannot bind argument to parameter 'RedactionRule' because it is null"
        }
        It 'Should be skipped' -Skip {

        }
    }    
}