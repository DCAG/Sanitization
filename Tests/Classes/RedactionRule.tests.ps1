using module Sanitization

Describe 'Class RedactionRule' {
    Context 'Parameters Validation' {
        It 'Reduction rule intialized with a string NewValue should create redaction rule of type "String"' {    
            [RedactionRule]$RedactionRule = [RedactionRuleString]::new('a','b')
            $RedactionRule.Pattern | Should -Be 'a'
            $RedactionRule.NewValue | Should -Be 'b'
        }

        It 'Reduction rule intialized with a ScriptBlock NewValue should create redaction rule of type "Function"' {    
            [RedactionRule]$RedactionRule = [RedactionRuleFunction]::new('a',[ScriptBlock]::Create('b'))
            $RedactionRule.Pattern | Should -Be 'a'
            $RedactionRule.NewValue | Should -Be 'b'
        } 

        It 'Pattern parameter should not be Null Or Empty' {
            {[RedactionRuleString]::new('','a')} | Should -Throw
            {[RedactionRuleString]::new($null,'a')} | Should -Throw
            {[RedactionRuleFunction]::new('',[ScriptBlock]::Create('a'))} | Should -Throw
            {[RedactionRuleFunction]::new($null,[ScriptBlock]::Create('a'))} | Should -Throw
        }

        It 'NewValue property can be changed to another value' {
            $RedactionRuleFunction = [RedactionRuleFunction]::new('a',[scriptblock]::Create('a'))
            $RedactionRuleString = [RedactionRuleString]::new('a','a')
            {$RedactionRuleFunction.NewValue = [scriptblock]::Create('b')} | Should -Not -Throw
            {$RedactionRuleString.NewValue = 'b'} | Should -Not -Throw
        }

        It 'NewValue properties cannot be assigned values with different type' {
            $RedactionRuleFunction = [RedactionRuleFunction]::new('a',[scriptblock]::Create('a'))
            $RedactionRuleString = [RedactionRuleString]::new('a','a')
            {$RedactionRuleFunction.NewValue = 'string'} | Should -Throw
            {$RedactionRuleString.NewValue = [scriptblock]::Create('Function')} | Should -Throw
        }
    }
    Context 'Class functions' {
        It 'NewValue property of RedactionRuleString of type String without ''{0}'' should return the NewValue as it is' {
            [RedactionRule]$RedactionRuleString = [RedactionRuleString]::new('regex','v1')
            $RedactionRuleString.Evaluate(3) | Should -Match 'v1'
        }

        It 'NewValue property of RedactionRuleString of type String with ''{0}'' should return the NewValue with the seed parameter replacing the {0} placeholder' {
            [RedactionRule]$RedactionRuleString = [RedactionRuleString]::new('regex','v1_{0}')
            $RedactionRuleString.Evaluate(3) | Should -Match 'v1_3'
        }
    }
}