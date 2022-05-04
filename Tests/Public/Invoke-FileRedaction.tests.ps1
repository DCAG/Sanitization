Describe 'Invoke-FileRedaction' {
    Context 'Parameters Validation' {
        if(-not $IsCoreCLR){
            $IsWindows = [environment]::OSVersion.Platform -match 'Win'
            $IsLinux = [environment]::OSVersion.Platform -match 'Unix'
        }
        
        It 'Parameter RedactionRule should not be null' {
            $IpConfigResult = if ($IsWindows) {
                Invoke-Expression 'IPConfig /All'
            } else {
                Invoke-Expression 'ip addr'
            }
            $IpConfigResult | Out-File "TestDrive:\IPConfig.txt"
            {Invoke-FileRedaction -Path "TestDrive:\IPConfig.txt" -RedactionRule $null} | Should -Throw -ExpectedMessage "Cannot bind argument to parameter 'RedactionRule' because it is null."
        }
    }    
}