#!/usr/bin/perl

# colors
$c1 = "\e[0;34m";
$c2 = "\e[0;36m";
$c3 = "\e[0;m";

#what values to display. Use "OS Kernel DE WM WMTheme Font Icon Theme"
$display = "OS Kernel DE WM WMTheme Theme Icon Font";


use Switch;

@wm = ("fluxbox", "openbox", "blackbox", "awesome",
       "xfwm", "metacity", "kwin");
@line = ();
%de = ("gnome", "gnome-session",
       "xfce", "xfce",
       "kde", "ksmserver");
$quite = 1; # Prints little debugging messages if set to 0;
$tryWP = 1; # trys to find your wallpaper if set to 0;

## Dont alter after this ##
my $isDE = 0;
my $version = `cat /etc/arch-release`;
my $kernel = `uname -r`;
$version =~ s/\s+/ /g;
$kernel =~ s/\s+/ /g;
$version = "$c1 OS:$c3 $version";
$kernel = "$c1 Kernel:$c3 $kernel";
if ( $display =~ "OS"){
    push(@line, "$version");
}
if ( $display =~ "Kernel"){
    push(@line, "$kernel");
}

parsePS(2);
$isDE == 0 && print "No DE found, not running one?..\n" unless $quite == 1;

if( $isDE == 0 ) {
   if( !open(GTKRC, "<", "$ENV{HOME}/.gtkrc-2.0")  ) {
      print "$ENV{HOME}.gtkrc-2.0 -> $!...\n";
   } else {
      while( <GTKRC> ) {
         if( /include "$ENV{HOME}\/\.themes\/(.+)\/gtk-(1|2)\.0\/gtkrc"/ ){
            $theme = "$c1 Theme:$c3 $1";
            if ( $display =~ m/Theme/ ) {
                push(@line, "$theme");
            }
         }
         if( /gtk-icon-theme-name.*=.*"(.+)"/ ) {
            $icon = "$c1 Icons: $c3 $1";
            if ( $display =~ m/Icon/ ) {
                push(@line, "$icon");
            }
         }
         if( /gtk-font-name.*=.*"(.+)"/ ) {
            $font = "$c1 Font:$c3 $$1";
            if ( $display =~ m/Font/ ) {
                push(@line, "$font");
            }
         }
      }
      close(GTKRC);
   }

   ## Processes First
   parsePS(1);
   ## Couldn't find a WM in PS
   $WM =~ /Unknown/ && print "No WM found, yours isn't on the list?...\n" unless $quite == 1;
} else {
   grabDEinfo($DE);
}

print "
$c1              __
$c1          _=(SDGJT=_
$c1        _GTDJHGGFCVS)                @line[0]
$c1       ,GTDJGGDTDFBGX0               @line[1]
$c1      JDJDIJHRORVFSBSVL$c2-=+=,_        @line[2]
$c1     IJFDUFHJNXIXCDXDSV,$c2  \"DEBL      @line[3]
$c1    |LKDSDJTDU=OUSCSBFLD.$c2   '?ZWX,   @line[4]
$c1    LMDSDSWH'    \`?DCBOSI$c2     DRDS], @line[5]
$c1   SDDFDFH'        \`0YEWD,$c2   )HDROD  @line[6]
$c1  !KMDOCG            &GSU|$c2\_GFHRGO'   @line[7]
$c1  HKLSGP'$c2           __$c1\TKM0$c2\GHRBV)'
$c1 JSNRVW'$c2       __+MNAEC$c1\IOI,$c2\BN'
$c1 HELK['$c2    __,=OFFXCBGHC$c1\FD)
$c1 ?KGHE $c2\_-#DASDFLSV='$c1    'EF
$c1 'EHTI                   !H
$c1  \`0F'                   '!
";

sub parsePS {
   my $x = 0;
   my $y = 0;
   my $found = 0;
   my $psl = `ps -A | awk {'print \$4'}`;
   @psl = split(/\n/, $psl);

   switch (shift @_) {
      case 1 {
         $WM = "Unknown";
         while( $x < @wm && $found == 0 ) {
            while( $y < @psl ) {
               print "Testing '$psl[$y]' with '$wm[$x]'\n" unless $quite == 1;
               if( $psl[$y] =~ /$wm[$x]/ ) {
                  $WM = "    $wm[$x]";
                  if ( $display =~ m/WM/ ) {
                  push(@line, "$c1 WM:$c3 $WM");
                  }
                  print "WM found as $WM\n" unless $quite == 1;
                  getWMtheme();
                  $found = 1;
                  last;
               }
               $y++;
            }
            $y = 0;
            $x++;
            $found == 1 && last;
         }
      }
      case 2 {
         $isDE = 0;
         $DE = "None";
         while( ($dev, $devid) = each(%de) ) {
            while( $x < @psl ) {
               print "Testing '$psl[$x]' with '$devid'\n" unless $quite == 1;
               if( $psl[$x] =~ /$devid/ ) {
                  $DE = $dev;
                  print "DE found as $DE\n" unless $quite == 1;
                  $found = 1;
                  $isDE = 1;
                  if ( $display =~ m/DE/ ) {
                      push(@line, "$c1 DE:$c3 $DE");
                  }
                  last;
               }
               $x++;
            }
            $x = 0;
            $found == 1 && last;
         }
      }
   }
}

sub getWMtheme {

   switch($WM) {
      case "openbox" {
         open(FILE, "<", "$ENV{HOME}/.config/openbox/rc.xml")
            || die("$!\nFailed to open OpenBox rc.xml...\n");
         while( <FILE> ) {
            if( /<name>(.+)<\/name>/ ) {
               print "OB Theme found as $1\n" unless $quite == 1;
               $WMTHEME = $1;
               $wmtheme = "$c1 WM Theme:$c3 $WMTHEME";
               if ( $display =~ m/WMTheme/ ) {
                   push(@line, "$wmtheme");
               }
               last;
                }
              }
         close(FILE);
      }
      case "metacity" {
         $WMTHEME = `gconftool-2 -g /apps/metacity/general/theme`;
         $wmtheme = "$c1 WM Theme:$c3 $WMTHEME";
         if ( $display =~ m/WMTheme/ ) {
             push(@line, "$wmtheme");
         }
      }
      case "fluxbox" {
         open(FILE, "<", "$ENV{HOME}/.fluxbox/init")
            || die("$!\nFailed to open Fluxbox init file...\n");
         while( <FILE> ) {
            if( /session.styleFile: \/.+\/(.+)$/ ) {
               print "FB Theme found as $1\n";
               $WMTHEME = $1;
               $wmtheme = "$c1 WM Theme:$c3 $WMTHEME";
               if ( $display =~ m/WMTheme/ ) {
                   push(@line, "$wmtheme");
               }
               last;
            }
         }
         close(FILE);
      }
      case "blackbox" {
         open(FILE, "<", "$ENV{HOME}/.blackboxrc")   
            || die("$!\nFailed to open Blackbox .blackboxrc file...\n");
                        while( <FILE> ) {
                                if( /session.styleFile: \/.+\/(.+)$/ ) {
                                        print "BB Theme found as $1\n";
               $WMTHEME = $1;
               $wmtheme = "$c1 WM Theme:$c3 $WMTHEME";
               if ( $display =~ m/WMTheme/ ) {
               push(@line, "$wmtheme");
               }
               last;
            }
         }
         close(FILE);
      }
      case "xfwm" {
         open(FILE, "<", "$ENV{HOME}/.config/xfce4/mcs_settings/xfwm4.xml")
            || die("XFCE4 -> $!...\n");
         while( <FILE> ) {
            if( /<option name="Xfwm\/ThemeName" type="string" value="(.+)"\/>/ ) {
               $WMTHEME = $1;
               $wmtheme = "$c1 WM Theme:$c3 $WMTHEME";
               if ( $display =~ m/WMTheme/ ) {
                   push(@line, "$wmtheme");
                        }
            }
         }
         close(FILE);
      }
      case "kwin" {
        open(FILE, "<", "$ENV{HOME}./kde/share/config/kwinrc")
          || die("\nFailed to open kwin config file \n");
        while( <FILE> ) {
          if( /PluginLib=(.+)/ ) {
            $WMTHEME = $1;
            $wmtheme = "$c1 WM Theme:$c3 $WMTHEME";
            if ( $display =~ m/WMTheme/ ) {
              push(@line, "$wmtheme");
            }
          }
         }
         close(FILE);
     }
   }
}

sub grabDEinfo {

   switch(shift @_) {
      case "gnome" {
         parsePS(1);
         if ( $display =~ m/Theme/ ) {
             $THEME = `gconftool-2 -g /desktop/gnome/interface/gtk_theme`;
             $theme = "$c1 Theme:$c3 $THEME";
             push(@line, "$theme");
         }
         if ( $display =~ m/Icon/ ) {
             $ICON = `gconftool-2 -g /desktop/gnome/interface/icon_theme`;
             $icon = "$c1 Icon:$c3 $Icon";
             push(@line, "$icon");
         }
         if ( $display =~ m/Font/ ) {
            $FONT = `gconftool-2 -g /desktop/gnome/interface/font_name`;
            $font = "$c1 Font:$c3 $FONT";
            push(@line, "$font");
         }
      }
      case "xfce" {
         parsePS(1);
         open(FILE, "<", "$ENV{HOME}/.config/xfce4/mcs_settings/gtk.xml")
            || die("XFCE4 GTK -> $!...\n");
         while( <FILE> ) {
            if( /<option name="Net\/ThemeName" type="string" value="(.+)"\/>/ ) {
               $THEME = $1;
               $theme = "$c1 Theme:$c3 $THEME";
               if ( $display =~ m/Theme/ ) {
                   unshift(@xfce, "$theme");
               }
            }
            if( /<option name="Net\/IconThemeName" type="string" value="(.+)"\/>/ ) {
               $ICON = $1;
               $icon = "$c1 Icon:$c3 $ICON";
               if ( $display =~ m/Icon/ ) {
                   unshift(@xfce, "$icon");
               }
            }
            if( /<option name="Gtk\/FontName" type="string" value="(.+)"\/>/ ) {
               $FONT = $1;
               $font = "$c1 Font:$c3 $FONT";
               if ( $display =~ m/Font/ ) {
                   unshift(@xfce, "$font");
               }
            }
         }
         close(FILE);
            foreach $i (@xfce) {
               push(@line, "$i");
            }
      }
      case "kde" {
        prasePS(1);
        open(FILE, "<", "$ENV{HOME}/.kde/share/config/kdeglobals")
          || die("\nFailed to open kwin config file \n");
        while( <FILE> ) {
          if( /Theme=(.+)/ ) {
            $ICON = $1;
            $icon = "$c1 Icon:$c3 $ICON";
               if ( $display =~ m/Icon/ ) {
                 push(@line, $icon);
               }
          }
          if( /widgetStyle(.+)/ ) {
            $THEME = $1;
            $theme = "$c1 Theme:$c3 $THEME";
              if ( $display =~ m/Theme/ ) {
                push(@line, $icon);
              }
          }
          if( /font=(.+),.*/ ) {
            $FONT = $1;
            $font = "$c1 Font:$c3 $FONT";
              if ( $display =~ m/Icon/ ) {
                push(@line, $font);
              }
          }
        }
      }
   }
 my $shot = `scrot`
}
