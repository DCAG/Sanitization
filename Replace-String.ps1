<#
.Synopsis
   Replace string with regex patterns
.DESCRIPTION
   Replace string with regex patterns
   Good for blackening purposes usually.
.AUTOR
   Amir Granot 9.7.2016
#>

function Script:Generate-IPValue {
    [long]$t = $args[0]

    $o4 = ($t % 254) + 1
    $t = $t / 254
    $o3 = $t % 254
    $t = $t / 254 
    $o2 = $t % 254
    $t = $t / 254
    $o1 = $t % 254 + 11

    "$o1.$o2.$o3.$o4"
}

class BlackenPattern {
    [string]$Pattern
    [scriptblock]$NewValue

    BlackenPattern ($Pattern, $NewValue) {
        $this.Pattern = $Pattern
        $this.NewValue = $NewValue
    }
}

Function New-Pattern {
    [Alias('Pattern')]
    [OutputType([BlackenPattern])]
    [CmdletBinding(DefaultParameterSetName = 'Custom')]
    param(
        # Regex pattern with 1 named capturing group at most
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Custom')]
        [string]$Pattern,
        # Value can contain {0} so counter value will be added
        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Custom')]
        [scriptblock]$NewValue,
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Common')]
        [ValidateSet('IPPattern')]   
        [string]$CommonPattern
    )

    if($PSCmdlet.ParameterSetName -eq 'Common'){
        $Script:CommonPatternTable[$CommonPattern]
    }
    else{
        New-Object BlackenPattern($Pattern, $NewValue)
    }
}

$Script:CommonPatternTable = @{
    'IPPattern' = New-Pattern -Pattern '\b(\d{1,3}(\.\d{1,3}){3})\b' -NewValue ${Function:Generate-IPValue}
}

function ReplaceAt {
    param(
        [string]$Str,
        [int]$Index,
        [int]$Length,
        [string]$NewValue
    )
    $StrSB = New-Object System.Text.StringBuilder($Str)
    $null = $StrSB.Remove($Index, $Length)
    $null = $StrSB.Insert($Index, $Replacement)
    $StrSB.ToString()
}

function Replace-String {
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
        [BlackenPattern[]]$Pattern,
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
        # Output as object (with line number and instead of a single line
        # Will work only if the data was changed
        # Format parameter
        [switch]
        $AsObject)

    Begin {
        if (-not $LineNumber) {
            $LineNumber = 0
        }

        if($Consistent) {
            $Uniqueness = 0
            if (-not $ConvertionTable) {
                $ConvertionTable = @{}
            }
        }
    }

    Process {

        $CurrentString = $InputObject.ToString()

        $CurrentStringChanged = $false

        foreach($PatternItem in $Pattern){
            # Consistent
            $Matches = Select-String -InputObject $CurrentString -Pattern $PatternItem.Pattern -AllMatches | Select-Object -ExpandProperty Matches
            if($Matches){
                Foreach($Match in $Matches){
                    $MatchedValue = $Match.Value

                    'MatchedValue = {0}' -f $MatchedValue | Write-Verbose

                    if($Consistent){
                        if ($null -eq $ConvertionTable[$MatchedValue]) {
                            # MatchedValue doesn't exist in the ConvertionTable
                            # Adding MatchedValue to the ConvertionTable, add it with line number (if {0} is specified in $NewValue)
                            $ConvertionTable[$MatchedValue] = & $PatternItem.NewValue $Uniqueness
                            'Adding new value to the convertion table: $ConvetionTable[{0}] = {1}' -f $MatchedValue, $ConvertionTable[$MatchedValue] | Write-Verbose 
                            $Uniqueness++
                        }

                        # This MatchedValue exists, use it.
                        $Replacement = $ConvertionTable[$MatchedValue]
                    }
                    else{
                        $Replacement = & $PatternItem.NewValue $LineNumber
                    }

                    $CurrentString = ReplaceAt -Str $CurrentString -Index $Match.Index -Length $Match.Length -NewValue $Replacement
                    $CurrentStringChanged = $true
                }
            }
        } # foreach($PatternItem in $Pattern)

        # Only if result is different from the input object
        if ($AsObject) {
            $OutputProperties = @{
                LineNumber    = $LineNumber
                CurrentString = $CurrentString
                #Pattern       = $Pattern
                #NewValue      = $NewValue
                Original      = $InputObject
                #Result        = $result
                Changed       = $CurrentStringChanged
            }

            $OutputPropertiesList = 'LineNumber', 'CurrentString', 'Original', 'Changed'

            if($Consistent){
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


#gcm replace-string -Syntax