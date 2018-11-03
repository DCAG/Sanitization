---
external help file: Sanitization-help.xml
Module Name: Sanitization
online version:
schema: 2.0.0
---

# Invoke-Redaction

## SYNOPSIS
Redact sensitive information from an object

## SYNTAX

```
Invoke-Redaction [-RedactionRule] <RedactionRule[]> [-InputObject] <PSObject> [-Consistent] [-AsObject]
 [-TotalLines <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Redact sensitive information from an object as string by defined redaction rules

## EXAMPLES

### EXAMPLE 1
```
Replace all a-z letters with '+' sign
```

$RedactionRule = New-RedactionRule -Pattern '\[a-z\]' -NewValueString '+'
ipconfig /all | Invoke-Redaction -RedactionRule $RedactionRule

### EXAMPLE 2
```
Replace all service names that start with the letter 's' with 's_{0}', where {0} is replaced by uniqueness factor.
```

Each unique serivce name will be replaced with a unique new value 's_{0}' and it will stay consistent if the service shows up multiple times.
$RedactionRule = New-RedactionRule -Pattern '(?\<=\s)\[Ss\].+' -NewValueString 's_{0}'
Get-Process | Out-String | Invoke-Redaction -RedactionRule $RedactionRule -Consistent

## PARAMETERS

### -RedactionRule
Array of redaction rules to redact by

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

### -InputObject
String to redact sensitive information from

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Consistent
Saves discovered values in a ConvertionTable (hash table), when the same values disceverd again they are replaced with the same string that was generated the first time from the redaction rule NewValue function or NewValue formatted string.
It uses a uniqueness value to generate new value from the redaction rule (if applicable).
if Consistent is ommitted generation of new value from redaction rule's NewValues is based on current line number.

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

### -AsObject
Return an object with the old string, the processed string, line number and if the string was changed or not instead of just a processed string.

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

### -TotalLines
Number of lines that are going to be processed over the pipeline.
Relevant for showing informative progress bar.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
