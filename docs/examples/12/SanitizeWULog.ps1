$LogFile = "WULog.log"
Invoke-FileRedaction -Path $LogFile -ReadRaw -RedactionRule @(
        New-RedactionRule -Pattern '\b[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}\b' -NewValueFunction {
                [Guid]::NewGuid().Guid
        }
        New-RedactionRule -Pattern '(?<=\d{2}:\d{2}:\d{2}\.\d{7}\s+\d+\s+\d+\s+)[^\s]+?(?=\s{1,})' -NewValueString "Component_{0}"
        New-RedactionRule -Pattern '(?<=PN=)[^\s;]+?(?=;|\s|$|\n)' -NewValueString "Product_{0}"
        New-RedactionRule -Pattern '(?<=(E:|\?)[^\s]*\=)[^\s&=]+?(?=&|\s|$|\n)' -NewValueString "UriParam_{0}"
        New-RedactionRule -Pattern '(?-i)Microsoft\.com' -NewValueString "Contoso.co.au"
        New-RedactionRule -Pattern 'microsoft\.com' -NewValueString "contoso.co.au"
        New-RedactionRule -Pattern '(?-i)Microsoft' -NewValueString "Contoso"
        New-RedactionRule -Pattern 'microsoft' -NewValueString "contoso"
        New-RedactionRule -Pattern 'Dell' -NewValueString "Msi"
        New-RedactionRule -Pattern '(?<=\((cV: |cV = ))[^\s]+?(?=(\.\d+){1,}\))' -NewValueString 'cV_{0}'
        New-RedactionRule -Pattern '(?<=Destaging package )[^\s]*?(?=\s|$|\n)' -NewValueString 'DestagingPackage_{0}'
        New-RedactionRule -Pattern '(?<=IntentPFaNs = )[^\s]*?(?=\s|$|\n)' -NewValueString 'PFaNs_{0}'
        New-RedactionRule -Pattern '(?<=Title = ).+?(?=$|\n)' -NewValueString 'ApplicationSet_{0}'
        New-RedactionRule -Pattern '(?<=Non-required installable package \().+(?=\) found!)' -NewValueString 'Package_{0}'
        New-RedactionRule -Pattern 'S-1-5-21-\d{10}-\d{10}-\d{10}-1001' -NewValueFunction {                
                $Group1 = -join (1..10 | ForEach-Object{0..9 | Get-Random})
                $Group2 = -join (1..10 | ForEach-Object{0..9 | Get-Random})
                $Group3 = -join (1..10 | ForEach-Object{0..9 | Get-Random})
                'S-1-5-21-{0}-{1}-{2}-1001' -f $Group1,$Group2,$Group3
        }
)