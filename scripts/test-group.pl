#!/usr/bin/perl
# Funciones para ordenar y agrupar un listado de puertos de un switch u otros.

use strict;

my @ports = qw/ fe.2.10 fe.2.1 lag0 fe.1.1 fe.1.3 fe.1.4 fe.1.5 fe.1.6 fe.1.7 fe.1.8 fe.1.9 fe.1.10 fe.1.11 fe.2.1 fe.2.2 fe.2.9 ge.1.1 ge.1.2 ge.1.3 ge.1.10 fe.2.1 /;


sub TrueSort() { # http://www.perlmonks.org/?node_id=483462
	my @list = @_;
	return @list[
	    map { unpack "N", substr($_,-4) }
	    sort
    	map {
        	my $key= $list[$_];
	        $key =~ s[(\d+)][ pack "N", $1 ]ge;
    	    $key . pack "N", $_
	    } 0..$#list
	];
}

sub RDigits() { #Devuelve los digitos a la derecha del string
	return $& if "@_[0]" =~ /\d+$/g;
}

sub AgrArr() { #Agrupa los puertos de un array de un chui
	my @out=();
	my $cache=undef;
	my @array=&TrueSort(@_); 
	for my $i (0..$#array) {
		next if $array[$i] eq $array[$i+1]; #Nos cargamos los duplicados 
		if ( (&RDigits($array[$i])+1) != &RDigits($array[$i+1]) ) {
			push (@out, $cache.$array[$i]);
			undef($cache);
		} elsif ( ! defined($cache) ) {
			$cache = "$array[$i]-";
		}
	}
	return @out;
}

print "Original: ".join( ', ', @ports )."\n";
print "\nOrdenado: ".join( ', ', &AgrArr(@ports) )."\n";
