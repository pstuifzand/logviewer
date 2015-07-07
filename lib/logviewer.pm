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
    my $page = param 'p';
    $page ||= 1;
    my $q = param 'q';
    my $qi = $q;
    $qi ||= '*:*';

    my %enabled_filters;
    for my $param (params) {
        my ($filter,$key,$value) = split/:/,$param,3;
        if ($filter eq 'filter') {
            $enabled_filters{$key.':'.$value} = $key.':"'.$value.'"';
        }
    }

    $qi =~ s/\bproject:/project_s:/g;
    $qi =~ s/\bmessage:/message_txt:/g;
    $qi =~ s/\bdate:/date_f:/g;
    $qi =~ s/\bfilename:/filename_s:/g;
    $qi =~ s/\bline:/line_i:/g;

    if (keys %enabled_filters) {
        $qi .= ' AND ' . join(' AND ', values %enabled_filters);
    }

    my $solr = WebService::Solr->new('http://localhost:8983/solr/logviewer');
    my @res;
    my $res;
    if ($qi) {
        $res = $solr->search(
            $qi,
            { sort => 'date_f desc', rows => 20, start => ($page-1)*20, facet => 'true',
                'facet.field'=>['filename_s','project_s','attr_package'],
            });

        if ($res->ok) {
            print Dumper($res->facet_counts);
            push @res, @{$res->docs};
        }
    }

    my @results;
    for my $doc (@res) {
        my @field_names = grep !/^attr_request_id/, grep /^attr_/, $doc->field_names;
        push @results, {
            date     => DateTime->from_epoch(epoch => scalar($doc->value_for('date_f') || $doc->value_for('date_i'))),
            message  => $doc->value_for('message_txt'),
            filename => $doc->value_for('filename_s'),
            line     => $doc->value_for('line_i'),
            project  => $doc->value_for('project_s'),
            request_id => $doc->value_for('attr_request_id'),
            field_names => \@field_names,
            fields   => { map { $_ => $doc->value_for($_) } @field_names },
        };
    }
    my @names;
    #if ($res->facet_counts) {
        @names = keys %{$res->facet_counts->{facet_fields}};
    #}

    my @filters;

    for my $name (@names) {
        my @values = @{$res->facet_counts->{facet_fields}{$name}};
        my @f;

        while (my ($k, $v) = splice @values, 0, 2) {
            my $label = $k;
            $label =~ s{^/home/peter/work/webwinkel/app/lib/}{}g;
            $label =~ s{^/home/peter/work/}{}g;
            my $key_name = $name . ':' . $k;
            push @f, { name => $key_name, label => $label, key => $k, count => $v };
        }
        use sort 'stable';
        @f = sort { $a->{count} <=> $b->{count} } @f;
        @f = sort { $a->{key} cmp $b->{key} } @f;
        push @filters, { name => $name, filters => \@f };
    }

    @filters = sort {$a->{name} cmp $b->{name}} @filters;

    my $params = {
        q        => $q,
        qi       => $qi,
        results  => \@results,
        response => $res,
        filters  => \@filters,
        enabled_filters => \%enabled_filters,
    };

    if ($res) {
        $params->{pager} = $res->pager;
    }
    template 'index', $params;
};

true;
