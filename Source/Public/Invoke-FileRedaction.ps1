function Invoke-FileRedaction {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Path
    Parameter description
    
    .PARAMETER RedactionRule
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [ValidateScript( {Test-Path $_})]
        [string]$Path,
        [Parameter(Mandatory = $true, 
            Position = 1)]
        [RedactionRule[]]$RedactionRule,
        [Parameter(Position = 2)]
        [switch]$ReadRaw
    )

    begin {
    }

    process {
        
        # Output will be on the same directory
        $SanitizedFilePath = $Path + "-Sanitized.txt"
        'Sanitized File: {0}' -f $SanitizedFilePath | Write-Verbose
        $ConvertionTableFilePath = $Path + "-ConvertionTable.csv"
        'Convertion Table File: {0}' -f $ConvertionTableFilePath | Write-Verbose 
        
        $TotalLines = Get-Content $Path | Measure-Object -Line | Select-Object -ExpandProperty Lines
        'Total No.Lines: {0}' -f $TotalLines | Write-Verbose
        if ($TotalLines -eq 0) {
            $TotalLines = 1
        }
        
        Write-Progress -Activity "Redacting sensitive data from file: `"$Path`"" -Id 1
        
        Get-Content $Path -Raw:$ReadRaw | Invoke-Redaction -RedactionRule $RedactionRule -Consistent -OutConvertionTable 'ConvertionTable' -TotalLines $TotalLines | Out-File -FilePath $SanitizedFilePath
        $ConvertionTable.Keys | Select-Object -Property @{N = 'NewValue'; E = {$ConvertionTable[$_]}}, @{N = 'Original'; E = {$_}} | Sort-Object -Property NewValue | Export-Csv -Path $ConvertionTableFilePath

        [PSCustomObject]@{
            Original        = $Path
            Sanitized       = $SanitizedFilePath
            ConvertionTable = $ConvertionTableFilePath            
        }
    }
    
    end {
        Write-Progress -Activity "[Done] Redacting sensitive data from file: `"$Path`" [Done]" -Id 1 -Completed
    }
}