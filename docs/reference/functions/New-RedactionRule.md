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

```powershell
New-RedactionRule [-Pattern] <String> [-NewValueFunction] <ScriptBlock> [<CommonParameters>]
```

### CustomString

```powershell
New-RedactionRule [-Pattern] <String> [-NewValueString] <String> [<CommonParameters>]
```

### Common

```powershell
New-RedactionRule [-CommonRule] <String> [<CommonParameters>]
```

## DESCRIPTION

Creates new redaction rule with regex pattern to look for and NewValue to replace with.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> New-RedactionRule '(?<=\().*(?=\))' 'Process_{0}'

Pattern         NewValueFunction NewValueString Type
-------         ---------------- -------------- ----
(?<=\().*(?=\))                  Process_{0}    String
```

Creating redaction rule with new-value-string using positional parameters.

### EXAMPLE 2

```powershell
PS> Mark '[a-z]' {
    [long]$p = $args[0]
    [char]($p % 26 + 65)
}

Pattern NewValueFunction                            NewValueString Type
------- ----------------                            -------------- ----
[a-z]    [long]$p = $args[0]; [char]($p % 26 + 65)                 Function
```

The call to create new redaction rule is made with the alias `Mark` instead of `New-RedactionRule`.
Creating redaction rule with new-value-function using positional parameters.  
Scriptblock is detected automatically and assigned to `-NewValueFunction` parameter.  
The script block accepts one number parameter/argument:

- When `-Consistent` is used in Invoke-Redaction - The argument is populated with uniquness value.
- and when `-Consistent` is **not** used in Invoke-Redaction - The argument is populated with the current line number.

### EXAMPLE 3

```powershell
PS> $IPRule = Mark -CommonRule IPV4Address
PS> $IPRule.Pattern
\b(\d{1,3}(\.\d{1,3}){3})\b
PS> $IPRule.NewValueFunction

    [int]$t = $args[0]

    $o4 = ($t % 254) + 1
    $t = $t / 254
    $o3 = $t % 254
    $t = $t / 254
    $o2 = $t % 254
    $t = $t / 254
    $o1 = $t % 254 + 11

    "$o1.$o2.$o3.$o4"

```

Create a rule with predefined definition or pattern and new value (function) to obfuscate an IP address.

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
