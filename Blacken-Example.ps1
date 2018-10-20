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
        Pattern "(?<=Windows service ).+(?= associated)" {"Service_{0}"}
        Pattern "(?<=group WinNT://(.*/)+).+(?= details on remote)|(?<=of group ).+(?= on remote)" {"UserOrGroup_{0}"}
        Pattern "(?<=Account ).*(?= causes)|(?<=\d - ).*(?= have \d)|\b[a-z0-9]{5,7}-x\b|(?<=Retrieving user ).+(?= details on)|(?<=to account ).+(?=\.)|(?<=User Principal ').+(?=' details from)|(?<=account ).+(?= details)|(?<=member path WinNT://(.*/){1,}).+(?= of group)" {"UserOrGroup_{0}"}
        Pattern "\bS(-\d{1,15}){6,7}\b" {"SID_{0}"}
        Pattern -CommonPattern IPPattern                                                  
        Pattern "\b([\w-]+\.myDom\.dom)\b" {"Server_{0}.$($Convert["myDom.dom"])"}
        Pattern "\b(?<ServerName>[a-zA-Z0-9-]*\.myDom\.dom)\b" {"Server_{0}.$($Convert["myDom.dom"])"}
        Pattern "\bmyDom\.dom\b" {$Convert["myDom.dom"]}
        Pattern "MYDOM" {"YOURDOMAIN"} #{$Convert["MYDOM"]}
        Pattern "CN=.* in LDAP path" {"CN=CN_{0} in LDAP path"}
        Pattern "OU=infra,DC=myDom,DC=dom" {"OU=soft,$($Convert["DC=myDom,DC=dom"])"}
        Pattern "DC=myDom,DC=dom" {$Convert["DC=myDom,DC=dom"]}
        Pattern "OU 'myDom > infra' " {"OU 'mila > kunis' "}
        Pattern '(?<=\().*(?=\))' {'Process_{0}' -f $args[0]}
)

Get-Process | Replace-String -AsObject -Pattern $rulesArr | ft -AutoSize
#-Consistent -ConvertionTable $Convert
# Write convertion table
$Convert.Keys | Select-Object -Property @{N = 'Original'; E = {$_}}, @{N = 'NewValue'; E = {$Convert[$_]}} | Sort-Object -Property NewValue | Export-Csv $tableFile -Force -NoTypeInformation
    

'System.Diagnostics.Process (System)' | Select-String '(?<=\().*(?=\))' | % Matches
$t = @{}
'1.1.1.1 30.20.7.2 3.1.2.4 1.2.4.6 4.5.6.4 9.8.7.8' | Replace-String -Consistent -ConvertionTable $t -Pattern @(Pattern -CommonPattern IPPattern)
'1.1.1.1 30.20.7.2' | Replace-String -Pattern @(Pattern -CommonPattern IPPattern)