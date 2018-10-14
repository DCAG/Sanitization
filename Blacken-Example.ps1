<#
Author: Amir Granot
Date: 5 September 2016
#>

#requires -version 4.0

#$Convert.Keys | Select-Object -Property @{N='Original';E={$_}},@{N='NewValue';E={$Convert[$_]}} | Sort-Object -Property NewValue | Export-Csv $tableFile -Force -NoTypeInformation

#######################################################################

# Path to original log file
$inputFile = "D:\log.txt"

# Output will be on the same directory
$outputFile = $inputFile -replace '\.txt$',"-Blackened.txt"
$tableFile = $inputFile -replace '\.txt$',"-ConvertionTable.csv"

#######################################################################

Test-Path $inputFile -ErrorAction Stop
$totalLines = Get-Content $inputFile | Measure-Object -Line | % Lines

#######################################################################

# reusable static values values to replace
$Convert = @{}    
$Convert["myDom.dom"]       = "your.domain"
$Convert["DC=myDom,DC=dom"] = "DC=your,DC=domain"
$Convert["MYDOM"]           = "YOURDOMAIN"

# Regex patterns to replace
$rulesArr = @(
     @{ Pattern = "(?<=Windows service ).+(?= associated)";
            NewValue = "Service_{0}"}
    ,@{ Pattern = "(?<=group WinNT://(.*/)+).+(?= details on remote)|(?<=of group ).+(?= on remote)";
            NewValue = "UserOrGroup_{0}"}
    ,@{ Pattern = "(?<=Account ).*(?= causes)|(?<=\d - ).*(?= have \d)|\b[a-z0-9]{5,7}-x\b|(?<=Retrieving user ).+(?= details on)|(?<=to account ).+(?=\.)|(?<=User Principal ').+(?=' details from)|(?<=account ).+(?= details)|(?<=member path WinNT://(.*/){1,}).+(?= of group)";
            NewValue = "UserOrGroup_{0}"}
    ,@{ Pattern = "\bS(-\d{1,15}){6,7}\b";
            NewValue = "SID_{0}"}
    ,@{ IPPattern = $true }                                                  
    ,@{ Pattern = "\b([\w-]+\.myDom\.dom)\b";
            NewValue = "Server_{0}.$($Convert["myDom.dom"])"}
    ,@{ Pattern = "\b(?<ServerName>[a-zA-Z0-9-]*\.myDom\.dom)\b";
            NewValue = "Server_{0}.$($Convert["myDom.dom"])"}
    ,@{ Pattern = "\bmyDom\.dom\b";
            NewValue = $Convert["myDom.dom"]}
    ,@{ Pattern = "MYDOM";
            NewValue = $Convert["MYDOM"]}
    ,@{ Pattern = "CN=.* in LDAP path";
            NewValue = "CN=CN_{0} in LDAP path"}
    ,@{ Pattern = "OU=infra,DC=myDom,DC=dom";
            NewValue = "OU=soft,$($Convert["DC=myDom,DC=dom"])"}
    ,@{ Pattern = "DC=myDom,DC=dom";
            NewValue = $Convert["DC=myDom,DC=dom"]}
    ,@{ Pattern = "OU 'myDom > infra' ";
            NewValue = "OU 'mila > kunis' "}
)

Measure-Command{
    Get-Content $inputFile -PipelineVariable line | ForEach-Object -Begin {
        $lineNumber = 0
        $activityText = "Working on file $inputFile, New name $outputFile"
    } -Process {
        Write-Progress -Activity $activityText -CurrentOperation "line $lineNumber" -PercentComplete ($lineNumber/$totalLines*10000/101) -ErrorAction SilentlyContinue #cause gets up to 101 (somehow...)
        $rulesArr | ForEach-Object -Begin { 
            $str = $line
         } -Process { 
             $str = Replace-String -LineNumber $lineNumber -InputObject $str -ConvertionTable $Convert @_ 
             } -End { 
                 $str 
                }
        $lineNumber++
    } | Out-File -FilePath $outputFile -Encoding utf8 -Force
} 
#| Select-Object -Property @{N='ServerName';E={$ServerName}},@{N='ServerNumber';E={$Convert[$ServerName]}},@{N='ConvertionTime(Sec)';E={$_.Seconds}} | format-table -autosize

# Write convertion table
$Convert.Keys | Select-Object -Property @{N='Original';E={$_}},@{N='NewValue';E={$Convert[$_]}} | Sort-Object -Property NewValue | Export-Csv $tableFile -Force -NoTypeInformation
    