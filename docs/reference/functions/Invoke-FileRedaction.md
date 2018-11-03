---
external help file: Sanitization-help.xml
Module Name: Sanitization
online version:
schema: 2.0.0
---

# Invoke-FileRedaction

## SYNOPSIS

Redact sensitive information from a file

## SYNTAX

### Path

```powershell
Invoke-FileRedaction [-RedactionRule] <RedactionRule[]> [-Path] <String[]> [-ReadRaw] [<CommonParameters>]
```

### LiteralPath

```powershell
Invoke-FileRedaction [-RedactionRule] <RedactionRule[]> [-LiteralPath] <String[]> [-ReadRaw]
 [<CommonParameters>]
```

## DESCRIPTION

Redact sensitive information from a file as an array of strings or one long string by defined redaction rules.

## EXAMPLES

### EXAMPLE 1

```powershell
$WULog = "$env:USERPROFILE\Desktop\WULog.log"
Get-WindowsUpdateLog -LogPath $WULog
Invoke-FileRedaction -Path $WULog -ReadRaw -RedactionRule @(
    New-RedactionRule '(?<=\d{4}\/\d{2}\/\d{2} \d{2}\:\d{2}\:\d{2}\.\d{7} \d{1,5} \d{1,5}\s+)\w+(?=\s+)' 'Component_{0}'
)
```

## PARAMETERS

### -RedactionRule

Array of rules to redact by.

```yaml
Type: RedactionRule[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Specifies a path to one or more locations.  
Wildcards are permitted.  

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### -LiteralPath

Specifies a path to one or more locations.  
Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed.  
No characters are interpreted as wildcards.  
If the path includes escape characters, enclose it in single quotation marks.  
Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.  

```yaml
Type: String[]
Parameter Sets: LiteralPath
Aliases: PSPath

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ReadRaw

Ignores newline characters and pass the entire contents of a file in one string with the newlines preserved.  
By default, newline characters in a file are used as delimiters to separate the input into an array of strings.  
Process the file as one string instead of processing the strings line by line.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.  
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Invoke-RedactionRule creates 2 files in the same location of the input file.  
The redacted file with "-Sanitized.txt" suffix and the convertion table csv file with "-ConvertionTable.csv" suffix.  
By default all strings in the files are processed with Invoke-Redaction with the -Consistent parameter.

## RELATED LINKS
