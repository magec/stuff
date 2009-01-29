#!/usr/bin/perl
# http://search.cpan.org/src/HARDAKER/SNMP-5.0401/t/bulkwalk.t

use strict;
use SNMP;
use Data::Dumper; #Para depurar
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

my %oids =(
	vmMembershipEntry		=>	'.1.3.6.1.4.1.9.9.68.1.2.2.1.2',	#CISCO
	vtpVlanName				=>	'.1.3.6.1.4.1.9.9.46.1.3.1.1.4.1',	#CISCO
	dot1dBasePortIfIndex 	=>	'.1.3.6.1.2.1.17.1.4.1.2', 			#ENT
	dot1qVlanStaticName		=>	'.1.3.6.1.2.1.17.7.1.4.3.1.1',		#ENT
	dot1qPvid				=>	'.1.3.6.1.2.1.17.7.1.4.5.1.1',		#ENT
	ifName					=> 	'.1.3.6.1.2.1.31.1.1.1.1',
	ifAlias					=>	'.1.3.6.1.2.1.31.1.1.1.18',
	ifEntryDescr			=>	'.1.3.6.1.2.1.2.2.1.2',
	ifEntrySpeed			=>	'.1.3.6.1.2.1.2.2.1.5',
	ifEntryStatus			=>	'.1.3.6.1.2.1.2.2.1.8',
	ifEntryInOctets			=>	'.1.3.6.1.2.1.2.2.1.10',
	ifEntryOutOctets		=>	'.1.3.6.1.2.1.2.2.1.16',
);

sub GetSnmp() {
	my ($machine, $community, @oids) = @_;

	$machine   = 'localhost' unless $machine;
	$community = 'public'    unless $community;

	my $session = new SNMP::Session(
		DestHost	=> $machine,
		Community	=> $community,
		Version		=> 2,
		RemotePort	=> 161,
		UseNumeric	=> 1, 	
	);

	my @VarBinds =();
	foreach (@oids) {
		push @VarBinds, new SNMP::Varbind([$_]);
	}
	
	my $VarList = new SNMP::VarList( @VarBinds );
	my @result = $session->bulkwalk( 0, 75, $VarList );

	if ( $session->{ErrorNum} ) {
		die "Error ".$session->{ErrorNum}." \"".$session->{ErrorStr}."\n en ".$session->{ErrorInd}."\n";
	}
	print "$result[0][1][0]\n";
	print "$result[0][1][1]\n";
	print "$result[0][1][2]\n";
	print "$result[0][1][3]\n";
	exit 0;
	return @result;
}

my @out = &GetSnmp ( $ARGV[0], qw( uocpublic .1.3.6.1.2.1.17.7.1.4.3.1.1 .1.3.6.1.2.1.17.7.1.4.5.1.1 ifAlias ifName .1.3.6.1.2.1.17.1.4.1.2 ) );

sub slice() {
	my %TmpArray=();
	for my $x (@out[@_[0]]){
		for my $y (@$x){
			$TmpArray{@$y[1]} = @$y[2];
		}
	}
	return %TmpArray;	
}

my %VlanNames = &slice(0);
my %PortVlans = &slice(1);
my %IfAlias = &slice(2);
my %IfNames = &slice(3);
my %BpIndex = reverse &slice(4);
	
foreach my $key (keys %IfNames) {
	print "$key -> $IfNames{$key} -> $PortVlans{$BpIndex{$key}} -> $VlanNames{$PortVlans{$BpIndex{$key}}} -> $IfAlias{$key}\n";
}








# vim: set filetype=perl fdm=marker tabstop=4 shiftwidth=4 nu:
