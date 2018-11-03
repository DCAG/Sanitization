---
external help file: Sanitization-help.xml
Module Name: Sanitization
online version:
schema: 2.0.0
---

# New-RedactionRule

## SYNOPSIS
Creates new redaction rule.

## SYNTAX

### CustomFunction (Default)
```
New-RedactionRule [-Pattern] <String> [-NewValueFunction] <ScriptBlock> [<CommonParameters>]
```

### CustomString
```
New-RedactionRule [-Pattern] <String> [-NewValueString] <String> [<CommonParameters>]
```

### Common
```
New-RedactionRule [-CommonRule] <String> [<CommonParameters>]
```

## DESCRIPTION
Creates new redaction rule with regex pattern to look for and NewValue to replace with.

## EXAMPLES

### EXAMPLE 1
```
New-RedactionRule '(?<=\().*(?=\))' 'Process_{0}'
```

### EXAMPLE 2
```
Mark '[a-z]' { [long]$p = $args[0]; [char]($p % 26 + 65) }
```

### EXAMPLE 3
```
Mark -CommonRule IPV4Address
```

## PARAMETERS

### -Pattern
Regex pattern

```yaml
Type: String
Parameter Sets: CustomFunction, CustomString
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewValueFunction
Script block to generate new generic data, the result is then put instead of the original value.
This script block can accept at most 1 int parameter with $args\[0\] or declare variable in param() block

```yaml
Type: ScriptBlock
Parameter Sets: CustomFunction
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewValueString
String value to be replaced instead of pattern.
The string can contain place holder {0}, and it will be replaced with uniqueness factor.

```yaml
Type: String
Parameter Sets: CustomString
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommonRule
Predefined rules - patterns and values

```yaml
Type: String
Parameter Sets: Common
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### RedactionRule

## NOTES

## RELATED LINKS
