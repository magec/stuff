#--------------------------------------------------------------------------------------------------
sub getCGIParams {
    my $line;
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
        read(STDIN, $line, $ENV{'CONTENT_LENGTH'});
    } else {
        $line = $ENV{'QUERY_STRING'};
    }

    my (@pairs) = split(/&/, $line);
    my ($name, $value, %F);
    foreach (@pairs) {
        ($name, $value) = split(/=/);
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        if (! exists $F{$name}) {
            $F{$name} = $value;
        } elsif (exists $F{$name} and ref($F{$name}) ne 'ARRAY') {
            my $prev_value = $F{$name};
            delete $F{$name};
            $F{$name} = [ $prev_value, $value ];
    } else { push @{ $F{$name} }, $value }
    }
    return \%F;
}
#--------------------------------------------------------------------------------------------------
