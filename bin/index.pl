use feature 'say';
use IO::Socket::IP;
use WebService::Solr;
use DateTime;
use JSON::XS 'decode_json';
use Data::Dumper;

my $io = IO::Socket::IP->new(Proto => 'udp', LocalPort => '5066');

my $solr = WebService::Solr->new('http://localhost:8983/solr/logviewer');

my $id = 4;
my $data;
while ($io->recv($data, 4096)) {
    my $o = decode_json($data);
    print Dumper($o);

    my $doc = {
        id => $id++,
        date_i => $o->{date},
        message_txt => $o->{message},
        filename_s => $o->{filename},,
        line_i => $o->{line},
        project_s => $o->{project},
    };
    $solr->add($doc);
}

