package YAML::Matrix;
use strict;
use warnings;
use 5.010;

use base 'Exporter';
our @EXPORT_OK = qw/
    minimal_events minimal_events_for_framework
    cpp_event_to_event java_event_to_event
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

1;
