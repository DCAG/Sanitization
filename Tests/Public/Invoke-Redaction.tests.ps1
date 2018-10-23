Describe 'Invoke-Redaction' {
    Context 'Parameters Validation' {
        It 'Should be skipped' -Skip {

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