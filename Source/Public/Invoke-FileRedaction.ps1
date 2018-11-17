<#
.SYNOPSIS
Redact sensitive information from a file

.DESCRIPTION
Redact sensitive information from a file as an array of strings or one long string by defined redaction rules

.PARAMETER RedactionRule
Array of rules to redact by

.PARAMETER Path
Specifies a path to one or more locations. Wildcards are permitted.

.PARAMETER LiteralPath
Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
characters as escape sequences.

.PARAMETER ReadRaw
Ignores newline characters and pass the entire contents of a file in one string with the newlines preserved.
By default, newline characters in a file are used as delimiters to separate the input into an array of strings.
Process the file as one string instead of processing the strings line by line.

.EXAMPLE
$WULog = "$env:USERPROFILE\Desktop\WULog.log"
Get-WindowsUpdateLog -LogPath $WULog
Invoke-FileRedaction -Path $WULog -ReadRaw -RedactionRule @(
    New-RedactionRule '(?<=\d{4}\/\d{2}\/\d{2} \d{2}\:\d{2}\:\d{2}\.\d{7} \d{1,5} \d{1,5}\s+)\w+(?=\s+)' 'Component_{0}'
)

.NOTES
Invoke-RedactionRule creates 2 files in the same location of the input file,
the redacted file with "-Sanitized.txt" suffix
and the conversion table csv file with "-ConversionTable.csv" suffix.
By default all strings in the files are processed with Invoke-Redaction with the -Consistent parameter.
#>
function Invoke-FileRedaction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, 
            Position = 0)]
        [RedactionRule[]]$RedactionRule,
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path,
        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName="LiteralPath",
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Literal path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath,
        [switch]$ReadRaw
    )

    begin {
        $ExportCSVProperties = @{}
        if($PSVersionTable.PSVersion.Major -le 5){
            $ExportCSVProperties['NoTypeInformation'] = $true
        } 
    }

    process {
        $paths = @()
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }
        
        foreach ($aPath in $paths) {        
            # Output will be on the same directory
            $SanitizedFilePath = $aPath + "-Sanitized.txt"
            'Sanitized File: {0}' -f $SanitizedFilePath | Write-Verbose
            $ConversionTableFilePath = $aPath + "-ConversionTable.csv"
            'Conversion Table File: {0}' -f $ConversionTableFilePath | Write-Verbose 
            
            $TotalLines = Get-Content $aPath | Measure-Object -Line | Select-Object -ExpandProperty Lines
            'Total No.Lines: {0}' -f $TotalLines | Write-Verbose
            if ($TotalLines -eq 0) {
                $TotalLines = 1
            }
            
            Write-Progress -Activity "Redacting sensitive data from file: `"$aPath`"" -Id 1
            
            Get-Content $aPath -Raw:$ReadRaw | Invoke-Redaction -RedactionRule $RedactionRule -Consistent -OutConversionTable 'ConversionTable' -TotalLines $TotalLines | Out-File -FilePath $SanitizedFilePath
            $ConversionTable.Keys | Select-Object -Property @{N = 'NewValue'; E = {$ConversionTable[$_]}}, @{N = 'Original'; E = {$_}} | Sort-Object -Property NewValue | Export-Csv -Path $ConversionTableFilePath @ExportCSVProperties

            [PSCustomObject]@{
                Original        = $aPath
                Sanitized       = $SanitizedFilePath
                ConversionTable = $ConversionTableFilePath            
            }       
        }
    }
    
    end {
        Write-Progress -Activity "[Done] Redacting sensitive data from file: `"$aPath`" [Done]" -Id 1 -Completed
    }
}