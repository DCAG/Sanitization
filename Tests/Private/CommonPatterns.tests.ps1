Describe 'Common Patterns: IPV4Address' {
    BeforeAll{
        $ConvertIPValue = New-RedactionRule -CommonRule IPV4Address
    }
    It 'Minimum value is ''11.0.0.1''' {
        $ConvertIPValue.Evaluate(0) | should -Match '11.0.0.1'
    }
    It 'Maxmum value is ''142.12.16.8''' {
        $ConvertIPValue.Evaluate([int]::MaxValue) | should -Match '142.12.16.8'
    }
}