package logviewer;

use feature "say";

use Dancer2;
use DateTime;
use WebService::Solr;
use WebService::Solr::Query;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/search' => sub {
    my $q = param 'q';
    my $solr = WebService::Solr->new('http://localhost:8983/solr/logviewer');
    my @res;
    if ($q) {
        my $res = $solr->search(
            WebService::Solr::Query->new({message_txt => $q}),
            { fl => 'message_txt,project_s,date_i,id,filename_s,line_i'});
        if ($res->ok) {
            push @res, @{$res->docs};
        }
    }
    my @results;
    for my $doc (@res) {
        push @results, {
            date     => DateTime->from_epoch(epoch => scalar($doc->value_for('date_i'))),
            message  => $doc->value_for('message_txt'),
            filename => $doc->value_for('filename_s'),
            line     => $doc->value_for('line_i'),
            project  => $doc->value_for('project_s'),
        };
    }

    template 'index', { q => $q, results => \@results };
};

true;