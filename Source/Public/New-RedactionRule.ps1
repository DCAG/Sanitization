Function New-RedactionRule {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Pattern
    Parameter description
    
    .PARAMETER NewValueFunction
    Parameter description
    
    .PARAMETER NewValueString
    Parameter description
    
    .PARAMETER CommonPattern
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [Alias('New-SanitizationRule','New-MarkingRule','Mark')] # Usually Single word is an automatic alias for Get-<SingleWord>
    [OutputType([RedactionRule])]
    [CmdletBinding(DefaultParameterSetName = 'CustomFunction')]
    param(
        # Regex pattern with 1 named capturing group at most
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'CustomString')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'CustomFunction')]
        [string]$Pattern,
        # Value can contain {0} so counter value will be added
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'CustomFunction')]
        [scriptblock]$NewValueFunction,
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'CustomString')]
        [String]$NewValueString,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Common')]
        [ValidateSet('IPV4Address')]   
        [string]$CommonPattern
    )

    if ($PSCmdlet.ParameterSetName -eq 'Common') {
        $Script:CommonPatternTable[$CommonPattern]
    }
    elseif($PSCmdlet.ParameterSetName -eq 'CustomFunction') {
        New-Object RedactionRule($Pattern, $NewValueFunction)
    }
    elseif($PSCmdlet.ParameterSetName -eq 'CustomString') {
        New-Object RedactionRule($Pattern, $NewValueString)
    }
}