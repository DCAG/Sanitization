function Invoke-FileRedaction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_})]
        [string]$Path,
        [RedactionRule[]]$RedactionRule
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
        if($TotalLines -eq 0){
            $TotalLines = 1
        }
        
        Write-Progress -Activity "Redacting sensitive data from file: `"$Path`"" -Id 1
        
        $ConvertionTable = @{}
        Get-Content $Path | Invoke-Redaction -RedactionRule $RedactionRule -Consistent -ConvertionTable $ConvertionTable -ShowProgress -TotalLines $TotalLines | Out-File -FilePath $SanitizedFilePath
        $ConvertionTable.Keys | Select-Object -Property @{N = 'Original'; E = {$_}}, @{N = 'NewValue'; E = {$ConvertionTable[$_]}} | Sort-Object -Property NewValue | Export-Csv -Path $ConvertionTableFilePath

        [PSCustomObject]@{
            Original = $Path
            Sanitized = $SanitizedFilePath
            ConvertionTable = $ConvertionTableFilePath            
        }
    }
    
    end {
        Write-Progress -Activity "[Done] Redacting sensitive data from file: `"$Path`" [Done]" -Id 1 -Completed
    }
}