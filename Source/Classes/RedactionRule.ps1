class RedactionRule {
    [ValidateNotNullOrEmpty()][string]$Pattern

    [string] Evaluate([int]$Seed){
        throw "Cannot call Evaluate from base class"
    }
}

class RedactionRuleFunction:RedactionRule {
    [ValidateNotNullOrEmpty()][scriptblock]$NewValue

    RedactionRuleFunction ([string]$Pattern, [scriptblock]$NewValue) {
        $this.Pattern = $Pattern
        $this.NewValue = $NewValue
    }

    [string] Evaluate([int]$Seed){
        return (& $this.NewValue $Seed)
    }
}

class RedactionRuleString:RedactionRule {
    [ValidateNotNullOrEmpty()][string]$NewValue

    RedactionRuleString ([string]$Pattern, [string]$NewValue) {
        $this.Pattern = $Pattern
        $this.NewValue = $NewValue
    }

    [string] Evaluate([int]$Seed){
        return ($this.NewValue -f $Seed)
    }
}