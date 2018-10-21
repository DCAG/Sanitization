<#
Author: Amir Granot
Date: 5 September 2016
#>

#requires -version 5.1

#$Convert.Keys | Select-Object -Property @{N='Original';E={$_}},@{N='NewValue';E={$Convert[$_]}} | Sort-Object -Property NewValue | Export-Csv $tableFile -Force -NoTypeInformation

#######################################################################

# Path to original log file
$inputFile = "D:\log.txt"

# Output will be on the same directory
$outputFile = $inputFile -replace '\.txt$', "-Blackened.txt"
$tableFile = $inputFile -replace '\.txt$', "-ConvertionTable.csv"

#######################################################################

Test-Path $inputFile -ErrorAction Stop
$totalLines = Get-Content $inputFile | Measure-Object -Line | % Lines

#######################################################################

# reusable static values to replace
# $Convert hash table is written as output to the ConvertionTable.csv file
$Convert = @{}    
$Convert["myDom.dom"] = "your.domain"
$Convert["DC=myDom,DC=dom"] = "DC=your,DC=domain"
$Convert["MYDOM"] = "YOURDOMAIN"

# Regex patterns to replace
# Unique matches that are found based in patterns in this array are added to the $Convert hash table.
# If a unique match was replaced with a new value before, it will get the same value to keep on consistency
# You may use {0} in the values to add the line number to the value. Useful for assigning unique values.
$rulesArr = @(
        Mark "(?<=Windows service ).+(?= associated)" "Service_{0}"
        Mark "(?<=group WinNT://(.*/)+).+(?= details on remote)|(?<=of group ).+(?= on remote)" "UserOrGroup_{0}"
        Mark "(?<=Account ).*(?= causes)|(?<=\d - ).*(?= have \d)|\b[a-z0-9]{5,7}-x\b|(?<=Retrieving user ).+(?= details on)|(?<=to account ).+(?=\.)|(?<=User Principal ').+(?=' details from)|(?<=account ).+(?= details)|(?<=member path WinNT://(.*/){1,}).+(?= of group)" "UserOrGroup_{0}"
        Mark "\bS(-\d{1,15}){6,7}\b" "SID_{0}"
        Mark -CommonPattern IPV4Address                                                  
        Mark "\b([\w-]+\.myDom\.dom)\b" "Server_{0}.$($Convert["myDom.dom"])"
        Mark "\b(?<ServerName>[a-zA-Z0-9-]*\.myDom\.dom)\b" "Server_{0}.$($Convert["myDom.dom"])"
        Mark "\bmyDom\.dom\b" $Convert["myDom.dom"]
        Mark "MYDOM" $Convert["MYDOM"]
        Mark "CN=.* in LDAP path" "CN=CN_{0} in LDAP path"
        Mark "OU=infra,DC=myDom,DC=dom" "OU=soft,$($Convert["DC=myDom,DC=dom"])"
        Mark "DC=myDom,DC=dom" $Convert["DC=myDom,DC=dom"]
        Mark "OU 'myDom > infra' " "OU 'mila > kunis' "
        Mark '(?<=\().*(?=\))' 'Process_{0}'
        Mark '[a-z]' {
                [long]$p = $args[0]
                [char]($p % 26 + 65)
        }
        [ReductionRule]::new('[^\s]+','blablabla')
)

$t = @{}
Get-Process | Invoke-Reduction -ConvertionTable $t -Consistent -ReductionRule $rulesArr -AsObject -Verbose  | ft -AutoSize
$t.Keys | Select-Object -Property @{N = 'Original'; E = {$_}}, @{N = 'NewValue'; E = {$t[$_]}} | Sort-Object -Property NewValue
Get-Process | Sort-Object | Invoke-Reduction -ReductionRule $rulesArr -AsObject -Verbose  | ft -AutoSize


ipconfig /all | Invoke-Reduction -ConvertionTable $t -Consistent -ReductionRule $rulesArr -AsObject -Verbose  | fl # ft -AutoSize
ipconfig /all | Out-String | Invoke-Reduction -ConvertionTable $t -Consistent -ReductionRule $rulesArr | fl # ft -AutoSize
ipconfig /all | Out-String | Invoke-Reduction -ReductionRule $rulesArr | fl # ft -AutoSize
ipconfig /all | Invoke-Reduction -ReductionRule $rulesArr | fl # ft -AutoSize
ipconfig | Sort-Object | Invoke-Reduction -ReductionRule $rulesArr -AsObject -Verbose  | fl
Get-WindowsUpdateLog
cat C:\Users\Amir\Desktop\WindowsUpdate.log
#-Consistent -ConvertionTable $Convert
# Write convertion table
$Convert.Keys | Select-Object -Property @{N = 'Original'; E = {$_}}, @{N = 'NewValue'; E = {$Convert[$_]}} | Sort-Object -Property NewValue | Export-Csv $tableFile -Force -NoTypeInformation
    
$P = Pattern '(?<=\().*(?=\))' {'Process_{0}' -f $args[0]}
(& $P.NewValue 5)
Get-Process | %{
        $CurrentStringSB = New-Object System.Text.StringBuilder($_.ToString())
        $CurrentStringSB.ToString()
}
'System.Diagnostics.Process (System)' | Select-String '(?<=\().*(?=\))' | % Matches 
'System.Diagnostics.Process (System)'
$t = @{}
'1.1.1.1 30.20.7.2 3.1.2.4 1.2.4.6 4.5.6.4 9.8.7.8' | Invoke-Reduction -Consistent -ConvertionTable $t -ReductionRule @(Pattern -CommonPattern IPV4Address)
'1.1.1.1 30.20.7.2' | Invoke-Reduction -ReductionRule @(Pattern -CommonPattern IPPattern)




$File = 'C:\Users\Amir\Desktop\WindowsUpdate.log'

$RulesArr = @(
        Mark '(?<=\d{4}\/\d{2}\/\d{2} \d{2}\:\d{2}\:\d{2}\.\d{7} \d{1,5} \d{1,5} )\w+(?=\s+)' 'Component_{0}'
)

$table = @{}
Get-Content $File | Invoke-Reduction -ReductionRule $RulesArr -Consistent -ConvertionTable $table -AsObject
