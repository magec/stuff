#!/usr/bin/perl
#release:"Opus Magnum" AND artist:"Hollenthon" AND tracks:"9"
#http://musicbrainz.org/ws/1/release/?type=xml&artist=hollenthon&title=opus+magnum&count=9
#http://musicbrainz.org/ws/1/release/ac591bde-76b5-4bbc-ad7a-b7f19aeaac3c?type=xml&inc=artist+counts+release-events+discs+tracks+release-groups+artist-rels+label-rels+release-rels+track-rels+url-rels+track-level-rels+labels+tags+ratings+isrcs





use strict;
use warnings;
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
my @log=();
my $threshold = 3000;


sub dprint {
    my ($line) = @_;
    print $line;
    push(@log, $line);
#   print LOG $line;
}

foreach my $dir (@ARGV) {
    if (-d $dir) {
        @log=();
        my $vgmcd=0;
        my @files=();
        opendir(DIR, $dir) || dprint RED "can't opendir $dir: $!\n";
        @files=map {"$dir/$_"} grep { !/^\.+$/ && /^.*flac$/i } readdir(DIR);
        closedir DIR;
        &hashfiles(@files);
        my $tracknum = scalar @files;

        my ($dirname) = $dir =~ /([^\/]+)(?:|\/)$/;
    
        my ($artist,$year,$album) = $dirname =~ /^(?:^(.*?)(?: - (\d+)|) - |)(.*?)$/ ;
        next unless $album;
        $album =~ s/[\[\{\(].*/+/gi;
        $album =~ s/\smp3|flac|ape\s/+/gi;
        $album =~ s/\s/+/g;
        $artist = "" unless $artist;
        $year   = "" unless $year;

        print "'$dirname'\n";
        print "$artist\n";
        print "$year\n";
        print "$album\n";
        print "$tracknum\n";

        my $first_xml = decode_entities(&http("http://musicbrainz.org/ws/1/release/?type=xml&artist=$artist&title=$album&count=$tracknum", 'GET'));

        $first_xml = encode('utf-8', $first_xml); # A lo bestia.



        sleep 1;
        while ( $first_xml =~ /<release type="(.+?)" id="([\w-]+)" ext:score="100">/sg ) {
           print WHITE BOLD "Type: "; print BLUE "$1\n";
           print WHITE BOLD "ID: "; print BLUE "$2\n";
            #my $second_xml = decode_entities(&http("http://musicbrainz.org/ws/1/release/$2?type=xml&inc=artist+counts+release-events+discs+tracks+release-groups+artist-rels+label-rels+release-rels+track-rels+url-rels+track-level-rels+labels+tags+ratings+isrcs", 'GET'));
            my $second_xml = decode_entities(&http("http://musicbrainz.org/ws/1/release/$2?type=xml&inc=artist+release-events+tracks+url-rels", 'GET'));
    $second_xml = encode('utf-8', $second_xml); # A lo bestia.
#            print $second_xml;

print WHITE BOLD "";
            my ($aartist) = $second_xml =~ /<artist id="[\w-]+".+?<name>(.+?)<.name>/;
           print WHITE BOLD "Artist: "; print BLUE "$aartist\n";

           my $lastfmartist = $aartist;

           $lastfmartist =~ s/\s/+/g;

           print WHITE BOLD "LASTFMArtist: "; print BLUE "$lastfmartist\n";

            my $third_xml = decode_entities(&http("http://ws.audioscrobbler.com/1.0/artist/$lastfmartist/toptags.xml", 'GET'));
    $third_xml = encode('utf-8', $third_xml); # A lo bestia.

            my $count=0;
            while ($third_xml =~ /<tag>\s+<name>(.+?)<.name>\s+<count>(\d+)<.count>/sg) {
                last if ++$count == 11;
                my $genre=$1;
                my $rank=$2;
                $genre =~ s/([^\s]+)/\u\L$1/gi; # 1st Leter Uppercase Voodoo
                print "$rank -> $genre\n";
            }


           my ($title) = $second_xml =~ /<release id="[\w-]+".+?<title>(.+?)<.title>/;
           print WHITE BOLD "Title: "; print BLUE "$title\n";

            my ($asin) = $second_xml =~ /<asin>(.+?)<.asin>/;
            print WHITE BOLD "ASIN: "; print BLUE "$asin\n";

            my ($event) = $second_xml =~ /<event(.+?)>/;
            while ($second_xml =~ /<event(.+?)>/sg) {
                print "$1\n";

            }




next;
            my %events=();
            while ($event =~ /(\w+)="(.+?)"/sg) {
                $events{$1} = $2;
                print WHITE BOLD "$1: " ; print BLUE "$2\n";
            }

            my ($urls) = $second_xml =~ /<.track-list><relation-list target-type="Url">(.+?)<.relation-list><.release>/;
            if ($urls) {
                while ($urls =~ /<relation type="(\w+)" target="(.+?)" begin="" end="".>/sg) {
                    print WHITE BOLD "$1: "; print BLUE "$2\n";
                }
            }




            my $count=0;
            print GREEN "TRK TITLE                                        MBRAINZ <-> FILES  DIFFERENCE\n";
            print GREEN "=" x (80)."\n";
            while ( $second_xml =~ /<track id="[\w-]+"><title>(.*?)<.title><duration>(\d+)<.duration>.*?<.track>/sg ) {
                $count = sprintf ("%02d", ++$count);
            #    print YELLOW "$count  $2 vs $cd{$count}{TIMES}\t";
            printf ("%-3.3s %-44.44s %7.7s <-> %-7.7s", $count, $1,  $2,  $cd{$count}{TIMES});
                my $subs = $2 - $cd{$count}{TIMES};
                if ($subs == 0) {
                    print GREEN BOLD "(0 ms) OK!\n";
                    $cd{$count}{NTITLE} = $1;
                } elsif ($subs > 0 and $subs < $threshold) {
                    print YELLOW BOLD "($subs ms) OK!\n";
                    $cd{$count}{NTITLE} = $1;
                } elsif ($subs < 0 and $subs > -$threshold) {
                    print YELLOW BOLD "($subs ms) OK!\n";
                    $cd{$count}{NTITLE} = $1;
                } else {
                    print RED BOLD "($subs ms) NOK!\n";
                   # $mark=1;
                }



            }


        }

#    print Dumper %cd;

        next;





        exit 0;
        &hashfiles(@files);
        my ($dirname) = $dir =~ /([^\/]+)(?:|\/)$/;
        my $ids = &vgmdbsearch($dirname);
        unless (keys(%$ids)) {
            dprint RED BOLD "#\n#\tNo results on VGMDB for $dirname, skipping...\n#\n";
            open(LOG, ">> errors.txt") || die "Can't redirect stdout";
            print LOG "# No RESULTS on VGMDB for '$dirname'\n";
            close(LOG);
            next;
        }

        foreach (sort { $ids->{$a}{type} cmp $ids->{$b}{type} } keys %$ids) {
            %vgm=();
            dprint BLUE BOLD"\nTrying ($_) - $ids->{$_}{title}\n\n";
            &vgmdbid($_);
            $vgmcd = &compare;
            if ($vgmcd) {
                my $result = &rename($vgmcd,$dir);
                    if ($result) {
                    dprint GREEN BOLD "#\n#\tOK! '$dirname' was tagged as '$result'\n#\n";
                    last;
                };
            }
        }
        unless ($vgmcd) {
            dprint RED BOLD "#\n#\tNo match for '$dirname' :(\n#\n";
            open(LOG, ">> errors.txt") || die "Can't redirect stdout";
            print LOG "# No MATCH for '$dirname'\n";
            close(LOG);
        }
    } # if -d dir
} # foreach my dir

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
    $req->content($content) if $content;
    my $res = $ua->request($req);   # Pass request to the User Agent and get a response back
    unless ($res->is_success) {     # Check the outcome of the response
        return $res->status_line;
    } else {
        return $res->decoded_content;
    }
}

sub hashfiles(@) {
    %cd=();
    my $curalbum = "NULL";
    my $count=1;
    foreach (sort {$a cmp $b} @_) {
        my $flac = Audio::FLAC::Header->new($_);
        my $info = $flac->info();
        my $tags = $flac->tags();
        $curalbum = $tags->{ALBUM} || $tags->{album} || "";
        my $secsre = ($info->{TOTALSAMPLES} / $info->{SAMPLERATE})*1000;
        $secsre =~ s/\.\d+$//g;
        my $secs = sprintf ("%.2d:%.2d", $secsre/1000/60%60, $secsre/1000%60);
        my $tnumber = $tags->{TRACKNUMBER} || $tags->{tracknumber} || "";
        $tnumber = $count unless $tnumber =~ /^\d\d$/;
        $tnumber = sprintf ("%02d", $tnumber) if length($tnumber) == 1;
        $count++;
        $cd{$tnumber} = {  TITLE  => $tags->{TITLE}  || $tags->{title}  || ""
                        ,  ALBUM  => $tags->{ALBUM}  || $tags->{album}  || ""
                        ,  GENRE  => $tags->{GENRE}  || $tags->{genre}  || ""
                        ,  ARTIST => $tags->{ARTIST} || $tags->{artist} || ""
                        ,  DATE   => $tags->{DATE}   || $tags->{date}   || ""
                        ,  TIME   => $secs
                        ,  TIMES  => $secsre
                        ,  FNAME  => $_
                        };
    }

    dprint BLUE BOLD "=" x (23+length($curalbum)+length(keys(%cd)))."\n";
    dprint BLUE BOLD "Album: '$curalbum' with ".keys(%cd)." tracks.\n";
    dprint BLUE BOLD "=" x (23+length($curalbum)+length(keys(%cd)))."\n\n";
    dprint GREEN "TRK TITLE                                        TIME  YEAR GENRE       ARTIST\n";
    dprint GREEN "=" x (80)."\n";
    foreach (sort {$a <=> $b} keys %cd ){
        next unless ref($cd{$_}) eq "HASH";
            dprint sprintf ("%-3.3s %-44.44s %+5.5s %5.5s %-10.10s %-16s \n", $_, $cd{$_}{TITLE}, $cd{$_}{TIME}, $cd{$_}{DATE}, $cd{$_}{GENRE}, $cd{$_}{ARTIST});
    } # foreach %cd
     dprint GREEN "=" x (80)."\n";
} # sub hashfiles

sub vgmdbsearch($) {
    my $album = shift;
    dprint YELLOW "\nOur DirName: '$album'\n";
    $album =~ s/^.*?\s-\s\d{4}\s-\s/+/g;
    $album =~ s/\sdis[kc]|ost|cd\w/+/gi;
    $album =~ s/\soriginal.soundtrack(?:|s)/+/gi;
    $album =~ s/[\[\{\(].*?[\)\}\]]/+/gi;
    $album =~ s/\W/+/g;
    $album =~ s/\++/+/g;
    $album =~ s/\+*$//g;
#    $album = "Valkyrie+profile";
    dprint YELLOW "Parsed Name: '$album'\n\n";
    dprint BLUE BOLD "=" x (23+length($album))."\n";
    dprint BLUE BOLD "Querying VGMDB with: '$album'\n";
    dprint BLUE BOLD "=" x (23+length($album))."\n";
    my $page = decode_entities(&http('http://vgmdb.net/search?do=results', 'POST', "action=advancedsearch&albumtitles=$album&sortby=release&orderby=ASC",'http://vgmdb.net/search'));
    $page = encode('utf-8', $page); # A lo bestia.
    my %results=();
    dprint GREEN "\nCATALOG NUM\tID\tYEAR\tNAME\n";
    dprint GREEN "=" x (80)."\n";

    my %types = (  '#CEFFFF'=> 'Official Release'
                ,  yellow   => 'Enclosure / Promo'
                ,  orange   => 'Doujin / Fanmade'
                ,  '#00BFFF'=> 'Works'
                ,  silver   => 'Game Animation & Film'
                ,  violet   => 'Demo Scene'
                ,  tomato   => 'Bootleg'
                ,  white    => 'Other'
                ,  seagreen => 'Cancelled Release'
                );

    while ($page =~ /<tr>.*?<span class=.catalog.>(.*?)<.span>.*?<a href=....album.(\d+).><span style=.color: ([#\w]+).><span class=.albumtitle. lang=.en. style=.display:inline.>(.*?)<.span>.*?(\d{4})</sg ) {
        dprint "$1\t$2\t$5\t$4\t($types{$3})\n";
        $results{$2} = {title =>$4, type =>$3};
    }
    dprint GREEN "=" x (80)."\n";
    return \%results;
}

sub vgmdbid($) {
    return 0 unless $_ =~ /^\d+$/;
    %vgm=();
    $vgm{URL}="http://vgmdb.net/album/$_";
    my $page = decode_entities(&http($vgm{URL}));
    $page = encode('utf-8', $page); # A lo bestia.

    if ($page =~ /<span class="albumtitle" lang="en" style="display:inline">(.*?)<\/span>/) {
        dprint MAGENTA BOLD "=" x length($1)."\n";
        dprint MAGENTA BOLD "$1\n";
        dprint MAGENTA BOLD "=" x length($1)."\n\n";
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
                    dprint BLUE BOLD "$matches[0]:\t";
                    $matches[1] =~ s/\s+$//g;
                    dprint "'$matches[1]'\n";
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

    if ( $vgm{'Catalog Number'} =~ /(\w+\W)(\d+)~(\d+)$/) {
        my $pref = $1;
        my $last = substr($2, 0, -length($3))."$3";
        foreach ($2..$last) {
            push (@catnums, "$pref$_");
        }
    } else {
        if ($vgm{TOTALDISCS} == 1) {
            push (@catnums, $vgm{'Catalog Number'});
        } else {
            foreach (1..$vgm{TOTALDISCS}) {
                push (@catnums, "$vgm{'Catalog Number'} Disc ".sprintf ("%02d", $_));
            }
        }
    }

    my @result = split('\n', $page);
    my ($disc,$track,$name,$time,$secs)=();
    foreach (@result) {
        if ($_ =~ /<b>Disc\s(\d+)/) {
            $disc="$1";
            dprint MAGENTA BOLD "\n\tDisc $disc, Cat Number: $catnums[$disc-1]\n\n";
            dprint GREEN "TRK TITLE                                                          TIME    SECS\n";
            dprint GREEN "=" x (80)."\n";
        }

        $track = $1 if $_ =~ /class="smallfont"><span class="label">(\d+)<\/span><\/td>.$/;
        $name  = decode_entities($1) if $_ =~ /class="smallfont" width="100%">(.*?)<\/td>.$/;
        if ( $_ =~ /class="time">([\d:]+)<\/span><(?:\/td|div)/ ) {
            my $time = $1;
            if ($time =~ /(\d+):(\d+)/) {
                $secs = ($1*60)+$2;
            }
            dprint sprintf ("%-3.3s %-62.62s %-8.8s %-4.4s\n", $track, $name, $time, $secs);
            $vgm{"CD$disc"}{$track} = { TITLE => $name
                                      , TIME  => $time
                                      , SECS  => $secs
                                      };
            ($track,$name)=(0,0);
        }

        if ( $_ =~ /class="time">([\d:]+)<\/span><\/span>/) {
            dprint GREEN "=" x 59; dprint YELLOW BOLD " Disc Length = $1\n";
            last if $disc eq $vgm{TOTALDISCS};
        }
    } #foreach @result
} # sub vgmdbtitle

sub compare() {
    dprint BLUE BOLD "=" x (39)."\n";
    dprint BLUE BOLD "Comparing last results with our tracks:\n";
    dprint BLUE BOLD "=" x (39)."\n\n";
    foreach my $vgmcd (sort keys %vgm) {
        next unless ref($vgm{$vgmcd}) eq "HASH"; # Only the CDX hashes
        my $mark=0;
        my %current = %{$vgm{$vgmcd}};
        dprint "$vgmcd has ".keys(%current)." tracks and I got ".keys(%cd)." files...\t";
        if (keys(%current) ne keys(%cd)) {
            dprint RED BOLD "SKIPPING\n";
            next;
        } else {
            dprint GREEN BOLD "OK!\n";
            dprint GREEN "\n  This CD -> Our Files:\n=========================\n";
            foreach (sort keys %current) {
                dprint sprintf ("(%02d) % 4d -> (%02d) % 4d ", $_, $current{$_}{SECS}, $_, $cd{$_}{TIMES});
                my $subs = $current{$_}{SECS} - $cd{$_}{TIMES};
                if ($subs == 0) {
                    dprint GREEN BOLD "(0 secs) OK!\n";
                    $cd{$_}{NTITLE} = $current{$_}{TITLE};
                } elsif ($subs > 0 and $subs < $threshold) {

                    dprint YELLOW BOLD "($subs secs) OK!\n";
                    $cd{$_}{NTITLE} = $current{$_}{TITLE};
                } elsif ($subs < 0 and $subs > -$threshold) {
                    dprint YELLOW BOLD "($subs secs) OK!\n";
                    $cd{$_}{NTITLE} = $current{$_}{TITLE};
                } else {
                    dprint RED BOLD "($subs secs) NOK!\n";
                    $mark=1;
                }
            }
            if ($mark) {;
                dprint RED BOLD"\n$vgmcd FAILED!\n"; 
            } else {
                dprint GREEN BOLD"\nOK! '$vgm{ALBUM}' $vgmcd passed our requirements!\n"; 
                $vgmcd =~ s/\D//g;
                return $catnums[$vgmcd-1] unless $mark;
            }
        }
    } # foreach keys %vgm
    return 0;
} # compare

sub rename($) {
    dprint BLUE BOLD "=" x (20)."\n";
    dprint BLUE BOLD "Copying and Tagging:\n";
    dprint BLUE BOLD "=" x (20)."\n\n";
    my $vgmcd = shift;
    my $cdnum = 1;
    foreach (@catnums) {
        last if $_ eq $vgmcd;
        $cdnum++;
    }
    my $dir   = shift;
    my $newdir = "$vgm{ALBUM} [$vgmcd]";
    $newdir =~ s/[\/\:*?<>|]//g; # NTFS Valid file?
    $newdir =~ s/\s+/ /g;
    #print Dumper %cd;
    dprint GREEN "Directory to Create/Use: "; dprint "'$newdir'\n";
    mkdir "$newdir" unless -d $newdir;
    foreach my $track (sort keys %cd) {
#        $cd{$track}{NTITLE} =~ s/[\/\:*?<>|]/ /g; # NTFS Valid file?
        $cd{$track}{NTITLE} =~ s/["\*?<>]//g;  # NTFS Valid file
        $cd{$track}{NTITLE} =~ s/[\/:|]/, /g; # and proper
        $cd{$track}{NTITLE} =~ s/ +/ /g;      # formatting
        my $destfile = "$newdir/$track $cd{$track}{NTITLE}.flac";
        $destfile =~ s/[\:*?<>|]//g; # NTFS Valid file?
        my $bytes=-s $cd{$track}{FNAME};
        dprint "\n / Inside "; dprint BLUE BOLD "'$newdir'\n";
        dprint " | We will copy "; dprint YELLOW "'$cd{$track}{NTITLE}.flac' ($bytes bytes)\n";
        dprint " | as "; dprint YELLOW "'$cd{$track}{NTITLE}'\n";
        copy ($cd{$track}{FNAME}, "$destfile") or die $!;
        $bytes=-s $destfile;
        dprint " | "; dprint BOLD GREEN "OK! ($bytes bytes).\n";

        if (-B $destfile) {
            dprint " | "; dprint "Now we will tag it:\n";
            my $flac = Audio::FLAC::Header->new($destfile);
            my $tags = $flac->tags();
            %{$tags} = ();
            my $result = $flac->write();
            unless ($result) {
                dprint RED "No se pudieron limpiar los tags de $cd{$track}{NTITLE}.flac\n";
                return 0;
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
            $tags->{TRACKNUMBER}    = $track               ; dprint " |-- TRACKNUMBER\t= '$track'\n";
            $tags->{TOTALTRACKS}    = keys(%cd)            ; dprint " |-- TOTALTRACKS\t= '".keys(%cd)."'\n";
            $tags->{ALBUM}          = $newdir              ; dprint " |-- ALBUM\t\t= '$newdir'\n";
            $tags->{TITLE}          = $cd{$track}{'NTITLE'}; dprint " |-- TITLE\t\t= '$cd{$track}{'NTITLE'}'\n";
            $tags->{GENRE}          = $genre               ; dprint " |-- GENRE\t\t= '$genre'\n";
            $tags->{DATE}           = $date                ; dprint " |-- DATE\t\t= '$date'\n";
            $tags->{'ALBUM ARTIST'} = $aartist             ; dprint " |-- ALBUM ARTIST\t= '$aartist'\n";
            $tags->{ARTIST}         = $vgm{'Arranged by'}  ; dprint " |-- ARTIST\t\t= '$vgm{'Arranged by'}'\n";
            $tags->{COMPOSER}       = $vgm{'Composed by'}  ; dprint " |-- COMPOSER\t\t= '$vgm{'Composed by'}'\n";
            $tags->{PERFORMER}      = $vgm{'Performed by'} ; dprint " |-- PERFORMER\t\t= '$vgm{'Performed by'}'\n";
            $tags->{TOTALDISCS}     = $vgm{TOTALDISCS}     ; dprint " |-- TOTALDISCS\t\t= '$vgm{TOTALDISCS}'\n";
            $tags->{DISCNUMBER}     = $cdnum               ; dprint " |-- DISCNUMBER\t\t= '$cdnum'\n";
            $tags->{COMMENT}        = $description         ; dprint " |-- COMMENT\t\t= '$description'\n";
            $tags->{VERSION}        = $version             ; dprint " |-- VERSION\t\t= '$version'\n";
            $tags->{COPYRIGHT}      = $vgm{'Published by'} ; dprint " |-- COPYRIGHT\t\t= '$vgm{'Published by'}'\n";
            $result = $flac->write();
            if ($result) {
                dprint " \\ "; dprint GREEN BOLD "OK! Tagging done!\n";
            } else {
                dprint " \\ "; dprint RED BOLD "No se pudo tagear $cd{$track}{NTITLE}.flac debidamente.\n";
                return 0;
            }
        } else {
            dprint " \\ "; dprint RED BOLD "El fichero '$destfile' no existe o no es binario";
            return 0;
        }
    } # foreach my $track

    open(LOG, "> $newdir/log_ansi.txt") || die "Can't redirect stdout";
    map {s/ +$//g;print LOG $_} @log;
    close(LOG);
    open(LOG, "> $newdir/log.txt") || die "Can't redirect stdout";
    map {s/ +$//g; s/.\[\d+m//g; print LOG $_} @log;
    close(LOG);
    return $newdir;
} # sub rename
