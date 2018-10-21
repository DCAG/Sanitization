
Describe 'Class ReductionRule' {
    Context 'Parameters Validation' {
        It 'Reduction rule intialized with a string NewValue should create reduction rule of type "String"' {    
            $ReductionRule = [ReductionRule]::new('a','b')
            $ReductionRule.Pattern | Should -Be 'a'
            $ReductionRule.NewValueFunction | Should -BeNullOrEmpty
            $ReductionRule.NewValueString | Should -Be 'b'
            $ReductionRule.Type | Should -Be 'String'
        }
        It 'Reduction rule intialized with a ScriptBlock NewValue should create reduction rule of type "Function"' {    
            $ReductionRule = [ReductionRule]::new('a',[ScriptBlock]::Create('b'))
            $ReductionRule.Pattern | Should -Be 'a'
            $ReductionRule.NewValueFunction | Should -Be 'b'
            $ReductionRule.NewValueString | Should -BeNullOrEmpty
            $ReductionRule.Type | Should -Be 'Function'
        } 
        It 'Pattern parameter should not be Null Or Empty' {
            {[ReductionRule]::new('','a')} | Should -Throw
            {[ReductionRule]::new('',[ScriptBlock]::Create('a'))} | Should -Throw
        } 
    }
}

Describe 'New-ReductionRule' {
    Context 'Parameters Validation' {
        It 'Pattern that doesn''t exist in validation set of CommonPattern parameter should throw' {
            {New-ReductionRule -CommonPattern 'NoPattern'} | Should -Throw
        }
    }
}

Describe 'Invoke-Reduction' {
    Context 'Parameters Validation' {
    }

    Context 'Edge Cases' {
        $IPV4AddressRule = New-ReductionRule -CommonPattern IPV4Address
        $InputStringIPAddress = '1.1.1.1 30.20.7.2 3.1.2.4 1.2.4.6 4.5.6.4 9.8.7.8'
        It 'Single rule replacements should not overlap' {
            $SanitizedOutput = $InputStringIPAddress | Invoke-Reduction -ReductionRule $IPV4AddressRule -Consistent
            $InputStringIPAddress | Should -Match (@('[^\s]+')*5 -join ' ')
            $SanitizedOutput | Should -Match (@('[^\s]+')*5 -join ' ')
        }
    }
}