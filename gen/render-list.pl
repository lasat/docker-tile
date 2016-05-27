#!/usr/bin/env perl

$ZOOM = $ARGV[0] || 12;
$META = $ARGV[1] || 8;

foreach $z (0..$ZOOM) {
  $cols = 2**$z;
  if ($cols <= $META) {
    print "$z:0:$cols\n";
  } else {
    for ($col = 0; $col < $cols; $col += $META) {
      $endcol = $col + $META;
      print "$z:$col:$endcol\n";
    }
  }
}
