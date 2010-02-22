#!/usr/bin/perl -w

use strict;

use SNMP;
use Data::Dumper;
#&SNMP::initMib();
#&SNMP::addMibFiles(    "mibs/RMON2.MIB",
#                   "mibs/RFC1493.MIB",
#                   "mibs/draft2674ext.mib"
#                   );
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

my %oids =(
    vmMembershipEntry       =>  '.1.3.6.1.4.1.9.9.68.1.2.2.1.2',    #CISCO
    vtpVlanName             =>  '.1.3.6.1.4.1.9.9.46.1.3.1.1.4.1',  #CISCO
    dot1dBasePortIfIndex    =>  '.1.3.6.1.2.1.17.1.4.1.2',          #ENT
    dot1qVlanStaticName     =>  '.1.3.6.1.2.1.17.7.1.4.3.1.1',      #ENT
    dot1qPvid               =>  '.1.3.6.1.2.1.17.7.1.4.5.1.1',      #ENT
    ifIndex                 =>  '.1.3.6.1.2.1.2.2.1.1.1',
    ifName                  =>  '.1.3.6.1.2.1.31.1.1.1.1',
    ifAlias                 =>  '.1.3.6.1.2.1.31.1.1.1.18',
    ifDescr                 =>  '.1.3.6.1.2.1.2.2.1.2',
    ifSpeed                 =>  '.1.3.6.1.2.1.2.2.1.5',
    ifAdminStatus           =>  '.1.3.6.1.2.1.2.2.1.7',
    ifOperStatus            =>  '.1.3.6.1.2.1.2.2.1.8',
    ifInOctets              =>  '.1.3.6.1.2.1.2.2.1.10',
    ifOutOctets             =>  '.1.3.6.1.2.1.2.2.1.16',
);

&backupSNMP qw/192.168.246.26 public/;

sub backupSNMP {
    my ($switch, $community) = @_;
    $community = "public" unless $community;

    my $session = new SNMP::Session(DestHost    => $switch,
                                    Community   => $community,
                                    Version     => 1
                                    );
    die unless $session;
    my $vars = new SNMP::VarList(   [$oids{'ifIndex'}       , 0, ''],
                                    [$oids{'ifName'}        , 0, ''],
                                    [$oids{'ifAlias'}       , 0, ''],
                                    [$oids{'ifDescr'}       , 0, ''],
                                    [$oids{'ifSpeed'}       , 0, ''],
                                    [$oids{'ifAdminStatus'} , 0, ''],
                                    [$oids{'ifOperStatus'}  , 0, ''],
                                    [$oids{'ifInOctets'}    , 0, ''],
                                    [$oids{'ifOutOctets'}   , 0, ''],
#                                   [$oids{'dot1dBasePortIfIndex'}  , 0, ''],
#                                   [$oids{'dot1qVlanStaticName'}   , 0, ''],
#                                   [$oids{'dot1qPvid'} , 0, '']
                                    );
    my %iftab;
    while (my @if = $session->getnext($vars)) {
        last if $vars->[0]->tag ne "ifIndex";

        my ($index, $name, $alias,
            $descr, $speed, $admin,
            $oper, $in, $out, $vlanport) = @if;

        $iftab{$index} = {
            index   => $index,
            name    => $name,
            alias   => $alias,
            descr   => $descr,
            speed   => $speed,
            admin   => $admin,
            oper    => $oper,
            in      => $in,
            out     => $out,
            vlanportt       => $vlanport
        };
    }
    print Dumper %iftab;
}

# vim: set filetype=perl fdm=marker tabstop=4 shiftwidth=4 nu:
