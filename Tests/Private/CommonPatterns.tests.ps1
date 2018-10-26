Describe 'Common Patterns: IPV4Address' {
    $ConvertIPValue = New-RedactionRule -CommonPattern IPV4Address
    It 'Minimum value is ''11.0.0.1''' {
        $ConvertIPValue.Evaluate(0) | should -Match '11.0.0.1'
    }
    It 'Maxmum value is ''149.136.4.127''' {
        $ConvertIPValue.Evaluate([System.Int64]::MaxValue-1) | should -Match '149.136.4.127'
    }
}