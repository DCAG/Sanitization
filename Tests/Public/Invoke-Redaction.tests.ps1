Describe 'Invoke-Redaction' {
    Context 'Parameters Validation' {
        It 'LineNumber should not accept negative number' {
            {Invoke-Redaction -LineNumber -1} | Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'LineNumber'. The -1 argument is less than the minimum allowed range of 0. Supply an argument that is greater than or equal to 0 and then try the command again."
        }
    }

    Context 'Edge Cases' {
        $IPV4AddressRule = New-RedactionRule -CommonPattern IPV4Address
        $InputStringIPAddress = '1.1.1.1 30.20.7.2 3.1.2.4 1.2.4.6 4.5.6.4 9.8.7.8'
        It 'Single rule replacements should not overlap' {
            $SanitizedOutput = $InputStringIPAddress | Invoke-Redaction -RedactionRule $IPV4AddressRule -Consistent
            $InputStringIPAddress | Should -Match (@('[^\s]+')*5 -join ' ')
            $SanitizedOutput | Should -Match (@('[^\s]+')*5 -join ' ')
        }
    }
}