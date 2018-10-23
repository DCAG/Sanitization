Describe 'New-RedactionRule' {
    Context 'Parameters Validation' {
        It 'Pattern that doesn''t exist in validation set of CommonPattern parameter should throw' {
            {New-RedactionRule -CommonPattern 'NoPattern'} | Should -Throw
        }
    }
}