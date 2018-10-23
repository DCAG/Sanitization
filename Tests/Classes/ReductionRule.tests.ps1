Describe 'Class RedactionRule' {
    Context 'Parameters Validation' {
        It 'Reduction rule intialized with a string NewValue should create redaction rule of type "String"' {    
            $RedactionRule = [RedactionRule]::new('a','b')
            $RedactionRule.Pattern | Should -Be 'a'
            $RedactionRule.NewValueFunction | Should -BeNullOrEmpty
            $RedactionRule.NewValueString | Should -Be 'b'
            $RedactionRule.Type | Should -Be 'String'
        }
        It 'Reduction rule intialized with a ScriptBlock NewValue should create redaction rule of type "Function"' {    
            $RedactionRule = [RedactionRule]::new('a',[ScriptBlock]::Create('b'))
            $RedactionRule.Pattern | Should -Be 'a'
            $RedactionRule.NewValueFunction | Should -Be 'b'
            $RedactionRule.NewValueString | Should -BeNullOrEmpty
            $RedactionRule.Type | Should -Be 'Function'
        } 
        It 'Pattern parameter should not be Null Or Empty' {
            {[RedactionRule]::new('','a')} | Should -Throw
            {[RedactionRule]::new('',[ScriptBlock]::Create('a'))} | Should -Throw
        } 
    }
}