class RedactionRule {
    [ValidateNotNullOrEmpty()][string]$Pattern
    [scriptblock]$NewValueFunction
    [string]$NewValueString
    [ValidateSet('String','Function')][string]$Type

    RedactionRule ([string]$Pattern, [string]$NewValueString) {
        $this.Pattern          = $Pattern
        $this.NewValueString   = $NewValueString
        $this.NewValueFunction = $null
        $this.Type             = 'String'
    }

    RedactionRule ([string]$Pattern, [scriptblock]$NewValueFunction) {
        $this.Pattern          = $Pattern
        $this.NewValueFunction = $NewValueFunction
        $this.NewValueString   = $null
        $this.Type             = 'Function'
    }

    [string] Evaluate([int]$Seed){
        if($this.Type -eq 'String'){
            return ($this.NewValueString -f $Seed)
        }else{ # $this.Type -eq 'Function'
            return (& $this.NewValueFunction $Seed)
        }
    }
}