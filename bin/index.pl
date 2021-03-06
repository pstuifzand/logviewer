use feature 'say';
use IO::Socket::IP;
use WebService::Solr;
use DateTime;
use JSON::XS 'decode_json';
use Data::Dumper;
use Data::UUID;
use Time::HiRes 'gettimeofday','tv_interval';

my $io = IO::Socket::IP->new(Proto => 'udp', LocalPort => '5066');

my $solr = WebService::Solr->new('http://localhost:8983/solr/logviewer');

my $ug = Data::UUID->new;

my $data;
my @docs;

while ($io->recv($data, 4096)) {
    my $o = decode_json($data);
    my $doc = {
        id          => $ug->create_str,
        date_f      => delete $o->{date},
        message_txt => delete $o->{message},
        filename_s  => delete $o->{filename},
        line_i      => delete $o->{line},
        project_s   => delete $o->{project},
    };

    for (keys %$o) {
        $doc->{'attr_' . $_} = $o->{$_};
    }
    push @docs, $doc;

    if (@docs == 48) {
        say 'adding docs';
        $startTime = [gettimeofday];
        $solr->add($doc);
        @docs = ();
        say 'done ' . tv_interval($startTime);
    }
}


