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
        # Path to original log file

        # Output will be on the same directory
        $SanitizedFilePath = $Path + "-Sanitized.txt"
        'Sanitized File: {0}' -f $SanitizedFilePath | Write-Verbose 
        $ConvertionTableFilePath = $Path + "-ConvertionTable.csv"
        'Convertion Table File: {0}' -f $ConvertionTableFilePath | Write-Verbose 

        #######################################################################

        $TotalLines = Get-Content $Path | Measure-Object -Line | Select-Object -ExpandProperty Lines
        'Total No.Lines: {0}' -f $TotalLines | Write-Verbose
        if($TotalLines -eq 0){
            $TotalLines = 1
        }

        $ConvertionTable = @{}
        Get-Content $Path | ForEach-Object -Begin {
            $Line = 0

            #region Write-Progress calculation block initialization
            $PercentComplete = 0
            $PercentStep = 100 / $TotalLines
            [double]$AverageTime = 0
            [int]$SecondsRemaining = $AverageTime * $TotalLines
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            #endregion
        } -Process {
            
            Invoke-Redaction -InputObject $_ -Line $Line -RedactionRule $RedactionRule -Consistent -ConvertionTable $ConvertionTable
            
            #region Write-Progress calculation block
            $PercentComplete += $PercentStep
            $ElapsedSeconds = $StopWatch.Elapsed.TotalSeconds
            $StopWatch.Restart()
            [double]$AverageTime = ($AverageTime * $Line + $ElapsedSeconds) / ($Line + 1)
            [int]$SecondsRemaining = $AverageTime * ($TotalLines - $Line)
            'L = {0} | Avg = {1} | Remain(S) = {2}' -f $Line, $AverageTime, $ElapsedSeconds, $SecondsRemaining | Write-Debug
            Write-Progress -Activity "Redacting sensitive data from file: `"$Path`"" -Id 1 -PercentComplete $PercentComplete -SecondsRemaining $SecondsRemaining
            #endregion
            
            $Line++
        } | Out-File -FilePath $SanitizedFilePath
        
        #region Write-Progress calculation block closing
        $StopWatch.Stop()        
        Write-Progress -Activity "[Done] Redacting sensitive data from file: `"$Path`" [Done]" -Id 1 -Completed
        #endregion

        $ConvertionTable.Keys | Select-Object -Property @{N = 'Original'; E = {$_}}, @{N = 'NewValue'; E = {$ConvertionTable[$_]}} | Sort-Object -Property NewValue | Export-Csv -Path $ConvertionTableFilePath
    }
    
    end {
    }
}