#!/usr/bin/perl -w
# http://search.cpan.org/src/HARDAKER/SNMP-5.0401/t/bulkwalk.t

use strict;
use Net::Telnet;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

sub header() {
    my $date = scalar localtime();
    print "Content-Type: text/html\n\n";
    print <<EOF;
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=utf-8">
        <TITLE>$0 // $date</TITLE>
        <script type="text/javascript" src="../sorttable.js"></script>
    </HEAD>
<BODY>
EOF
}

sub footer() {
    print "</BODY></HTML>";
}

sub highlander() {
    use Fcntl qw(LOCK_EX LOCK_NB);

    open HIGHLANDER, ">>/tmp/perl_$0_highlander" or die "Content-Type: text/html\n\nCannot open highlander: $!";

    {
        flock HIGHLANDER, LOCK_EX | LOCK_NB and last;
        print "Content-Type: text/html\n\nScript en uso!";
        exit 0;
    }
}

sub getarray() {
    my $telnet = new Net::Telnet ( Timeout  => 5
                                 , Errmode  => 'die'
                                 , Prompt   => '/RBT8200castelldefels[>#]/i'
                                 );
    $telnet->open('192.168.XXX.XX');
    $telnet->login('admin', 'xxxxxxx');
    $telnet->print('enable');
    $telnet->waitfor('/Enter password:/i');
    $telnet->cmd('enable_pass');
    $telnet->cmd('set length 0');
    return $telnet->cmd('show ap status all name');
}

sub filltables(@) {
    exit 0 if $#_ < 7;  # El header es de 8 filas por lo menos.
    my @header = @_[0..7];
    chomp @header;

    # Header
    print '<TABLE style="border-style:solid; border-width:1px;" border="0" cellspacing="3" ><TR bgcolor=#AAAAAA><TD><CENTER><B>Wireless Switch</B></CENTER></TD></TR>';
    print "<TR><TD><PRE>@header</PRE></TD></TR></TABLE></BR>\n";

    # Tabla de Aps
    print '<TABLE class="sortable"; style="text-align: center; border-style:solid; border-width:1px;" border="0" cellspacing="3"><TR bgcolor=#AAAAAA><TD>Ap</TD><TD>ApName</TD><TD>Flags</TD><TD>IP</TD><TD>Model</TD><TD>Radio1</TD><TD>Radio2</TD><TD>Uptime</TD></TR>';
    foreach (@_) {
        next if not $_ =~ /^\s{0,3}\d{1,4}/;
        my $Ap      = substr($_, 0,  4);
        my $ApName  = substr($_, 5,  16);
        my $Flags   = substr($_, 22, 4);
        my $IP      = substr($_, 27, 15);
        my $Model   = substr($_, 43, 12);
        my $Radio1  = substr($_, 56, 7);
        my $Radio2  = substr($_, 64, 7);
        my $Uptime  = substr($_, 72, 6);

        if ( $Model =~ /^<unknown>   $/ ) { # Sin Modelo (Gris)
            print "<TR bgcolor=#DDDDDD>\n";
        } elsif ( $Uptime =~ /^\s+$/ ) {    # Sin Uptime (Rojo)
            print "<TR bgcolor=#D9B38C>\n";
        } elsif ( $Uptime =~ /m$/ ) {       # Uptime menor de un dia (Verde oscuro)
            print "<TR bgcolor=#D1D175>\n";
        } else {
            print "<TR bgcolor=#B3D98C>\n"; # El resto (verde)
        }
        print "\t<TD>$Ap</TD><TD>$ApName</TD><TD>$Flags</TD><TD>$IP</TD><TD>$Model</TD><TD>$Radio1</TD><TD>$Radio2</TD><TD>$Uptime</TD>";
        print "</TR>\n";
    }
    print "</TABLE>\n";
}

$0 =~ s/.*\///g;
&highlander;
&header;
&filltables(&getarray);
&footer;
