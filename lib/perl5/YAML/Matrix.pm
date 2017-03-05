package YAML::Matrix;
use strict;
use warnings;
use 5.010;
use File::Basename qw/ basename /;
use IO::All;

use base 'Exporter';
our @EXPORT_OK = qw/
    minimal_events minimal_events_for_framework
    cpp_event_to_event java_event_to_event
    generate_expected_output
    normalize_json
/;

sub minimal_events_for_framework {
    my ($type, @events) = @_;
    my %args;
    if ($type =~ m/^(pyyaml|ruamel|cpp)$/) {
        $args{no_explicit_doc} = 1;
        $args{no_quoting_style} = 1;
    }
    if ($type eq 'cpp') {
        $args{anchors_to_numbers} = 1;
    }
    minimal_events(\%args, @events);
}

sub minimal_events {
    my ($args, @events) = @_;
    my %anchor_map;
    my $anchor_count = 0;

    for my $event (@events) {
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

        if ($args->{anchors_to_numbers}) {
            if ($event =~ m/^(\+MAP|\+SEQ|=VAL|=ALI) (&|\*)(\S+)(.*)/) {
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

sub cpp_event_to_event {
    my (@events) = @_;
    for my $event (@events) {
        $event =~ s/^\+MAP \{\}/+MAP/;
        $event =~ s/^\+SEQ \[\]/+SEQ/;
    }
    return @events;
}

sub java_event_to_event {
    my (@events) = @_;
    return cpp_event_to_event(@events);
}

sub generate_expected_output {
    my ($dir) = @_;
    my $id = basename $dir;
    print "#$id\r";
    my %expected;

    my @test_events = io->file("$dir/test.event")->chomp->slurp;
    for my $fw (qw/ pyyaml ruamel cpp /) {
        my @minimal = minimal_events_for_framework($fw, @test_events);
        $expected{"minimal.$fw.event"} = join '', map { "$_\n" } @minimal;
    }

    if (-f "$dir/in.json") {
        my $exp_json = io->file("$dir/in.json")->slurp;
        $exp_json = normalize_json($exp_json);
        $expected{"in.json"} = $exp_json;
    }
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%expected], ['expected']);
    return %expected;
}

sub normalize_json {
    my ($json) = @_;
    require Mojo::JSON;
    my $data = eval { Mojo::JSON::decode_json($json) };
    $json = Mojo::JSON::encode_json($data);
    return $json;
}

1;
