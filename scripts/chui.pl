#!/usr/bin/perl -w

use strict;

use SNMP;
use Data::Dumper;
&SNMP::initMib();
&SNMP::addMibFiles(	"mibs/RMON2.MIB",
					"mibs/RFC1493.MIB",
					"mibs/draft2674ext.mib"
					);
use Getopt::Long qw(:config bundling);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

&backupSNMP qw/192.168.246.26 uocpublic/;

sub backupSNMP {
	my ($switch, $community) = @_;
	$community = "public" unless $community;

	my $session = new SNMP::Session(DestHost	=> $switch,
	                                Community	=> $community,
	                                Version		=> 1
									);
	die unless $session;
	my $vars = new SNMP::VarList(	['ifIndex'	, 0, ''],
									['ifName'	, 0, ''],
									['ifAlias'	, 0, ''],
									['ifDescr'	, 0, ''],
									['ifSpeed'	, 0, ''],
									['ifAdminStatus', 0,''],
									['ifOperStatus'	, 0,''],
									['ifInOctets'	, 0,''],
									['ifOutOctets'	, 0,'']
									);
	my %iftab;
	while (my @if = $session->getnext($vars)) {
		last if $vars->[0]->tag ne "ifIndex";

		my ($index, $name, $alias,
			$descr, $speed, $admin, 
			$oper, $in, $out) = @if;

		$iftab{$index} = {
			index	=> $index,
			name	=> $name,
			alias	=> $alias,
			descr	=> $descr,
			speed	=> $speed,
			admin	=> $admin,
			oper	=> $oper,
			in		=> $in,
			out		=> $out
		};
	}
	print Dumper %iftab;
}

# vim: set filetype=perl fdm=marker tabstop=4 shiftwidth=4 nu:
