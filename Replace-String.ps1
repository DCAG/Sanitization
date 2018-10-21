<#
.Synopsis
   Replace string with regex patterns
.DESCRIPTION
   Replace string with regex patterns
   Good for blackening purposes usually.
.AUTOR
   Amir Granot 9.7.2016
#>

. .\Private\HelperFunctions.ps1

class ReductionRule {
    [ValidateNotNullOrEmpty()][string]$Pattern
    [scriptblock]$NewValueFunction
    [string]$NewValueString
    [ValidateSet('String','Function')][string]$Type

    ReductionRule ([string]$Pattern, [string]$NewValueString) {
        $this.Pattern          = $Pattern
        $this.NewValueString   = $NewValueString
        $this.NewValueFunction = $null
        $this.Type             = 'String'
    }

    ReductionRule ([string]$Pattern, [scriptblock]$NewValueFunction) {
        $this.Pattern          = $Pattern
        $this.NewValueFunction = $NewValueFunction
        $this.NewValueString   = $null
        $this.Type             = 'Function'
    }

    [string] Evaluate([int]$Seed){
        if($this.Type -eq 'String'){
            return ($this.NewValueString -f $Seed)
        }else{ # $this.Type -eq 'Function'
            return (& $this.NewValueFunction $Seed)
        }
    }
}

Function New-ReductionRule {
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
    [OutputType([ReductionRule])]
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
        New-Object ReductionRule($Pattern, $NewValueFunction)
    }
    elseif($PSCmdlet.ParameterSetName -eq 'CustomString') {
        New-Object ReductionRule($Pattern, $NewValueString)
    }
}

$Script:CommonPatternTable = @{
    'IPV4Address' = New-ReductionRule -Pattern '\b(\d{1,3}(\.\d{1,3}){3})\b' -NewValueFunction ${Function:Generate-IPValue}
    #'IPV6Address' = New-Pattern -Pattern '\b(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\b' -NewValueFunction ${Function:Generate-IPValue}
    #'MACAddress' = New-Pattern -Pattern '\b([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\b' -NewValueFunction ${Function:Generate-IPValue}
    #'GUID' = New-Pattern -Pattern '\b[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?\b' -NewValueFunction ${Function:Generate-IPValue}
}

function Invoke-Reduction {
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
        [ReductionRule[]]$ReductionRule,
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

        foreach ($Rule in $ReductionRule) {
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
