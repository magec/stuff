#!/usr/bin/perl -w

&getValues();
$exp = $FORM{'input'} || "0";
$res = eval($exp) || "Error";
print <<EOF;
Content-Type: text/html
<html><body>
<b>Testr:</b><br/>
<form action="/cgi-bin/tst.pl" method="POST">
<table border="0">
<tr><td align="right">ASDF:</td>
<td><input type="text" name="input" value="$exp"/></td></tr>
<tr><td align="right">Result:</td>
<td>$res</td></tr>
<tr><td></td>
<td><input type="submit" value="OAL"/></td></tr>
</table></form>
</html></body>
EOF

foreach $key (keys %ENV) {
    print "$key -> $ENV{$key}<br>";
}

exit;

sub getValues {
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs) {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
    }
}
