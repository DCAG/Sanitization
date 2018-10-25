using module Sanitization

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
            {[RedactionRule]::new($null,'a')} | Should -Throw
            {[RedactionRule]::new('',[ScriptBlock]::Create('a'))} | Should -Throw
            {[RedactionRule]::new($null,[ScriptBlock]::Create('a'))} | Should -Throw
        }

        It 'Type property other than what was specified in the validated set should fail' {
            $RedactionRuleFunction = [RedactionRule]::new('a',[scriptblock]::Create('a'))
            $RedactionRuleString = [RedactionRule]::new('a','a')
            {$RedactionRuleFunction.Type = 'a'} | Should -Throw
            {$RedactionRuleString.Type = 'a'} | Should -Throw
        }

        # This is not a desired behavior when done without setting $NewValue properties accordingly
        It 'Type property can be changed to what was specified in the validated set should succeed' -Skip {
            $RedactionRuleFunction = [RedactionRule]::new('a',[scriptblock]::Create('a'))
            $RedactionRuleString = [RedactionRule]::new('a','a')
            {$RedactionRuleFunction.Type = 'String'} | Should -Not -Throw
            {$RedactionRuleString.Type = 'Function'} | Should -Not -Throw
        }

        # Setting NewValue properties to $null or some other values without the Type property along with it is not right
        It 'NewValue properties can be changed to null or another value of their type' -Skip {
            $RedactionRuleFunction = [RedactionRule]::new('a',[scriptblock]::Create('a'))
            $RedactionRuleString = [RedactionRule]::new('a','a')
            {$RedactionRuleFunction.NewValueFunction = [scriptblock]::Create('scriptblock')} | Should -Not -Throw
            {$RedactionRuleString.NewValueString = 'string'} | Should -Not -Throw
        }

        It 'NewValue properties cannot be assigned values with different type' {
            $RedactionRuleFunction = [RedactionRule]::new('a',[scriptblock]::Create('a'))
            $RedactionRuleString = [RedactionRule]::new('a','a')
            {$RedactionRuleFunction.NewValueFunction = 'string'} | Should -Throw
            {$RedactionRuleString.NewValueString = [scriptblock]::Create('Function')} | Should -Throw
        }
    }
    Context 'Class functions' {
        It 'NewValue property of RedactionRule of type String without ''{0}'' should return the NewValue as it is' {
            $RedactionRuleString = [RedactionRule]::new('regex','v1')
            $RedactionRuleString.Evaluate(3) | Should -Match 'v1'
        }

        It 'NewValue property of RedactionRule of type String with ''{0}'' should return the NewValue with the seed parameter replacing the {0} placeholder' {
            $RedactionRuleString = [RedactionRule]::new('regex','v1_{0}')
            $RedactionRuleString.Evaluate(3) | Should -Match 'v1_3'
        }
    }
}