<#
.Synopsis
   Function that helps to Blacken Logs
.DESCRIPTION
   Long description
.AUTOR
   Amir Granot 9.7.2016
#>
function Replace-String
{
    [CmdletBinding(DefaultParameterSetName='FreeForm')]
    param(
    # One line string
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false, 
                Position=0,
                ParameterSetName='IPPattern')]
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false, 
                Position=0,
                ParameterSetName='Consistent')]
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false, 
                Position=0,
                ParameterSetName='FreeForm')]
    [Alias("CurrentString")]
    [AllowEmptyString()] # Incoming lines can be empty, so applied because of the Mandatory flag
    [string]
    $InputObject,
    # Regex pattern with 1 named capturing group at most
    [Parameter(Mandatory=$true, 
                Position=1,
                ParameterSetName='Consistent')]
    [Parameter(Mandatory=$true, 
                Position=1,
                ParameterSetName='FreeForm')]
    [string]
    $Pattern,
    # Value can contain {0} so counter value will be added
    [Parameter(Mandatory=$true, 
                Position=2,
                ParameterSetName='Consistent')]
    [Parameter(Mandatory=$true, 
                Position=2,
                ParameterSetName='FreeForm')]
    [string]
    $NewValue,
    [Parameter(Mandatory=$true,
                ParameterSetName='IPPattern')]
    [switch]
    $IPPattern,
    # Can be global in the script instead of a parameter in this function. # need to think about it
    # Required if -AsObject | -Consistent (not dependent on them)
    [Parameter(Mandatory=$false,#true
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false,
                ParameterSetName='IPPattern')]
    [Parameter(Mandatory=$false,#true
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false,
                ParameterSetName='Consistent')]
    [Parameter(Mandatory=$false,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false, 
                ParameterSetName='FreeForm')]
    [int]
    $LineNumber,
    # ConvertionTable is required 
    [Parameter(Mandatory=$true,ParameterSetName='IPPattern')]
    [Parameter(Mandatory=$false,ParameterSetName='Consistent')]
    [HashTable]
    $ConvertionTable,
    # Output as object (with line number and instead of a single line
    # Will work only if the data was changed
    # Format parameter
    [switch]
    $AsObject)

    Begin{
        if(-not $LineNumber){
            $LineNumber = 0
        }
    }

    Process{

        $changed = $false

        if($IPPattern){
            $Pattern = "\b(\d{1,3}(\.\d{1,3}){3})\b" # \b with or without it makes a slight difference
        }

        #not Consistent
        if(-not $ConvertionTable){
            $result = $InputObject -replace $Pattern,($NewValue -f $LineNumber)
            if($AsObject){ #save time
                $changed = $result -ne $InputObject
            }        
        }
        else{#Consistent
            #match pattern?
            $result = if($InputObject -match $Pattern){
                #Capturing Group Name is set
                $NamedPattern = $Matches[0]
                Write-Verbose "`$NamedPattern = $NamedPattern"
                #Does this lexeme already exist in the ConvertionTable?
                if($ConvertionTable[$NamedPattern] -eq $null){
                    #IPPattern
                    if($IPPattern){
                        [int]$t = $LineNumber
                        $o4 = ($t % 254) + 1
                        $t = $t / 254
                        $o3 = $t % 254
                        $t = $t / 254 
                        $o2 = $t % 254
                        $t = $t / 254
                        $o1 = $t % 254 + 11

                        $NewValue = "$o1.$o2.$o3.$o4"
                    }
                    #This pattern doesn't exist in the ConvertionTable, add it with line number (if specified in the NewValue)
                    Write-Verbose "adding new value to the convertion table"
                    $ConvertionTable[$NamedPattern] = $NewValue -f $LineNumber
                    Write-Verbose "`$ConvetionTable[$NamedPattern] = $($ConvertionTable[$NamedPattern])"
                }
                #This pattern exists, use it.
                $InputObject -replace [regex]::Escape($NamedPattern),$ConvertionTable[$NamedPattern] #$InputObject -replace $NamedPattern,$ConvertionTable[$NamedPattern]

                $changed = $true
            }
            else{
                #Not match pattern
                $InputObject
            }
        }

        #Only if result is different from the input object
        if($AsObject){
            New-Object -TypeName PSCustomObject -Property @{
                CurrentString = $result
                Pattern       = $Pattern
                NewValue      = $NewValue
                Original      = $InputObject
                Result        = $result
                LineNumber    = $LineNumber
                Changed       = $changed
            } | Select-Object CurrentString,Pattern,NewValue,LineNumber,Original,Result,Changed
        }else{
            $result
        }

        $LineNumber++
    }#Process
}