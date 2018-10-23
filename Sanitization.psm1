<#
.Synopsis
   Replace string with regex patterns
.DESCRIPTION
   Replace string with regex patterns
   Good for blackening purposes usually.
.AUTOR
   Amir Granot 9.7.2016
#>

$Source = '.\Source'
$Classes= "$Source\Classes"
$Private= "$Source\Private"
$Public = "$Source\Public"

Get-ChildItem "$Classes\*" | ForEach-Object {. $_}
Get-ChildItem "$Private\*" | ForEach-Object {. $_}

# Files must be imported in this order
. "$Public\New-RedactionRule.ps1"
. "$Public\Invoke-Redaction.ps1"
. "$Public\Invoke-FileRedaction.ps1"

$PublicFunctions = Get-ChildItem "$Public\*"

Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *