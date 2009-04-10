#!/usr/bin/perl
# 
# A simple Perl-based calculator for network engineers/researchers.
# Copyright (c) 2004, Hiroyuki Ohsaki.
# All rights reserved.
# 
# $Id: calc,v 1.20 2005/11/02 08:39:08 oosaki Exp $
# 

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

use Getopt::Std;
use Term::ReadLine;
use strict;

$| = 1;

getopts('dp:') || die "usage: $0 [-d] [-p #]\n";

my $DEBUG = $::opt_d;
my $PACKET_SIZE = $::opt_p || 1000;

my %PREFIX_TABLE = (
    n => 10**-9,
    u => 10**-6,
    m => 10**-3,
    k => 10**3,
    K => 10**3,
    M => 10**6,
    G => 10**9,
    T => 10**12,
    P => 10**15,
);
my $PREFIX_REGEXP = '(' . join ( '|', keys %PREFIX_TABLE ) . ')';

my %UNIT_TABLE = (
    s      => 1,
    m      => 1 / 300000000,
    bit    => 1 / 8,
    bps    => 1 / 8,
    byte   => 1,
    B      => 1,
    pkt    => $PACKET_SIZE,
    packet => $PACKET_SIZE,
);
my $UNIT_REGEXP = '(' . join ( '|', keys %UNIT_TABLE ) . ')';

sub expand_single_unit {
    my $str = shift;

    return 1 unless (defined $str);
    return 1 unless ( $str =~ m!${PREFIX_REGEXP}?\s*${UNIT_REGEXP}?! );
    my ( $prefix, $unit ) = ( $1 || '', $2 || '' );
    ( $prefix, $unit ) = ( '', 'm' ) if ( $prefix eq 'm' and $unit eq '' );
    return ( ( $prefix and exists $PREFIX_TABLE{$prefix} )
	     ? $PREFIX_TABLE{$prefix}
	     : 1 ) *
		 ( ( $unit and exists $UNIT_TABLE{$unit} )
		   ? $UNIT_TABLE{$unit}
		   : 1 );
}

sub expand_unit {
    my $str = shift;

    @_ = split ( '/', $str );
    return ( expand_single_unit($_[0]) / expand_single_unit($_[1]) );
}

my $term    = new Term::ReadLine 'calc';
my $attribs = $term->Attribs;
$attribs->{completion_entry_function} = $attribs->{list_completion_function};
$attribs->{completion_word}           = [qw()];
my $count   = 1;
my @history = ();

while ( defined( $_ = $term->readline('? ') ) ) {
    next unless $_;
    ( system( 'perldoc', $0 ), next ) if /^\?/;

    # expand history reference
    s/%(\d+)/$history[$1]/eg;
    s/%/$history[$count - 1]/eg;

    # expand units in arguments
    1 while (s/([\d.]+)\s*\[(.*?)\]/"($1*" . expand_unit($2) . ")"/e);

    # evaluate expression
    print "eval \$_ = $_\n" if $DEBUG;
    eval "\$_ = $_;";

    # print result in several formats
    print "%$count = $_\n";
    $history[ $count++ ] = $_;

    printf "%12x %-6s", $_, "hex";
    printf "%12o %-6s", $_, "oct";
    my $binary = unpack( 'B*', pack( 'N', $_ ) );
    $binary =~ s/([01]{8})/$1 /g;
    printf "%s\n", $binary;

    for my $unit (qw(bit/ms bit/s Kbit/s Mbit/s)) {
        printf "%12.4g %-6s", $_ / expand_unit($unit), $unit;
    }
    print "\n";

    for my $unit (qw(B/ms B/s KB/s MB/s)) {
        printf "%12.4g %-6s", $_ / expand_unit($unit), $unit;
    }
    print "\n";

    for my $unit (qw(pkt/ms pkt/s m km)) {
        printf "%12.4g %-6s", $_ / expand_unit($unit), $unit;
    }
    print "\n";
}

__END__

=head1 NAME

calc - A simple Perl-based calculator for network engineers/researchers

=head1 SYNOPSIS

  calc [-d] [-p #]

=head1 DESCRIPTION

This manual page documents B<calc>.  This program is an interactive
text-based calculator written in Perl and supporting GNU readline
library.  B<calc> is specifically designed for network
engineers/researchers since it can easily handle network-related units
such as bit, byte, packet, bps, and bit/s.

After invocation, B<calc> displays a prompt "?", and ask for a user to
enter an arbitrary expression to be calculated, which must be a valid
Perl expression.  B<calc> then evaluates the expression as-is, and
displays the return value in a decimal format, followed by values in
hex, octal, and binary formats.

For typical daily use, the following builtin functions of Perl would
be convenient.  See perlfunc(1) for information on other builtin
functions.

  Numeric functions
    "abs", "atan2", "cos", "exp", "hex", "int", "log",
    "oct", "rand", "sin", "sqrt", "srand"

Note that B<calc> supports GNU readline library, so that a user can
interactively edit his/her input with Emacs-like (user-configurable)
qkey bindings.  See the manual page of GNU readline library for its
details.

B<calc> understands the following units, which must be enclosed in
square brackets.

  s            second
  m            meter
  bit          bit
  bps          bit per second
  byte, B      byte
  pkt, packet  packet

By default, packet size is assumed to be 1,500 [byte] (i.e., Ethernet
payload size), but it can be changed by B<-p> option. 

B<calc> supports the following prefixes.

  p     pico   10**-12
  n     nano   10**-9
  u     micro  10**-6
  m     milli  10**-3
  k, K  kilo   10**3
  M     mega   10**6
  G     giga   10**9
  T     tera   10**12
  P     peta   10**15

In B<calc>, the base unit is either second or byte, and all values in
other than second or byte are automatically converted.  For example,
1000 [bit/ms] is automatically converted to 125000 [byte/s].  See
L<"EXAMPLES"> for detailed usage of B<calc>.

=head1 EXAMPLES

This section shows an example session with of B<calc>.

A simple arithmetic calculation

  ? 1+2*(3+4/5)**6
  %1 = 6022.872768
          1786 hex          13606 oct   00000000 00000000 00010111 10000110 
         48.18 bit/ms   4.818e+04 bit/s        48.18 Kbit/s     0.04818 Mbit/s
         6.023 B/ms          6023 B/s          6.023 KB/s      0.006023 MB/s  
      0.004015 pkt/ms       4.015 pkt/s    1.807e+12 m        1.807e+09 km    

Blank spaces are arbitrary

  ? 1 + 2 * (3 + 4 / 5) ** 6
  %2 = 6022.872768
          1786 hex          13606 oct   00000000 00000000 00010111 10000110 
         48.18 bit/ms   4.818e+04 bit/s        48.18 Kbit/s     0.04818 Mbit/s
         6.023 B/ms          6023 B/s          6.023 KB/s      0.006023 MB/s  
      0.004015 pkt/ms       4.015 pkt/s    1.807e+12 m        1.807e+09 km    

The previous result can be referred by "%"

  ? % + 1
  %3 = 6023.872768
          1787 hex          13607 oct   00000000 00000000 00010111 10000111 
         48.19 bit/ms   4.819e+04 bit/s        48.19 Kbit/s     0.04819 Mbit/s
         6.024 B/ms          6024 B/s          6.024 KB/s      0.006024 MB/s  
      0.004016 pkt/ms       4.016 pkt/s    1.807e+12 m        1.807e+09 km    

Past results can be referred by "%N"

  ? %1 - %2
  %4 = 0
             0 hex              0 oct   00000000 00000000 00000000 00000000 
             0 bit/ms           0 bit/s            0 Kbit/s           0 Mbit/s
             0 B/ms             0 B/s              0 KB/s             0 MB/s  
             0 pkt/ms           0 pkt/s            0 m                0 km    

Perl builtin functions can be used

  ? int(%1)
  %5 = 6022
          1786 hex          13606 oct   00000000 00000000 00010111 10000110 
         48.18 bit/ms   4.818e+04 bit/s        48.18 Kbit/s     0.04818 Mbit/s
         6.022 B/ms          6022 B/s          6.022 KB/s      0.006022 MB/s  
      0.004015 pkt/ms       4.015 pkt/s    1.807e+12 m        1.807e+09 km    

  ? log(sin(1) + cos(2))

  %6 = -0.854903698976914
             0 hex              0 oct   00000000 00000000 00000000 00000000 
     -0.006839 bit/ms      -6.839 bit/s    -0.006839 Kbit/s  -6.839e-06 Mbit/s
    -0.0008549 B/ms       -0.8549 B/s     -0.0008549 KB/s    -8.549e-07 MB/s  
    -5.699e-07 pkt/ms  -0.0005699 pkt/s   -2.565e+08 m       -2.565e+05 km    

Variables can store values

  ? $a = 12345
  %7 = 12345
          3039 hex          30071 oct   00000000 00000000 00110000 00111001 
         98.76 bit/ms   9.876e+04 bit/s        98.76 Kbit/s     0.09876 Mbit/s
         12.35 B/ms     1.234e+04 B/s          12.35 KB/s       0.01235 MB/s  
       0.00823 pkt/ms        8.23 pkt/s    3.704e+12 m        3.704e+09 km    

  ? $a + 1
  %8 = 12346
          303a hex          30072 oct   00000000 00000000 00110000 00111010 
         98.77 bit/ms   9.877e+04 bit/s        98.77 Kbit/s     0.09877 Mbit/s
         12.35 B/ms     1.235e+04 B/s          12.35 KB/s       0.01235 MB/s  
      0.008231 pkt/ms       8.231 pkt/s    3.704e+12 m        3.704e+09 km    

  ? $b = 12345
  %9 = 12345
          3039 hex          30071 oct   00000000 00000000 00110000 00111001 
         98.76 bit/ms   9.876e+04 bit/s        98.76 Kbit/s     0.09876 Mbit/s
         12.35 B/ms     1.234e+04 B/s          12.35 KB/s       0.01235 MB/s  
       0.00823 pkt/ms        8.23 pkt/s    3.704e+12 m        3.704e+09 km    

  ? $a - $b
  %10 = 0
             0 hex              0 oct   00000000 00000000 00000000 00000000 
             0 bit/ms           0 bit/s            0 Kbit/s           0 Mbit/s
             0 B/ms             0 B/s              0 KB/s             0 MB/s  
             0 pkt/ms           0 pkt/s            0 m                0 km    

Example usage of some builtin functions

  ? hex("ffff")
  %11 = 65535
          ffff hex         177777 oct   00000000 00000000 11111111 11111111 
         524.3 bit/ms   5.243e+05 bit/s        524.3 Kbit/s      0.5243 Mbit/s
         65.53 B/ms     6.554e+04 B/s          65.53 KB/s       0.06553 MB/s  
       0.04369 pkt/ms       43.69 pkt/s    1.966e+13 m        1.966e+10 km    

  ? oct("7777")
  %12 = 4095
           fff hex           7777 oct   00000000 00000000 00001111 11111111 
         32.76 bit/ms   3.276e+04 bit/s        32.76 Kbit/s     0.03276 Mbit/s
         4.095 B/ms          4095 B/s          4.095 KB/s      0.004095 MB/s  
       0.00273 pkt/ms        2.73 pkt/s    1.228e+12 m        1.228e+09 km    

  ? sqrt(2943)
  %13 = 54.2494239600754
            36 hex             66 oct   00000000 00000000 00000000 00110110 
         0.434 bit/ms         434 bit/s        0.434 Kbit/s    0.000434 Mbit/s
       0.05425 B/ms         54.25 B/s        0.05425 KB/s     5.425e-05 MB/s  
     3.617e-05 pkt/ms     0.03617 pkt/s    1.627e+10 m        1.627e+07 km    

  ? abs(%)
  %14 = 54.2494239600754
            36 hex             66 oct   00000000 00000000 00000000 00110110 
         0.434 bit/ms         434 bit/s        0.434 Kbit/s    0.000434 Mbit/s
       0.05425 B/ms         54.25 B/s        0.05425 KB/s     5.425e-05 MB/s  
     3.617e-05 pkt/ms     0.03617 pkt/s    1.627e+10 m        1.627e+07 km    

  ? abs(-%)
  %15 = 54.2494239600754
            36 hex             66 oct   00000000 00000000 00000000 00110110 
         0.434 bit/ms         434 bit/s        0.434 Kbit/s    0.000434 Mbit/s
       0.05425 B/ms         54.25 B/s        0.05425 KB/s     5.425e-05 MB/s  
     3.617e-05 pkt/ms     0.03617 pkt/s    1.627e+10 m        1.627e+07 km    

Convert a transmission rate in several units

  ? 123 [packet/ms]
  %16 = 184500000
       aff3f20 hex     1277637440 oct   00001010 11111111 00111111 00100000 
     1.476e+06 bit/ms   1.476e+09 bit/s    1.476e+06 Kbit/s        1476 Mbit/s
     1.845e+05 B/ms     1.845e+08 B/s      1.845e+05 KB/s         184.5 MB/s  
           123 pkt/ms    1.23e+05 pkt/s    5.535e+16 m        5.535e+13 km    

From the above result, one can see 123 [packet/ms] is equivalent to
1476 [Mbit/s] with 1,500 [byte] packet.

Product of transmission rate and duration gives the total amount of
data transferred

  ? % * 10[s]
  %17 = 1845000000
      6df87740 hex    15576073500 oct   01101101 11111000 01110111 01000000 
     1.476e+07 bit/ms   1.476e+10 bit/s    1.476e+07 Kbit/s   1.476e+04 Mbit/s
     1.845e+06 B/ms     1.845e+09 B/s      1.845e+06 KB/s          1845 MB/s  
          1230 pkt/ms    1.23e+06 pkt/s    5.535e+17 m        5.535e+14 km    

Thus, if you continuosly send 10 [s] at the transmission rate of 123
[packet/ms], the total volume transferred is 1845 [MB].

Data size divided by duration gives transmission rate

  ? 6.4[Gbyte]/120[s]
  %18 = 53333333.3333333
       32dcd55 hex      313346525 oct   00000011 00101101 11001101 01010101 
     4.267e+05 bit/ms   4.267e+08 bit/s    4.267e+05 Kbit/s       426.7 Mbit/s
     5.333e+04 B/ms     5.333e+07 B/s      5.333e+04 KB/s         53.33 MB/s  
         35.56 pkt/ms   3.556e+04 pkt/s      1.6e+16 m          1.6e+13 km    

So, if 6.4 [Gbyte] is trensferred in 120 [s], the transmission rate of
the network is 426.7 [Mbit/s].

Calculate the bandwidth-delay product

  ? 64[packet] * 120[ms]
  %19 = 11520
          2d00 hex          26400 oct   00000000 00000000 00101101 00000000 
         92.16 bit/ms   9.216e+04 bit/s        92.16 Kbit/s     0.09216 Mbit/s
         11.52 B/ms     1.152e+04 B/s          11.52 KB/s       0.01152 MB/s  
       0.00768 pkt/ms        7.68 pkt/s    3.456e+12 m        3.456e+09 km    

which indicates that, for instance, 11.52 [KB] socket buffer is at
least required for TCP window flow control with its window size of 64
[packet] and the round-trip time of 120 [ms].

Values in meters are converted to seconds, time to need to travel in
speed of the light

  ? 128[km]
  %20 = 0.000426666666666666
             0 hex              0 oct   00000000 00000000 00000000 00000000 
     3.413e-06 bit/ms    0.003413 bit/s    3.413e-06 Kbit/s   3.413e-09 Mbit/s
     4.267e-07 B/ms     0.0004267 B/s      4.267e-07 KB/s     4.267e-10 MB/s  
     2.844e-10 pkt/ms   2.844e-07 pkt/s     1.28e+05 m              128 km    

which shows the light travels 128 [km] in 0.000426 [s].

Conversely, values in seconds are displayed in meters

  ? 0.0012[ms]
  %21 = 1.2e-06
             0 hex              0 oct   00000000 00000000 00000000 00000000 
       9.6e-09 bit/ms     9.6e-06 bit/s      9.6e-09 Kbit/s     9.6e-12 Mbit/s
       1.2e-09 B/ms       1.2e-06 B/s        1.2e-09 KB/s       1.2e-12 MB/s  
         8e-13 pkt/ms       8e-10 pkt/s          360 m             0.36 km    

So, one can see that the light travels 0.36 [km] in 0.0012 [ms].

=head1 AVAILABILITY

The latest version of B<calc> can is available at

http://www.ispl.jp/~oosaki/software/calc/calc

=head1 SEE ALSO

perl(1), perlfunc(1), readline(3)

=head1 AUTHOR

Hiroyuki Ohsaki <oosaki[atmark]ist.osaka-u.ac.jp>

=cut
