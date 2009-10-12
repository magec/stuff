#!/usr/bin/perl
# This will search for flac files on directories then will try to copy/tag them in the current directory via direct http queries to vgmdb.net, (or not).
#my $content ="action=advancedsearch&albumtitles=Valkyrie+Profile+Covenant+of+the+Plume+Arrange+Album&catalognum=&composer=&arranger=&performer=&lyricist=&publisher=&game=&trackname=&notes=&anyfield=&releasedatemodifier=is&day=0&month=0&year=0&discsmodifier=is&discs=&albumadded=&albumlastedit=&scanupload=&tracklistadded=&tracklistlastedit=&sortby=albumtitle&orderby=ASC&childmodifier=0&dosearch=Search+Albums+Now";

use strict;
use utf8;
use Encode;
use Audio::FLAC::Header;    # Para sub hashfiles(@)
use LWP::UserAgent;         # Para sub http($$$)
use HTML::Entities;         # Para decode_entities
use File::Copy;             # para copy en &rename
use Data::Dumper;
use Getopt::Long qw(:config bundling);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

$0 =~ s/.*\///g;

unless (@ARGV) {
    print <<EOF;
Usage: $0 <DIR1> <DIR2> ...
$0 will (or not):
1) Search on every DIR for flac files.
2) Launch a query to vcgmdb.net based on DIR's name.
3) Crawl through all results looking for the matching disc based on the length of each track.
4) If a match is found, it will copy and itag the files in the current directory
5) The schema is: ALBUM [CATALOG NUMBER]/TRACK_NUMBER - TITLE.flac

$0 Requires Audio::FLAC::Header and LWP::UserAgent.
EOF
exit 1;
}

my %cd=();
my %vgm=();
my @catnums=();

# This will search for flac files on directories then will try to copy/tag them in the current directory via direct http queries to vgmdb.net, (or not).
foreach my $dir (@ARGV) {
    if (-d $dir) {
        my @files=();
        opendir(DIR, $dir) || print RED "can't opendir $dir: $!\n";
        @files=map {"$dir/$_"} grep { !/^\.+$/ && /^*.flac$/i } readdir(DIR);
        closedir DIR;
        &hashfiles(@files) or next if @files;
        $dir =~ /([^\/]+)$/;
        my $ids = &vgmdbsearch($1);
        unless (keys(%$ids)) {
            print "No results for $dir, skipping...\n";
        }
        foreach (sort keys %$ids) {
            %vgm=();
            print BLUE BOLD"Trying ($_) - $ids->{$_}\n";
            &vgmdbid($_);
            my $vgmcd = &compare;
            if ($vgmcd) {
                &rename($vgmcd,$dir);
                last;
            }
        }
        %cd=();
        %vgm=();
    }
}

sub http($$$) {
    my $url     = shift || return 0;
    my $method  = shift || "GET";
    my $content = shift || 0;
    my $referer = shift || '127.0.0.1';

    my $ua = LWP::UserAgent->new;   # User Agent creation
    $ua->agent('Mozilla/5.0');      # IMMAFAKE
    my $req = HTTP::Request->new($method => $url); # Create a request
    $req->content_type('application/x-www-form-urlencoded');
    $req->referer($referer);
    $req->content($content);
    my $res = $ua->request($req);   # Pass request to the User Agent and get a response back
    unless ($res->is_success) {     # Check the outcome of the response
        return $res->status_line;
    } else {
        return $res->decoded_content;
    }
}

sub hashfiles(@) {
    my $curalbum = "NULL";
    my $count=1;
    foreach (sort {$a cmp $b} @_) {
        my $flac = Audio::FLAC::Header->new($_);
        my $info = $flac->info();
        my $tags = $flac->tags();
        $curalbum = $tags->{ALBUM};
        my $secsre = $info->{TOTALSAMPLES} / $info->{SAMPLERATE};
        $secsre =~ s/\.\d+$//g;
        my $secs = sprintf ("%.2d:%.2d:%.2d", $secsre/3600%24, $secsre/60%60, $secsre%60);
        my $tnumber = $tags->{TRACKNUMBER};
        $tnumber = $count unless $tnumber =~ /^\d\d$/;
        $tnumber = sprintf ("%02d", $tnumber) if length($tnumber) == 1;
        $count++;
        $cd{$tnumber} = {  TITLE  => $tags->{TITLE}
                        ,  ALBUM  => $tags->{ALBUM}
                        ,  GENRE  => $tags->{GENRE}
                        ,  ARTIST => $tags->{ARTIST}
                        ,  DATE   => $tags->{DATE}
                        ,  TIME   => $secs
                        ,  TIMES  => $secsre
                        ,  FNAME  => $_
                        };
    }
    print RED BOLD "Album: '$curalbum' with ".keys(%cd)." tracks.\n";
    print GREEN "TRK TITLE                             TIME     YEAR GENRE                 ARTIST\n";
    print GREEN "================================================================================\n";
    foreach (sort {$a <=> $b} keys %cd ){
        next unless ref($cd{$_}) eq "HASH";
#
format FLAC_HEADER =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @<<< @|||||||||| @>>>>>>>>>>>>>>>
$_, $cd{$_}{TITLE}, $cd{$_}{TIME}, $cd{$_}{DATE}, $cd{$_}{GENRE}, $cd{$_}{ARTIST}
.
#
            $~ = 'FLAC_HEADER';
            write();
    } # foreach %cd
    print "#\n";
} # sub hashfiles

sub vgmdbsearch($) {
    my $album = shift;
    print GREEN BOLD "Directory name: '$album'\n";
    $album =~ s/^.*?\s-\s\d{4}\s-\s//g;
    $album =~ s/\sdis[kc]|ost//gi;
    $album =~ s/[\[\{\(].*?[\)\}\]]//gi;
    $album =~ s/\W/+/g;
    $album =~ s/\++/+/g;
    $album =~ s/\+*$//g;
#    $album = "Valkyrie+profile";
    print GREEN BOLD "Parsed name: '$album'\n";
    my $page = decode_entities(&http('http://vgmdb.net/search?do=results', 'POST', "action=advancedsearch&albumtitles=$album&sortby=release&orderby=ASC",'http://vgmdb.net/search'));
    $page = encode('utf-8', $page); # A lo bestia.
    my %results=();
    print "CATALOG NUM\tID\tYEAR\tNAME\n================================================================================\n";
    while ($page =~ /<tr>.*?<span class=.catalog.>(.*?)<.span>.*?<a href=....album.(\d+).><span style=.color: #(\w+).><span class=.albumtitle. lang=.en. style=.display:inline.>(.*?)<.span>.*?year=(\d+)/sg ) {
        print "$1\t$2\t$5\t$4\t$3\n";
        $results{$2} = $4;
    }
    return \%results;
}

sub vgmdbid($) {
    return 0 unless $_ =~ /^\d+$/;
    $vgm{URL}="http://vgmdb.net/album/$_";
    my $page = decode_entities(&http($vgm{URL}));
    $page = encode('utf-8', $page); # A lo bestia.

    if ($page =~ /<span class="albumtitle" lang="en" style="display:inline">(.*?)<\/span>/) {
        print BOLD GREEN "=" x length($1)."\n";
        print BOLD GREEN "$1\n";
        print BOLD GREEN "=" x length($1)."\n";
        $vgm{ALBUM}=$1;
    }

    while ($page =~ /<div id="rightfloat"(.*?)<\/div><\/div>/sg){
        my $asd = $1;
        $asd =~ s/<script.*?\/script>//g;   # Noscript
        $asd =~ s/<[^>]*>//g;   # Fuera tags html.
        $asd =~ s/[\n\r]//g;    # Oneline pls
        if (my @matches = $asd =~ /(Catalog Number)(.*?)(?:|(Other Printings)(.*?))(Release Date)(.*?)(Release Type)(.*?)(Release Price)(.*?)(Media Format)(.*?)(Classification)(.*?)(Published by)(.*?)(Composed by)(.*?)(Arranged by)(.*?)(Performed by)(.*?)$/smg) {
            while (@matches) {
                if ($matches[0] and $matches[1]) {
                    print BLUE BOLD "$matches[0]:\t";
                    $matches[1] =~ s/\s+$//g;
                    print "'$matches[1]'\n";
                    $vgm{$matches[0]}=$matches[1];
                }
                shift @matches; # uglyyyyyyyy
                shift @matches;
            }
        }
    }

    @catnums=();
    $vgm{TOTALDISCS} = 1;
    $vgm{TOTALDISCS} = $1 if $vgm{'Media Format'} =~ /^(\d+).*$/;

    print "$vgm{TOTALDISCS}\n";

    if ( $vgm{'Catalog Number'} =~ /(\w+\W)(\d+)~(\d+)$/) {
        my $pref = $1;
        my $last = substr($2, 0, -length($3))."$3";
        foreach ($2..$last) {
            push (@catnums, "$pref$_");
        }
    } else {
        foreach (1..$vgm{TOTALDISCS}) {
            push (@catnums, "$vgm{'Catalog Number'} Disc ".sprintf ("%02d", $_));
        }
    }

    my @result = split('\n', $page);
    my ($disc,$track,$name,$time,$secs)=();
    foreach (@result) {
        if ($_ =~ /<b>Disc\s(\d+)/) {
            $disc="$1";
            print RED BOLD "Disc $disc, Cat Number: $catnums[$disc-1]\n";
            print GREEN " TRK TITLE                                                          TIME    SECS\n";
            print GREEN "=================================================================================\n";
        }

        $track = $1 if $_ =~ /class="smallfont"><span class="label">(\d+)<\/span><\/td>.$/;
        $name  = decode_entities($1) if $_ =~ /class="smallfont" width="100%">(.*?)<\/td>.$/;
        if ( $_ =~ /class="time">([\d:]+)<\/span><\/td>.$/ ) {
            my $time = $1;
            if ($time =~ /(\d+):(\d+)/) {
                $secs = ($1*60)+$2;
            }
#
format VGMDB_HEADER =
 @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @<<<
$track, $name, $time, $secs
.
#
            $~ = 'VGMDB_HEADER';
            write();
            $vgm{"CD$disc"}{$track} = {  TITLE => $name, time => $time, TIME => $secs };
            ($track,$name)=(0,0);
        }

        if ( $_ =~ /class="time">([\d:]+)<\/span><\/span>/) {
            print YELLOW BOLD "Disc Length = $1\n";
            $vgm{'Media Format'} =~ /^(\d+).*$/;
            last if $disc == $1;
        }
    } #foreach @result
} # sub vgmdbtitle

sub compare() {
    foreach my $vgmcd (sort keys %vgm) {
        next unless ref($vgm{$vgmcd}) eq "HASH"; # Only the CDX hashes
        my $mark=0;
        my %current = %{$vgm{$vgmcd}};
        print "$vgmcd has ".keys(%current)." tracks and I got ".keys(%cd)." files...\t";
        if (keys(%current) ne keys(%cd)) {
            print RED BOLD "SKIPPING\n";
            next;
        } else {
            print GREEN BOLD "OK!\n";
            print "  This CD -> Our Files:\n=========================\n";
            foreach (sort keys %current) {
                printf ("(%02d) % 4d -> (%02d) % 4d ", $_, $current{$_}{TIME}, $_, $cd{$_}{TIMES});
                my $subs = $current{$_}{TIME} - $cd{$_}{TIMES};
                if ($subs == 0) {
                    print GREEN BOLD "(0 secs) OK!\n";
                    $cd{$_}{NTITLE} = $current{$_}{TITLE};
                } elsif ($subs > 0 and $subs < 4) {
                    print YELLOW BOLD "($subs secs) OK!\n";
                    $cd{$_}{NTITLE} = $current{$_}{TITLE};
                } elsif ($subs < 0 and $subs > -4) {
                    print YELLOW BOLD "($subs secs) OK!\n";
                    $cd{$_}{NTITLE} = $current{$_}{TITLE};
                } else {
                    print RED BOLD "($subs secs) NOK!\n";
                    $mark=1;
                }
            }
            $vgmcd =~ /\d+$/;
            if ($mark) {;
                print RED "$vgmcd\n";
            } else {
                $vgmcd =~ s/\D//g;
                return $catnums[$vgmcd-1] unless $mark;
            }
        }
    } # foreach keys %vgm
    return 0;
} # compare

sub rename($) {
    my $vgmcd = shift;
    my $cdnum = 1;
    foreach (@catnums) {
        last if $_ eq $vgmcd;
        $cdnum++;
    }
    my $dir   = shift;
    my $newdir = "$vgm{ALBUM} [$vgmcd]";
    $newdir =~ s/[\:*?<>|]//g; # NTFS Valid file?
    print GREEN "Directory to Create: "; print "$newdir\n";
    foreach my $track (sort keys %cd) {
        print BOLD GREEN "We will rename: ================================================================\n";
        my $destfile = "$newdir/$track $cd{$track}{NTITLE}.flac";
        $destfile =~ s/[\:*?<>|]//g; # NTFS Valid file?
        my $bytes=-s $cd{$track}{FNAME};
        print BLUE "'$cd{$track}{FNAME}' ($bytes bytes)\n";
        print BOLD YELLOW "to "; print "'$destfile'\n";
        mkdir "$newdir" unless -d $newdir;
        if ( -B $destfile ) {
            print RED "Ya existe '$destfile', Omitiendo\n";
            next;
        } else {
            copy ($cd{$track}{FNAME}, $destfile) or die $!;
            $bytes=-s $destfile;
            print GREEN "$destfile copiado correctamente ($bytes bytes).\n";
        }

        if (-B $destfile) {
            print GREEN "Se procede a taggear '$cd{$track}{NTITLE}.flac':\n";
            my $flac = Audio::FLAC::Header->new($destfile);
            my $tags = $flac->tags();
            %{$tags} = ();
            my $result = $flac->write();
            unless ($result) {
                print RED "No se pudieron limpar los tags de $cd{$track}{NTITLE}.flac\n";
                next;
            }
            my $genre  = $vgm{'Classification'} || 'VGM';
            my $date   = $vgm{'Release Date'}   || 'XXXX';
            #$date = $& if $date =~ /\d+$/; # Only year MAN
            my $version = "Type:$vgm{'Release Type'}, Media:$vgm{'Media Format'}, Price:$vgm{'Release Price'}";
            my $description = "Catalog:$vgm{'Catalog Number'} URL:$vgm{URL}";
            my $aartist = $vgm{'Arranged by'};
            $aartist = $vgm{'Composed by'} unless $aartist;
            $aartist =~ s/,.*$//g;
            $vgm{'Arranged by'} = $aartist unless $vgm{'Arranged by'};
            $aartist =~ s/\s\/.*//g;
            $tags->{TRACKNUMBER}    = $track               ; print " |-- TRACKNUMBER\t= '$track'\n";
            $tags->{TOTALTRACKS}    = keys(%cd)            ; print " |-- TOTALTRACKS\t= '".keys(%cd)."'\n";
            $tags->{ALBUM}          = $newdir              ; print " |-- ALBUM\t\t= '$newdir'\n";
            $tags->{TITLE}          = $cd{$track}{'NTITLE'}; print " |-- TITLE\t\t= '$cd{$track}{'NTITLE'}'\n";
            $tags->{GENRE}          = $genre               ; print " |-- GENRE\t\t= '$genre'\n";
            $tags->{DATE}           = $date                ; print " |-- DATE\t\t= '$date'\n";
            $tags->{'ALBUM ARTIST'} = $aartist             ; print " |-- ALBUM ARTIST\t= '$aartist'\n";
            $tags->{ARTIST}         = $vgm{'Arranged by'}  ; print " |-- ARTIST\t\t= '$vgm{'Arranged by'}'\n";
            $tags->{COMPOSER}       = $vgm{'Composed by'}  ; print " |-- COMPOSER\t\t= '$vgm{'Composed by'}'\n";
            $tags->{PERFORMER}      = $vgm{'Performed by'} ; print " |-- PERFORMER\t\t= '$vgm{'Performed by'}'\n";
            $tags->{TOTALDISCS}     = $vgm{TOTALDISCS}     ; print " |-- TOTALDISCS\t\t= '$vgm{TOTALDISCS}'\n";
            $tags->{DISCNUMBER}     = $cdnum               ; print " |-- DISCNUMBER\t\t= '$cdnum'\n";
            $tags->{COMMENT}        = $description         ; print " |-- COMMENT\t\t= '$description'\n";
            $tags->{VERSION}        = $version             ; print " |-- VERSION\t\t= '$version'\n";
            $tags->{COPYRIGHT}      = $vgm{'Published by'} ; print " `-- COPYRIGHT\t\t= '$vgm{'Published by'}'\n";
            $result = $flac->write();
            if ($result) {
                print GREEN "Los tags se aplicaron en '$cd{$track}{NTITLE}.flac' correctamente!\n";
            } else {
                print RED "No se pudo tagear $cd{$track}{NTITLE}.flac debidamente.\n";
            }
        } else {
            print RED "El fichero '$destfile' no existe o no es binario";
        }
    }
    print GREEN BOLD "OK!\n";
    return 1;
}
