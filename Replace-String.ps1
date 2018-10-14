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
    param([int]$t)

    $o4 = ($t % 254) + 1
    $t = $t / 254
    $o3 = $t % 254
    $t = $t / 254 
    $o2 = $t % 254
    $t = $t / 254
    $o1 = $t % 254 + 11

    "$o1.$o2.$o3.$o4"
}

$Script:CommonPatternTable = @{
    'IPPattern' = @{ 
        Pattern          = "\b(\d{1,3}(\.\d{1,3}){3})\b" # \b with or without it makes a slight difference
        Value            = ${function:script:Generate-IPValue}
        ValueIsAFunction = $true
    }
}

function Replace-String {
    [CmdletBinding(DefaultParameterSetName = 'FreeForm')]
    param(
        # One line string
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            Position = 0)]
        [Alias("CurrentString")]
        [AllowEmptyString()] # Incoming lines can be empty, so applied because of the Mandatory flag
        [string]
        $InputObject,
        # Regex pattern with 1 named capturing group at most
        [Parameter(Mandatory = $true, 
            Position = 1,
            ParameterSetName = 'FreeForm')]
        [Parameter(Mandatory = $true, 
            Position = 1,
            ParameterSetName = 'Consistent')]
        [string]
        $Pattern,
        # Value can contain {0} so counter value will be added
        [Parameter(Mandatory = $true, 
            Position = 2,
            ParameterSetName = 'FreeForm')]
        [Parameter(Mandatory = $true, 
            Position = 2,
            ParameterSetName = 'Consistent')]
        [string]
        $NewValue,
        [Parameter(Mandatory = $true,
            Position = 3,
            ParameterSetName = 'CommonPattern')]
        [ValidateSet('IPPattern')]   
        [string]
        $CommonPattern,
        # Good practice is to provide the value from outside and increment before this function is being called for a new line.
        # If $LineNumber is not provided it is set to 0.
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            Position = 4)]
        [int]
        $LineNumber,
        # Requires $ConvertionTable but if it won't be provided, empty hash table for $ConvertionTable will be initialized instead
        [Parameter(mandatory = $true,
            Position = 5,
            ParameterSetName = 'Consistent')]
        [Parameter(Position = 5,
            ParameterSetName = 'CommonPattern')]
        [switch]
        $Consistent,
        [Parameter(Position = 6,
            ParameterSetName = 'Consistent')]
        [Parameter(Position = 6,
            ParameterSetName = 'CommonPattern')]
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
    }

    Process {

        $changed = $false

        if ($CommonPattern) {
            $Pattern = $Script:CommonPatternTable[$CommonPattern].Pattern
            $NewValue = $Script:CommonPatternTable[$CommonPattern].Value
            if ($Script:CommonPatternTable[$CommonPattern].ValueIsAFunction) {
                $NewValue = & $NewValue $LineNumber 
            }
        }

        if ($Consistent -and -not $ConvertionTable) {
            $ConvertionTable = @{}
        }

        # not Consistent
        if (-not $Consistent) {
            $result = $InputObject -replace $Pattern, ($NewValue -f $LineNumber)

            if ($AsObject) {
                # Since I dont know if there was a match ('-replace' does it internally) I'm checking to see if it was changed.
                $changed = $result -ne $InputObject
            }
        }
        else { # Consistent
            $result = if ($InputObject -match $Pattern) {

                $MatchedValue = $Matches[0]
                'MatchedValue = {0}' -f $MatchedValue | Write-Verbose

                if ($null -eq $ConvertionTable[$MatchedValue]) {
                    # MatchedValue doesn't exist in the ConvertionTable
                    # Adding MatchedValue to the ConvertionTable, add it with line number (if {0} is specified in $NewValue)
                    $ConvertionTable[$MatchedValue] = $NewValue -f $LineNumber
                    'Adding new value to the convertion table: $ConvetionTable[{0}] = {1}' -f $MatchedValue, $ConvertionTable[$MatchedValue] | Write-Verbose 
                }

                # This MatchedValue exists, use it.
                $InputObject -replace [regex]::Escape($MatchedValue), $ConvertionTable[$MatchedValue]

                # Since I know the pattern was matched, I'm certain that the line was changed
                $changed = $true
            }
            else { # Not match pattern
                $InputObject
            }
        }

        # Only if result is different from the input object
        if ($AsObject) {
            New-Object -TypeName PSCustomObject -Property @{
                LineNumber    = $LineNumber
                CurrentString = $result
                Pattern       = $Pattern
                NewValue      = $NewValue
                Original      = $InputObject
                Result        = $result
                Changed       = $changed
            } | Select-Object CurrentString, Pattern, NewValue, LineNumber, Original, Result, Changed
        }
        else {
            $result
        }

        $LineNumber++
    } # Process
}


gcm replace-string -Syntax