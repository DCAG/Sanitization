Describe 'Convert-IPValue' {
    It 'Minimum value is ''11.0.0.1''' {
        Convert-IPValue 0 | should -Match '11.0.0.1'
    }
    It 'Maxmum value is ''149.136.4.127''' {
        Convert-IPValue ([System.Int64]::MaxValue-1) | should -Match '149.136.4.127'
    }
}