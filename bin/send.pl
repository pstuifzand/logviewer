use feature 'say';
use IO::Socket::IP;
use DateTime;
use JSON::XS 'encode_json';
use Data::Dumper;

my $io = IO::Socket::IP->new(Proto => 'udp', PeerAddr => 'localhost', PeerPort => '5066');
my $data = encode_json({
        project  => 'logsender',
        date     => time,
        filename => __FILE__,
        line     => __LINE__,
        message  => 'testmessage',
});
$io->send($data, 4096);
$io->close;
