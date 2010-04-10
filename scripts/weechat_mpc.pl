weechat::register("mpc", "zaibach", "0.001", "GPL", "Show current song info from mpc. Usage: /mpc", "", "");
weechat::hook_command("mpc", "", "", "", "", "info", "");

sub info {
    my ($data, $buffer, $args) = @_;
    $args = "127.0.0.1" unless $args;
    my ($name, $artist, $album, $title, $track, $time, $file, $stats, $footer) = split("\n", `mpc -f "%name%\n%artist%\n%album%\n%title%\n%track%\n%time%\n%file%" -h $args 2>/dev/null`);
    if ($artist and $title and $album and $stats) {
        #$artist =~ tr/\000-\177//cd; #Only non-extended ASCII
        $artist =~ s/\s\/\s[^,]+//g if length($artist) > 60;
        $artist = 'V.A.'if length($artist) > 60;
        $stats =~ s/\s+/ /g;
        weechat::command($buffer, "$stats Track $track: $artist - $title, From The Album \'$album\'");
    }
    return weechat::WEECHAT_RC_OK;
}
