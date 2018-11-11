# Sanitization PowerShell Module

## PowerShell module to perform sanitization of sensitive information on a document or a string.

This module helps you replace the sensitive information within a document (or a string) with trash data,  
which also gives you to option to keep the document consistent.  

As an example it can be useful when a vendor requires log from a software that is processing classified or sensitive information.  
Before handing over the log to the vendor, use this module to redact the sensitive information but with consistency kept in tact so the vendor hopefully could still identify a pattern of a problem and help you.  

| Build Status |
| --- |
| [![Build status](https://ci.appveyor.com/api/projects/status/2je7fnhreg7v1scx?svg=true)](https://ci.appveyor.com/project/DCAG/sanitization) |

---

## Installation

### Prerequisits

- Make sure that the computer or server you are going to run this script on has PowerShell version 5.1 or PowerShell Core installed.

### On computer with an internet connection

```powershell
Install-Module Sanitization -Scope UserProfile
```

### On computer without an internet connection

1. Go to a Computer with internet connection and save the module to the local disk

```powershell
Save-Module Sanitization -Path "$env:userprofile\Desktop"
```

2. With a disk on key or any other means copy the module directory to the computer without an internet connection and paste it in the directory C:\Program Files\WindowsPowerShell\Modules\ .

---

## Examples

### Example 1

```powershell
'Apple, Lemon, Menta' | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern 'Lemon' -NewValueString 'Beet'
)
```

Output:

```text
Apple, Beet, Menta
```

### Example 2

```powershell
@(
'Apple, Waffle, Menta'
'Apple, Oreo, Menta'
) | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern 'Apple' -NewValueString 'Banana'
    New-RedactionRule -Pattern '(?<=, )\w+(?=,)' -NewValueString 'Sweets'
)
```

Output:

```text
Banana, Sweets, Menta
Banana, Sweets, Menta
```

### Example 3

```powershell
@(
'Apple, Waffle, Menta'
'Apple, Oreo, Menta'
) | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern 'Apple' -NewValueString 'Banana'
    New-RedactionRule -Pattern '(?<=, )\w+(?=,)' -NewValueString 'Sweet_{0}'
)
```

Output:

```text
Banana, Sweet_0, Menta
Banana, Sweet_1, Menta
```

### Example 4

```powershell
@(
'Apple, Waffle, Menta'
'Apple, Oreo, Menta'
) | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern 'Apple' -NewValueString 'Banana'
    New-RedactionRule -Pattern '(?<=, )\w+(?=,)' -NewValueString 'Sweet_{0}'
    New-RedactionRule -Pattern '(?<=, )\w+$' -NewValueFunction {
        (New-Guid).Guid
    }
)
```

Output:

```text
Banana, Sweet_0, 82b513b7-9f82-4071-9a0d-60c439dc4d56
Banana, Sweet_1, 244a22bc-9f84-44aa-bf12-f5522e93a130
```

### Example 5

```powershell
@(
'Apple, Waffle'
'Apple, Oreo'
) | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern '[^\s,]+' -NewValueString 'A_{0}'
)
```

Output:

```text
A_0, A_0
A_1, A_1
```

### Example 6

```powershell
@(
'Apple, Waffle'
'Apple, Oreo'
) | Invoke-Redaction -Consistent -RedactionRule @(
    New-RedactionRule -Pattern '[^\s,]+' -NewValueString 'A_{0}'
)
```

Output:

```text
A_1, A_0
A_1, A_2
```

### Example 7

```powershell
$Lines = @(
'Apple, Waffle'
'Apple, Oreo'
)

$RedactionRule = @(
    New-RedactionRule -Pattern '[^\s,]+' -NewValueString 'A_{0}'
)

$Lines | Invoke-Redaction -RedactionRule $RedactionRule -Consistent -OutConvertionTable 'Table'

# Print the convertion table
$Table
```

Output:

```text
A_1, A_0
A_1, A_2

Name                           Value
----                           -----
Waffle                         A_0
Apple                          A_1
Oreo                           A_2
```

Although the arragement is different, this example is the same as the previous one with the addition of `-OutConvertionTable 'Table'`.  
New variable `$Table` is created with the hash table used internally as its value.  
It lets us inspect what values were replaced and which new values replced them.

### Example 8

Order of rules is important.

```powershell
@(
'Apple, Waffle, Menta, Banana'
'Apple, Oreo, Menta, Banana'
) | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern 'Apple' -NewValueString 'Banana'
    New-RedactionRule -Pattern 'Banana' -NewValueString 'Kiwi'
)
```

After the 1st rule is processed, 'Apple' is replaced with 'Banana'.

```text
Banana, Waffle, Menta, Banana
Banana, Oreo, Menta, Banana
```

Then 'Banana' is replaced with 'Kiwi'.

Output:

```text
Kiwi, Waffle, Menta, Kiwi
Kiwi, Oreo, Menta, Kiwi
```

If the order of rules is changed it has different result, as seen here:

```powershell
@(
'Apple, Waffle, Menta, Banana'
'Apple, Oreo, Menta, Banana'
) | Invoke-Redaction -RedactionRule @(
    New-RedactionRule -Pattern 'Banana' -NewValueString 'Kiwi'
    New-RedactionRule -Pattern 'Apple' -NewValueString 'Banana'
)
```

Output:

```text
Banana, Waffle, Menta, Kiwi
Banana, Oreo, Menta, Kiwi
```

### Example 9

```powershell
@(
'Apple, Waffle, Menta, Banana'
'Apple, Oreo, Waffle, Banana'
'Apple - Menta - Banana'
) | Invoke-Redaction -AsObject -RedactionRule @(
    New-RedactionRule -Pattern '(?<=^|, )\w+?(?=,|$)' -NewValueString 'Food_{0}'
) | Format-Table -AutoSize
```

Output:

```text
LineNumber CurrentString                  Original                     Changed
---------- -------------                  --------                     -------
         0 Food_0, Food_0, Food_0, Food_0 Apple, Waffle, Menta, Banana    True
         1 Food_1, Food_1, Food_1, Food_1 Apple, Oreo, Waffle, Banana     True
         2 Apple - Menta - Banana         Apple - Menta - Banana         False
```

### Example 10

```powershell
@(
'Apple, Waffle, Menta, Banana'
'Apple, Oreo, Waffle, Banana'
'Apple - Menta - Banana'
) | Invoke-Redaction -AsObject -Consistent -RedactionRule @(
    New-RedactionRule -Pattern '(?<=^|, )\w+?(?=,|$)' -NewValueString 'Food_{0}'
) | Format-Table -AutoSize
```

Output:

```text
LineNumber CurrentString                  Original                     Changed Uniqueness
---------- -------------                  --------                     ------- ----------
         0 Food_3, Food_2, Food_1, Food_0 Apple, Waffle, Menta, Banana    True          4
         1 Food_3, Food_4, Food_2, Food_0 Apple, Oreo, Waffle, Banana     True          5
         2 Apple - Menta - Banana         Apple - Menta - Banana         False          5
```