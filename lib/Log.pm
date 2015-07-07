package Log;
use strict;
use warnings;
use IO::Socket::IP;
use JSON::XS 'encode_json';
use Time::HiRes 'time';

sub send_log {
    my ($project, $message, %additional) = @_;

    my ($package, $filename, $line) = caller;

    my $io = IO::Socket::IP->new(Proto => 'udp', PeerAddr => 'localhost', PeerPort => '5066');

    my $data = encode_json({
        %additional,
        project  => $project,
        date     => time,
        package  => $package,
        filename => $filename,
        line     => $line,
        message  => $message,
    });

    $io->send($data, 4096);
    $io->close;
    return;
}

1;
