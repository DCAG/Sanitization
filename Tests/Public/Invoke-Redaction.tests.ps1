Describe 'Invoke-Redaction' {
    Context 'Parameters Validation' {
        It 'LineNumber should not accept negative number' {
            {Invoke-Redaction -LineNumber -1} | Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'LineNumber'. The -1 argument is less than the minimum allowed range of 0. Supply an argument that is greater than or equal to 0 and then try the command again."
        }
        It 'InputObject and LineNumber should accept values from pipeline by name' {
            $Line = [PSCustomObject]@{InputObject = 'a';LineNumber = 0}
            $Line | Invoke-Redaction -RedactionRule (New-RedactionRule 'a' 'b') | Should -Be 'b'
        }
        It 'Dynamic parameter $OutConvertionTable should be shown only when $Consistent parameter is assigned true'{
            {'a' | Invoke-Redaction -Consistent -OutConvertionTable 't' -RedactionRule (New-RedactionRule 'a' 'b')} | Should -Not -Throw
            {'a' | Invoke-Redaction -OutConvertionTable 't' -RedactionRule (New-RedactionRule 'a' 'b')} | Should -Throw -ExpectedMessage "A parameter cannot be found that matches parameter name 'OutConvertionTable'."
        }
    }

    Context 'Functionality' {
        $IPV4AddressRule = New-RedactionRule '\d+' '{0}'
        $InputStringIPAddress = '10 10 6'
        It 'Consistent should replace the exact string with the same value' {
            $SanitizedOutput = $InputStringIPAddress | Invoke-Redaction -RedactionRule $IPV4AddressRule -Consistent:$true
            $SanitizedOutput | Should -Be '1 1 0'
        }
        It 'Inconsistent should replace the exact string with new value every time (on the same line)' {
            $SanitizedOutput = $InputStringIPAddress | Invoke-Redaction -RedactionRule $IPV4AddressRule -Consistent:$false
            $SanitizedOutput | Should -Be '0 0 0'
        }
        It 'When consistent and $OutConvertionTable is assigned, it should be populated with hashtable of the convertion'{
            'a' | Invoke-Redaction -Consistent -OutConvertionTable 't' -RedactionRule (New-RedactionRule 'a' 'b')
            $t.Keys | Should -Be 'a'
            $t['a'] | Should -Be 'b'
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