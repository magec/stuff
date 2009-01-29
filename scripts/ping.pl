use Net::Ping;

$host = $ARGV[0];

$p = Net::Ping->new();
	print "$host is alive.\n" if $p->ping($host);
$p->close();

