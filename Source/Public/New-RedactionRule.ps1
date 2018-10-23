Function New-RedactionRule {
    <#
    .SYNOPSIS
    Creates new redaction rule.
    
    .DESCRIPTION
    Creates new redaction rule with regex pattern to look for and NewValue to replace with.
    
    .PARAMETER Pattern
    Regex pattern
    
    .PARAMETER NewValueFunction
    Script block to generate new generic data, the result is then put instead of the original value.
    This script block can accept at most 1 int parameter with $args[0] or declare variable in param() block 
    
    .PARAMETER NewValueString
    Parameter description
    
    .PARAMETER CommonPattern
    Parameter description
    
    .EXAMPLE
    Mark '(?<=\().*(?=\))' 'Process_{0}'
    
    .EXAMPLE
    Mark '[a-z]' {
        [long]$p = $args[0]
        [char]($p % 26 + 65)
    }

    .EXAMPLE
    Mark -CommonPattern IPV4Address

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

$Script:CommonPatternTable = @{
    'IPV4Address' = New-RedactionRule -Pattern '\b(\d{1,3}(\.\d{1,3}){3})\b' -NewValueFunction ${Function:Convert-IPValue}
    #'IPV6Address' = New-Pattern -Pattern '\b(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\b' -NewValueFunction ${Function:Generate-IPValue}
    #'MACAddress' = New-Pattern -Pattern '\b([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\b' -NewValueFunction ${Function:Generate-IPValue}
    #'GUID' = New-Pattern -Pattern '\b[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?\b' -NewValueFunction ${Function:Generate-IPValue}
}