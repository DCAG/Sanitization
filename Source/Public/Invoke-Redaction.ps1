<#
.SYNOPSIS
Redact sensitive information from an object

.DESCRIPTION
Redact sensitive information from an object as string by defined redaction rules

.PARAMETER RedactionRule
Array of redaction rules to redact by

.PARAMETER InputObject
String to redact sensitive information from

.PARAMETER Consistent
Saves discovered values in a ConversionTable (hash table), when the same values disceverd again they are replaced with the same string that was generated the first time from the redaction rule NewValue function or NewValue formatted string.
It uses a uniqueness value to generate new value from the redaction rule (if applicable).
if Consistent is ommitted generation of new value from redaction rule's NewValues is based on current line number.

.PARAMETER OutConversionTable
Creates a variable with the specified name and the ConversionTable as its value.

.PARAMETER AsObject
Return an object with the old string, the processed string, line number and if the string was changed or not instead of just a processed string.

.PARAMETER TotalLines
Number of lines that are going to be processed over the pipeline.
Relevant for showing informative progress bar.

.EXAMPLE
Replace all a-z letters with '+' sign
$RedactionRule = New-RedactionRule -Pattern '[a-z]' -NewValueString '+'
ipconfig /all | Invoke-Redaction -RedactionRule $RedactionRule

.EXAMPLE
Replace all service names that start with the letter 's' with 's_{0}', where {0} is replaced by uniqueness factor.
Each unique serivce name will be replaced with a unique new value 's_{0}' and it will stay consistent if the service shows up multiple times.
$RedactionRule = New-RedactionRule -Pattern '(?<=\s)[Ss].+' -NewValueString 's_{0}'
Get-Process | Out-String | Invoke-Redaction -RedactionRule $RedactionRule -Consistent

.NOTES

.EXTERNALHELP Sanitization-help.xml
#>
function Invoke-Redaction {
    [Alias('Invoke-Sanitization', 'irdac', 'isntz')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, 
            Position = 0)]
        [RedactionRule[]]$RedactionRule,
        # One line string
        [Parameter(Mandatory = $true,  
            ValueFromPipeline = $true,
            Position = 1)]
        [AllowEmptyString()] # Incoming lines can be empty, so applied because of the Mandatory flag
        [psobject]
        $InputObject,
        # Requires $ConversionTable but if it won't be provided, empty hash table for $ConversionTable will be initialized instead
        [switch]
        $Consistent,
        [switch]
        $AsObject,
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $TotalLines = 1
    )

    DynamicParam {
        if ($Consistent) {
            $ParameterName = 'OutConversionTable'
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            $ValidateNotNullOrEmptyAttribute = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute
            $AttributeCollection.Add($ValidateNotNullOrEmptyAttribute)
            
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $AttributeCollection.Add($ParameterAttribute)
            
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            
            return $RuntimeParameterDictionary
        }
    }

    Begin {
        if ($Consistent) {
            $OutConversionTable = $PSBoundParameters[$ParameterName]            
            $ConversionTable = @{}
            $Uniqueness = 0
        }

        #region Write-Progress calculation block initialization
        $PercentComplete = 0
        $PercentStep = 100 / $TotalLines
        [double]$AverageTime = 0
        [int]$SecondsRemaining = $AverageTime * $TotalLines
        $StopWatch = [System.Diagnostics.Stopwatch]::new()
        $StopWatch.Start()
        #endregion

        $LineNumber = 0
    }

    Process {
        $CurrentString = $InputObject.ToString()
        $CurrentStringChanged = $false

        foreach ($Rule in $RedactionRule) {
            $Matches = Select-String -InputObject $CurrentString -Pattern $Rule.Pattern -AllMatches | Select-Object -ExpandProperty Matches | Sort-Object -Property Index -Descending # Sort Descending is required so the replacments won't overwrite each other
            if ($Matches) {
                $CurrentStringChanged = $true
                $StrSB = New-Object System.Text.StringBuilder($CurrentString)
                Foreach ($Match in $Matches) {
                    $MatchedValue = $Match.Value

                    'MatchedValue = {0}' -f $MatchedValue | Write-Verbose

                    if ($Consistent) {
                        if ($null -eq $ConversionTable[$MatchedValue]) {
                            # MatchedValue doesn't exist in the ConversionTable
                            # Adding MatchedValue to the ConversionTable, add it with line number (if {0} is specified in $NewValue)
                            $ConversionTable[$MatchedValue] = $Rule.Evaluate($Uniqueness)
                            'Adding new value to the conversion table: $ConvetionTable[{0}] = {1}' -f $MatchedValue, $ConversionTable[$MatchedValue] | Write-Verbose 
                            $Uniqueness++
                        }

                        # This MatchedValue exists, use it.
                        $Replacement = $ConversionTable[$MatchedValue]
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

        #region Write-Progress calculation block
        if ($TotalLines -gt $LineNumber) {
            $PercentComplete += $PercentStep
            $ElapsedSeconds = $StopWatch.Elapsed.TotalSeconds
            $StopWatch.Restart()
            [double]$AverageTime = ($AverageTime * $LineNumber + $ElapsedSeconds) / ($LineNumber + 1)
            [int]$SecondsRemaining = $AverageTime * ($TotalLines - $LineNumber)
            'L = {0} | Avg = {1} | Remain(S) = {2}' -f $LineNumber, $AverageTime, $ElapsedSeconds, $SecondsRemaining | Write-Debug
        }

        Write-Progress -Activity "Redacting sensitive data. Line Number: $LineNumber out of $TotalLines" -Id 2 -ParentId 1 -PercentComplete $PercentComplete -SecondsRemaining $SecondsRemaining
        #endregion

        $LineNumber++
    } # Process

    end {
        #region Write-Progress calculation block closing
        $StopWatch.Stop()        
        Write-Progress -Activity "[Done] Redacting sensitive data [Done]" -Id 2 -ParentId 1 -Completed
        #endregion

        if (-not [string]::IsNullOrWhiteSpace($OutConversionTable)) {
            '$PSCmdlet.MyInvocation.CommandOrigin: {0}' -f $PSCmdlet.MyInvocation.CommandOrigin | Write-Debug
            if ($PSCmdlet.MyInvocation.CommandOrigin -eq 'Runspace') {
                $PSCmdlet.SessionState.PSVariable.Set($OutConversionTable, $ConversionTable)
            }
            else {
                # CommandOrigin: Internal
                Set-Variable -Name $OutConversionTable -Value $ConversionTable -Scope 2
            }
        }
    }
}