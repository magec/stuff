#!/usr/bin/perl -w
use strict;
use SNMP;
use Getopt::Long;
use Net::Telnet;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

$0 =~ s/.*\///g;
my @cmds = ();

GetOptions ('command=s' => \@cmds);

unless (@ARGV) {
    print <<EOF;
Usage: $0 <host/s> --command <Command to send>
Args:
\t--command, -c\tOptional, can be repeated. Commands to send, use quotes for space-separated arguments.
\t\t\tIf no commands specified, it will use "show config".
Example: $0 management.uoc.es -c "show version" -c "show interface status" -c "show interface trunk"
EOF
exit 1;
}

@cmds = ("show config") unless @cmds;

my %chuis =();
$chuis{'.1.3.6.1.4.1.9.1.359'}      = {name => 'WS-C2950T-24',     user => 'XXXX', pass => 'XXXX', runcmd => 'terminal length 0', enable => 'XXXX'};
$chuis{'.1.3.6.1.4.1.9.1.559'}      = {name => 'WS-C2950T-48-SI',  user => 'XXXX', pass => 'XXXX', runcmd => 'terminal length 0', enable => 'XXXX'};
$chuis{'.1.3.6.1.4.1.9.1.716'}      = {name => 'WS-C2960-24TT-L',  user => 'XXXX', pass => 'XXXX', runcmd => 'terminal length 0', enable => 'XXXX'};
$chuis{'.1.3.6.1.4.1.9.1.717'}      = {name => 'WS-C2960-48TT-L',  user => 'XXXX', pass => 'XXXX', runcmd => 'terminal length 0', enable => 'XXXX'};
$chuis{'.1.3.6.1.4.1.9.1.696'}      = {name => 'WS-C2960G-24TC-L', user => 'XXXX', pass => 'XXXX', runcmd => 'terminal length 0', enable => 'XXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.2.220'} = {name => 'C2H124-48',        user => 'XXXX',    pass => 'XXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.1.100'} = {name => 'B3G124-24',        user => 'XXXX',    pass => 'XXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.1.53'}  = {name => '7H4382-25',        user => 'XXXX',    pass => 'XXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.1.59'}  = {name => '1H582-25',         user => 'XXXX',    pass => 'XXXX',  runcmd => 'set terminal rows disable'};
$chuis{'.1.3.6.1.4.1.5624.2.1.34'}  = {name => '1H582-51',         user => 'XXXX',    pass => 'XXXX',  runcmd => 'set terminal rows disable'};

sub getSNMP() {
    my $machine   = shift || 'localhost';
    my $community = shift || 'public';
    my $oid       = shift || '.1.3.6.1.2.1.1.2.0';

    my $session = new SNMP::Session(
        DestHost    => $machine,
        Community   => $community,
        Version     => 2,
        UseNumeric  => 1
    );

    if ($session) {
        if ($session->get($oid)) {
            return $session->get($oid);
        } else {
            print BOLD RED "#\tNo SNMP 'get' response from '$machine'\n";
            return 0;
        }
    } else {
        print BOLD RED "#\tNo SNMP session from '$machine'\n";
        return 0;
    }

}

foreach my $host (@ARGV) {
    print BOLD WHITE "#\n#\tTrying $host...\n#\n";
    my $sysObjectID = &getSNMP($host,'XXXX','.1.3.6.1.2.1.1.2.0') || next;
    if ($chuis{$sysObjectID}{name}) {
        print GREEN "#\tHardware: $chuis{$sysObjectID}{name} ($sysObjectID)\n";
    } else {
        print BOLD RED "#\t$sysObjectID no está en el hash:\n";
        foreach my $key (sort keys %chuis) {
            next unless $chuis{$key}{name};
            print GREEN "#\t$chuis{$key}{name}";
            print BOLD GREEN " $key\n";
        }
        next;
    }
    my $user   = $chuis{$sysObjectID}{user};
    my $pass   = $chuis{$sysObjectID}{pass};
    my $runcmd = $chuis{$sysObjectID}{runcmd} || 0;
    my $enable = $chuis{$sysObjectID}{enable} || 0;

    my $telnet = new Net::Telnet ( Timeout  => 5
                                 , Errmode  => 'return'
                                 , Prompt   => '/.*?[>#%\$]$/i'
                                 );
    $telnet->open($host);
    $telnet->login($user, $pass);
    my $prompt = $telnet->last_prompt;
    $prompt =~ /[\w@()]+/g;
    print  GREEN "#\tStrip Prompt -> '$&'\n";
    if ( $enable ) {
        print GREEN "#\tSending enablepass...";
        $telnet->print('enable');
        $telnet->waitfor('/password/i');
        $telnet->cmd($enable);
        if ($telnet->lastline =~ /denied/i) {
            print BOLD RED " NOK\n";
            print BOLD RED "#\tSkipping Host $host\n";
            next;
        } else {
            print BOLD GREEN " OK\n";
        }
    }
    $telnet->cmd($runcmd) if $runcmd;
    foreach (@cmds) {
        s/[\n\t\f]+/ /g;
        print CYAN "#\tExecuting '$_' en $host\n\n";
        print "${prompt}$_\n";
        print $telnet->cmd("$_");
        print CYAN "#\tEOF '$_' en $host.\n"
    }
}
