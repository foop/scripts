#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;

use LWP::Simple;
use XML::Simple;

use constant LINZ_AG_URL => "http://www.linzag.at/static/XML_DM_REQUEST";

sub get_trips {
    my ( $name_dm, $no_of_trips ) = @_;
    my ( $result, $result_trips, $requestID, $sessionID, $direction, 
          $max_length_dest, $max_length_countdown, $max_length_line );
    $requestID = $sessionID = $max_length_dest = $max_length_countdown = $max_length_line = 0; 

    # cheat sheet:
    # http://www.linzag.at/static/XML_DM_REQUEST?sessionID=0&locationServerActive=1&type_dm=any&name_dm=60502280
    # http://www.linzag.at/static/XML_DM_REQUEST?sessionID=2880156875&requestID=1&dmLineSelectionAll=1

    # open session and get ID
    my $get_s_id_url = LINZ_AG_URL
                       . "?sessionID=${sessionID}"
                       . "&locationServerActive=1" # TODO: What does this do?
                       . "&type_dm=any"
                       . "&name_dm=${name_dm}"
                       . "&limit=${no_of_trips}";

    my $xml = XMLin(get( $get_s_id_url ));
    # retrieve XML for trips
    $sessionID = $xml->{sessionID};
    my $get_time_url = LINZ_AG_URL
                       . "?sessionID=${sessionID}"
                       . "&requestID=${requestID}"
                       . "&dmLineSelectionAll=1";
    $xml = XMLin(get( $get_time_url ));

    # map direction shortcode_letters to names (e.g $direction->{27}->{R} = "Linz Auwiesen" );
    foreach my $line (@{$xml->{itdDepartureMonitorRequest}->{itdServingLines}->{itdServingLine}} ) {
        $direction->{$line->{number}}->{$line->{motDivaParams}->{direction}} = $line->{direction};
    }

    # parse trips
    foreach my $trip (@{$xml->{itdDepartureMonitorRequest}->{itdDepartureList}->{itdDeparture}})  {
        my $line        = $trip->{itdServingLine}->{symbol};
        my $dest_code   = $trip->{itdServingLine}->{motDivaParams}->{direction};
        my $destination = $direction->{$line}->{$dest_code};
        my $countdown   = $trip->{countdown};
        my $hour        = $trip->{itdDateTime}->{itdTime}->{hour};
        my $minute      = $trip->{itdDateTime}->{itdTime}->{minute};
        $max_length_dest      = length($destination) if ( length($destination) > $max_length_dest);
        $max_length_countdown = length($countdown) if ( length($countdown) > $max_length_countdown);
        $max_length_line      = length($line) if ( length($line) > $max_length_line);

        push (@$result_trips, { 
                line        => $line,
                destination => $destination,
                countdown   => $trip->{countdown},
                hour        => $hour,
                minute      => $minute,
            });
    }

    $result->{trips}                = $result_trips;
    $result->{max_length_dest}      = $max_length_dest;
    $result->{max_length_countdown} = $max_length_countdown;
    $result->{max_length_line}      = $max_length_line;
    return $result;
}

sub print_trips {
    # quick hack

    my $t = shift;
    my $ml_dest = $t->{max_length_dest};
    my $ml_cd   = $t->{max_length_countdown};
    my $ml_ln   = $t->{max_length_line};
    $ml_ln = length("line")        if ( length("line") > $ml_ln );
    $ml_cd = length("countdown")   if ( length("countdown") > $ml_cd );
    $ml_dest = length("destination") if ( length("destination") > $ml_dest );
    my $total_line_length = $ml_ln + $ml_cd + $ml_dest + 21;
    print ( "  ". "=" x $total_line_length . "\n" );
    # line      destination     countdown   time
    printf(" |  %-${ml_ln}s    %-${ml_dest}s   %-${ml_cd}s   %s     |\n", "line", "destination", "countdown", "time" );
    print ( "  ". "=" x $total_line_length . "\n" );
    $ml_cd -= length("(min) ");
    $ml_cd += length(" ");
    for my $entry ( @{$t->{trips}} ) {
        printf(" |   %-${ml_ln}s | %-${ml_dest}s | %-${ml_cd}d(min) | %02d:%02d h  |\n",
                                      $entry->{'line'}, $entry->{'destination'},
                                      $entry->{'countdown'},
                                      $entry->{'hour'}, $entry->{'minute'});
    }
    print ( "  ". "-" x $total_line_length . "\n" );
}

my $name_dm = 60502280;
my $no_of_trips = 10;
my $trips = get_trips($name_dm, $no_of_trips);
#print Dumper($trips);
print_trips($trips);
