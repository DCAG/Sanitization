using module Sanitization

Describe 'New-RedactionRule' {
    Context 'Parameters Validation' {
        It 'Pattern that doesn''t exist in validation set of CommonRule parameter should throw' {
            {New-RedactionRule -CommonRule 'NoPattern'} | Should -Throw
        }

        It 'Assigning Scriptblock parameter creates redaction rule of type function' {
            $RedactionRule = New-RedactionRule 'a' {'a'}
            $RedactionRule.Type | Should -Be 'Function'
        }

        It 'Assigning string parameter creates redaction rule of type string' {
            $RedactionRule = New-RedactionRule 'a' 'a'
            $RedactionRule.Type | Should -Be 'String'
        }

        It 'Only 1 type of new value parameter is accepted' {
            {New-RedactionRule -Pattern 'p' -NewValueString 's' -NewValueFunction {'f'}} | Should -Throw
            {New-RedactionRule -Pattern 'p' -NewValueFunction {'f'}} | Should -not -Throw
            {New-RedactionRule -Pattern 'p' -NewValueString 's' } | Should -not -Throw
        }
    }

    Context 'General' {
        It 'Should be able to call New-RedactionRule in all its aliases' {
            'New-SanitizationRule','New-MarkingRule','Mark' | foreach-object {
                {& $_ -Pattern 'p' -NewValueFunction {'f'}} | Should -not -Throw
                {& $_ -Pattern 'p' -NewValueString 's'} | Should -not -Throw
                {& $_  -CommonRule IPV4Address} | Should -not -Throw
            }
        }
        It 'Should output RedactionRule type object' {
            $FunctionRule = New-RedactionRule -Pattern 'p' -NewValueFunction {'f'}
            $StringRule = New-RedactionRule -Pattern 'p' -NewValueString 's'
            $CommonRuleRule = Mark -CommonRule IPV4Address
            $FunctionRule.GetType() | Should -Be 'RedactionRule'
            $StringRule.GetType() | Should -Be 'RedactionRule'
            $CommonRuleRule.GetType() | Should -Be 'RedactionRule'
        }
    }
}