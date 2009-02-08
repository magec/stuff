    for $x (1 .. 10) {
        for $y (1 .. 10) {
            for $z (1 .. 10) {
                $AoA[$x][$y][$z] =
                    $x ** $y + $z;
            }
        }
    };

  print @{$AoA[1][1]};
