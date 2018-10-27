function Invoke-Redaction {
    <#
    .SYNOPSIS
    Redact a string object
    
    .DESCRIPTION
    Redact a string object
    
    .PARAMETER InputObject
    An Input Object to redact from
    
    .PARAMETER ReductionRule
    Array of Rules with Regex pattern and new value to set when this pattern is matched to input object 
    
    .PARAMETER LineNumber
    Line number is used as a seed to obfoscate new values
    
    .PARAMETER Consistent
    Use a ConvertionTable to make previously matched values assigned with the same new valuethat was assigned to them and theyr were first found to make consistent
    
    .PARAMETER OutConvertionTable
    Table contains the matched values and their replacements.
    Shown only when Consistent switch is on ($true)
    
    .PARAMETER AsObject
    Return object with more parameters instead of single string 
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [Alias('Invoke-Sanitization', 'irdac', 'isntz')]
    [CmdletBinding()]
    param(
        # One line string
        [Parameter(Mandatory = $true,  
            ValueFromPipeline = $true,
            Position = 0)]
        [AllowEmptyString()] # Incoming lines can be empty, so applied because of the Mandatory flag
        [psobject]
        $InputObject,
        [Parameter(Mandatory = $true, 
            Position = 1)]
        [RedactionRule[]]$RedactionRule,
        # Requires $ConvertionTable but if it won't be provided, empty hash table for $ConvertionTable will be initialized instead
        [Parameter(Position = 2)]
        [switch]
        $Consistent,
        [Parameter(Position = 4)]
        [switch]
        $AsObject,
        [Parameter(Position = 5)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $TotalLines = 1
    )

    DynamicParam {
        if ($Consistent) {
            $ParameterName = 'OutConvertionTable'
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            $ValidateNotNullOrEmptyAttribute = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute
            $AttributeCollection.Add($ValidateNotNullOrEmptyAttribute)
            
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Position = 3
            $AttributeCollection.Add($ParameterAttribute)
            
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            
            return $RuntimeParameterDictionary
        }
    }

    Begin {
        if ($Consistent) {
            $OutConvertionTable = $PSBoundParameters[$ParameterName]            
            $ConvertionTable = @{}
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
        if ($ShowProgress) {
            $StopWatch.Stop()        
            Write-Progress -Activity "[Done] Redacting sensitive data [Done]" -Id 2 -ParentId 1 -Completed
        }
        #endregion

        if (-not [string]::IsNullOrWhiteSpace($OutConvertionTable)) {
            '$PSCmdlet.MyInvocation.CommandOrigin: {0}' -f $PSCmdlet.MyInvocation.CommandOrigin | Write-Debug
            if ($PSCmdlet.MyInvocation.CommandOrigin -eq 'Runspace') {
                $PSCmdlet.SessionState.PSVariable.Set($OutConvertionTable, $ConvertionTable)
            }
            else {
                # CommandOrigin: Internal
                Set-Variable -Name $OutConvertionTable -Value $ConvertionTable -Scope 1
            }
        }
    }
}