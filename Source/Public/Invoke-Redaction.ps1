$Script:CommonPatternTable = @{
    'IPV4Address' = New-RedactionRule -Pattern '\b(\d{1,3}(\.\d{1,3}){3})\b' -NewValueFunction ${Function:Generate-IPValue}
    #'IPV6Address' = New-Pattern -Pattern '\b(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\b' -NewValueFunction ${Function:Generate-IPValue}
    #'MACAddress' = New-Pattern -Pattern '\b([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\b' -NewValueFunction ${Function:Generate-IPValue}
    #'GUID' = New-Pattern -Pattern '\b[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?\b' -NewValueFunction ${Function:Generate-IPValue}
}

function Invoke-Redaction {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER InputObject
    Parameter description
    
    .PARAMETER ReductionRule
    Parameter description
    
    .PARAMETER LineNumber
    Parameter description
    
    .PARAMETER Consistent
    Parameter description
    
    .PARAMETER ConvertionTable
    Parameter description
    
    .PARAMETER AsObject
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [Alias('Invoke-Sanitization','irduc','isntz')]
    [CmdletBinding()]
    param(
        # One line string
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            Position = 0)]
        [Alias("CurrentString")]
        [AllowEmptyString()] # Incoming lines can be empty, so applied because of the Mandatory flag
        [psobject]
        $InputObject,
        [Parameter(Mandatory = $true, 
            Position = 1)]
        [RedactionRule[]]$RedactionRule,
        # Good practice is to provide the value from outside and increment before this function is being called for a new line.
        # If $LineNumber is not provided it is set to 0.
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            Position = 2)]
        [int]$LineNumber,
        # Requires $ConvertionTable but if it won't be provided, empty hash table for $ConvertionTable will be initialized instead
        [Parameter(Position = 3,
            ParameterSetName = 'Consistent')]
        [switch]
        $Consistent,
        [Parameter(Position = 4,
            ParameterSetName = 'Consistent')]
        [HashTable]
        $ConvertionTable,
        # Output as object
        # Will work only if the data was changed
        # Format parameter
        [switch]
        $AsObject)

    Begin {
        if (-not $LineNumber) {
            $LineNumber = 0
        }

        if ($Consistent) {
            $Uniqueness = 0
            if (-not $ConvertionTable) {
                $ConvertionTable = @{}
            }
        }
    }

    Process {
        $CurrentString = $InputObject.ToString()
        $CurrentStringChanged = $false

        foreach ($Rule in $RedactionRule) {
            # Consistent
            $Matches = Select-String -InputObject $CurrentString -Pattern $Rule.Pattern -AllMatches | Select-Object -ExpandProperty Matches | Sort-Object -Property Index -Descending # Sort Descending is required so the replacments won't overwrite each other
            if ($Matches) {
                $CurrentStringChanged = $true
                $StrSB = New-Object System.Text.StringBuilder($CurrentString)
                Foreach ($Match in $Matches) {
                    $MatchedValue = $Match.Value

                    'MatchedValue = {0}' -f $MatchedValue | Write-Verbose

                    if ($Consistent) {
                        if ($null -eq $ConvertionTable[$MatchedValue]) {
                            # MatchedValue doesn't exist in the ConvertionTable
                            # Adding MatchedValue to the ConvertionTable, add it with line number (if {0} is specified in $NewValue)
                            $ConvertionTable[$MatchedValue] = $Rule.Evaluate($Uniqueness)
                            'Adding new value to the convertion table: $ConvetionTable[{0}] = {1}' -f $MatchedValue, $ConvertionTable[$MatchedValue] | Write-Verbose 
                            $Uniqueness++
                        }

                        # This MatchedValue exists, use it.
                        $Replacement = $ConvertionTable[$MatchedValue]
                    }
                    else {
                        $Replacement = $Rule.Evaluate($LineNumber)
                    }

                    $null = $StrSB.Remove($Match.Index, $Match.Length)
                    $null = $StrSB.Insert($Match.Index, $Replacement)
                }

                $CurrentString = $StrSB.ToString()
            }
        } # foreach($Rule in $ReductionRule)

        # Only if result is different from the input object
        if ($AsObject) {
            $OutputProperties = @{
                LineNumber    = $LineNumber
                CurrentString = $CurrentString
                Original      = $InputObject
                Changed       = $CurrentStringChanged
            }

            $OutputPropertiesList = 'LineNumber', 'CurrentString', 'Original', 'Changed'

            if ($Consistent) {
                $OutputProperties['Uniqueness'] = $Uniqueness
                $OutputPropertiesList += 'Uniqueness'
            }

            New-Object -TypeName PSCustomObject -Property $OutputProperties | Select-Object $OutputPropertiesList
        }
        else {
            $CurrentString
        }

        $LineNumber++
    } # Process
}
