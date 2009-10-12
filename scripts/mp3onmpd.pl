#!/usr/bin/perl
# Muestra info/tags de un mp3 local o de goear y busca ficheros de misma duración en la DB de mpd.

use strict;
use Getopt::Long qw(:config bundling);
use LWP::Simple;
use MP3::Info;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;


my $song;
my $first;
my $xmlurl;
my $mp3url;
my $mp3name;
my $urlregex = '^(?:|.*goear\.com\/listen\/)([\da-z]{7})\/.*$';

my %options = ();
GetOptions ( \%options
            ,'help|h|?'
            ,'info|i'
            ,'find|f'
            ,'strip|s'
            ,'cut|c'
) or die &help;

#keys %options or die "No se ha especificado ninguna opción.";

&help if $options{'help'}; # Puede ser mostrada sin argumentos.

foreach my $command (@ARGV) {
    if ($command =~ /$urlregex/) {
        $song = $1;
        &download;
    } elsif (-f $command) {
        $mp3name = $command;
    } else {
        print "$command no es un comando válido!\n";
        next;
    }
    &info   if $options{'info'};
    &strip  if $options{'strip'};
    &cut    if $options{'cut'};
    &find   if $options{'find'};
}

exit 0;

sub vars () {
print <<EOF;

#
SONG -> $song
FIRST -> $first
XMLURL -> $xmlurl
MP3URL -> $mp3url
MP3NAME -> $mp3name
#
EOF
}

sub download() {
    $first = $& if $song =~ /^[\da-z]/;
    $xmlurl = "http://www.goear.com/files/xmlfiles/${first}/secm${song}.xml";
    if ( get ($xmlurl) =~ /<song path="([\w\/:\.]+)"/ ) {
        $mp3url = $1;
    } else {
        die BOLD RED "Error al acceder o parsear $xmlurl\n";
    }
    $mp3name = $1 if $mp3url =~ /\/([\da-z]+.mp3)$/;

    &vars;

    if ( ! -f "$mp3name") {
        print "No existe $mp3name en local, descargando... ";
        $| = 1; #Fuera autoflush
        my $exit = getstore( $mp3url, $mp3name );
        if ( defined $exit and $exit =="200" ) {
            my $size = -s "$mp3name";
            print BOLD GREEN "$exit, OK ($size bytes)\n";
        } else {
            die BOLD RED "$exit, Error al descargar $mp3url\n";
        }
        $| = 0;
    } else {
        print BOLD CYAN "Ya existe $mp3name, paso de bajarlo\n";
    }
}

sub info() {
    my $info = get_mp3tag($mp3name);
    print BOLD YELLOW "#\n#\tTAGINFO v1+v2 de $mp3name\n#\t\n";
    foreach my $key (keys %$info) {
        print "$key -> $$info{$key}\n";
    }
    my $info = get_mp3tag($mp3name, 2, 2);
    print BOLD YELLOW "#\n#\tTAGINFO v2 RAW de $mp3name\n#\t\n";
    foreach my $key (keys %$info) {
        print "$key -> $$info{$key}\n";
    }
    my $info = get_mp3info($mp3name);
    print BOLD YELLOW "#\n#\tMP3INFO de $mp3name\n#\t\n";
    foreach my $key (keys %$info) {
        print "$key -> $$info{$key}\n";
    }
}

sub strip() {
    print BOLD YELLOW "#\n#\tBorrando Tags de $mp3name\n#\t\n";
    my $info = remove_mp3tag($mp3name, 'ALL');
    if ($info > 0) {
        print BOLD GREEN "OK!\n";
    } else {
        print BOLD RED "Error al borrar tags!: '$info'\n";
    }
}

sub cut() {
    print BOLD YELLOW "#\n#\tRecortando $mp3name\n#\t\n";
    local *FILE;
    open FILE, "+< $mp3name\0" or die BOLD RED "Can't open '$mp3name': $!";
    binmode FILE;
    read FILE, my $header, 3;
    if ($mp3name !~ /\.mp3$/i) {
        close FILE;
        print BOLD RED "$mp3name no parece un mp3, la cabezera es '($header'.\nAbortando...\n";
        return $header;
    }
    seek FILE, -128000, 2;
    my $tell = tell FILE;
    truncate FILE, $tell or return "Can't truncate '$mp3name': $!";
    close FILE or return "Problem closing '$mp3name': $!";
    print BOLD GREEN "OK!\n";
    exit 0;
}


sub find() {
    print BOLD YELLOW "#\n#\tBuscando canciones de misma duración que $mp3name en la DB de MPD:\n#\t\n";
    my $info = get_mp3info($mp3name);
    my $time = sprintf("%.f", $info->{SECS});
    local(*DB, $/);
    open (DB, "/var/lib/mpd/mpd.db") or die BOLD RED "No puedo abir mpd.db";
    my $slurp = <DB>;
    while ($slurp =~ /file: ([^\n]*game[^\n]*)\nTime: $time\n/isg) {
        print "$1\n";
    }
}

sub help() {
    $0 =~ s/.*\///g;
    my $time = scalar localtime();
    print <<EOF;
$0, $time
\tLa sintaxis es '$0 <opciones> <archivos>'
<Opciones>
\t-info\t-i\tMuestra Tags e info del fichero.
\t-strip\t-s\tQuita todos los tags ID3 del fichero
\t-cut\t-c\tRecorta el fichero.
\t-find\t-f\tBusca ficheros con la misma duración en la DB de MPD.
<archivos>
\tPueden ser ficheros mp3 y/o urls o Ids de goear.
EOF
}
