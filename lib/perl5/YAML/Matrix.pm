package YAML::Matrix;
use strict;
use warnings;
use 5.010;
use File::Basename qw/ basename /;
use IO::All;
use Encode;

use base 'Exporter';
our @EXPORT_OK = qw/
    minimal_events minimal_events_for_framework
    hsyaml_event_to_event
    generate_expected_output
    load_csv gather_tags
/;

sub minimal_events_for_framework {
    my ($type, @events) = @_;
    my %args;
    if ($type eq 'cpp') {
        $args{anchors_to_numbers} = 1;
        $args{no_explicit_doc} = 1;
        $args{no_quoting_style} = 1;
    }
    elsif ($type eq 'flow') {
        $args{no_flow_indicator} = 1;
    }
    minimal_events(\%args, @events);
}

sub minimal_events {
    my ($args, @events) = @_;
    my %anchor_map;
    my $anchor_count = 0;

    for my $event (@events) {
        if ($event =~ m/^\+DOC/) {
            $anchor_count = 0;
        }
        if ($args->{no_explicit_doc} and $event =~ m/^\+DOC ---/) {
            $event = '+DOC';
        }
        elsif ($args->{no_explicit_doc} and $event =~ m/^-DOC \.\.\./) {
            $event = '-DOC';
        }
        elsif ($args->{no_quoting_style} and $event =~ s/^=VAL//) {
            my $ev = '=VAL';
            if ($event =~ s/^ &(\S+)//) {
                $ev .= " &$1";
            }
            if ($event =~ s/^ (<.*?>)//) {
                $ev .= " $1";
            }
            if ($event =~ s/^ ["'>|](.*)//) {
                $ev .= " :$1";
            }
            else {
                $ev .= $event;
            }
            $event = $ev;
        }

        if ($args->{no_flow_indicator}) {
            $event =~ s/^\+MAP \{\}/+MAP/mg;
            $event =~ s/^\+SEQ \[\]/+SEQ/mg;
        }
        if ($args->{anchors_to_numbers}) {
            if ($event =~ m/^(\+MAP(?: \{\})?|\+SEQ(?: \[\])?|=VAL|=ALI) (&|\*)(\S+)(.*)/) {
                my $ev = $1;
                my $ali = $2;
                my $name = $3;
                my $rest = $4;

                my $index = $anchor_map{ $name };
                if ($ali eq '&') {
                    $anchor_count++;
                    $index = $anchor_count;
                    $anchor_map{ $name } = $index;
                }
                $event = "$ev $ali$index$rest";
            }
        }
    }
    return @events;
}

# HsYaml outputs {}[] with special logic: implicit flow mappings in flow
# sequences `[ key: value ]` don't get a {}, so we remove all
sub hsyaml_event_to_event {
    my (@events) = @_;
    for my $event (@events) {
        $event =~ s/^\+MAP \{\}/+MAP/;
        $event =~ s/^\+SEQ \[\]/+SEQ/;
    }
    return @events;
}

sub gather_tags {
    my ($dir) = @_;
    my %tags;
    opendir my $dh, $dir or die $!;
    my @tags = grep { -d "$dir/$_" and not m/^\./ } readdir $dh;
    closedir $dh;
    for my $tag (@tags) {
        my $tagdir = "$dir/$tag";
        opendir my $dh, $tagdir or die $!;
        my @ids;
        for my $item (readdir $dh) {
            if (-l "$tagdir/$item" and $item =~ m/^[A-Z0-9]{4}$/) {
                push @ids, $item;
                next;
            }
            if (-d "$tagdir/$item") {
                opendir my $dh, "$tagdir/$item" or die $!;
                my @subids = map {"$item:$_" } grep { -l "$tagdir/$item/$_" and m{^\d+$} } readdir $dh;
                closedir $dh;
                push @ids, @subids;
            }
        }
        closedir $dh;
        for my $id (@ids) {
            $tags{ $id } ||= [];
            push @{ $tags{ $id } }, $tag;
        }
    }
    return \%tags;
}

sub generate_expected_output {
    my ($dir) = @_;
    my $id = basename $dir;
    print "#$id\r";
    my %expected;

    my @test_events = io->file("$dir/test.event")->chomp->encoding('utf-8')->slurp;
    for my $typw (qw/ cpp flow /) {
        my @minimal = minimal_events_for_framework($typw, @test_events);
        $expected{"minimal.$typw.event"} = join '', map { "$_\n" } @minimal;
    }

    if (-f "$dir/in.json") {
        my $exp_json = decode_utf8 scalar qx{jq --sort-keys . < $dir/in.json 2>&1};
        $expected{"in.json"} = $exp_json;
    }
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%expected], ['expected']);
    return %expected;
}

# sub normalize_json {
#     my ($json) = @_;
#     require JSON::XS;
#     my $coder = JSON::XS->new->ascii->pretty->allow_nonref->canonical;
#     my $data = eval { $coder->decode($json) };
#     $json = $coder->encode($data);
#     return $json;
# }

# CSV to List of Hashes
my $separator = ",";
sub load_csv {
    my ($id_field, $arg) = @_;
    my $header;
    my @lines;
    if (ref $arg eq 'ARRAY') {
        @lines = @$arg;
        $header = shift @lines;
    }
    else {
        open my $fh, "<", $arg or die $!;
        chomp($header = <$fh>);
        chomp(@lines = <$fh>);
    }
    my @headers = split m/$separator/, $header;

    my %result;
    for my $line (@lines) {
        my @fields = split m/$separator/, $line;
        my %row;
        @row{ @headers } = @fields;
        my $id = $row{ $id_field };
        $result{ $id } = \%row;
    }
    return \%result;
}


1;
