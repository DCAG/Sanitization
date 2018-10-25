function Convert-IPValue {
    [long]$t = $args[0]

    $o4 = ($t % 254) + 1
    $t = $t / 254
    $o3 = $t % 254
    $t = $t / 254 
    $o2 = $t % 254
    $t = $t / 254
    $o1 = $t % 254 + 11

    "$o1.$o2.$o3.$o4"
}
