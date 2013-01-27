#!/usr/bin/env perl

use strict;
use warnings;
use LWP::Simple;
use Time::Local;


use Data::Dumper;

my $url_prefix = "http://forum.wiziwig.eu/";
my $url_forum = "${url_prefix}forums/10-NBA-Basketball";
my $content = get($url_forum);
die "Could not get $url_forum" unless defined $content;

die "Could not parse $url_forum" unless ( $content=~m{href="([^"]+)"[^>]+>NBA\s+Today!} );
my $url_nba_today = "${url_prefix}$1";

$content = get($url_nba_today);
die "Couldn't get $url_nba_today" unless defined $content;

my %game;

PARSE: {
    my $current_game;
    my $current_time;

    foreach ( split( '\n', $content ) )  {
        if ( m{(\d\d:\d\d)\s+GMT\s+/(\d\d:\d\d)\s+CET} ) {
            $current_time = $2;
        } elsif ( m:<b>([^<]+)</b>.*<b>([^<]+)</b>: ) {
           $current_game = $1;
           $game{$current_time}{$current_game}{'home_team'} = $2;
           #$game->{$current_time}{$current_game}->{'url' => [] };
        } else { 
            if ( defined $current_time ) {
                if ( m:</div>: ) { last PARSE }; # <------------------- END OF LOOP 
                if ( defined $current_game ) {
                    while ( m:<li[^>]*><a href="([^"]+)":g ) {
                        if ( defined $current_time ) {
                            #print $1 , "\n";
                            push( @{$game{$current_time}{$current_game}{'url'}},$1);
                        }
                    }
                }
            }
        }
    }
}

PRINT_NICELY: {
    foreach my $time ( sort keys %game ) {
        foreach my $a_team ( sort keys $game{$time} ) {
            
            print "$time: $a_team \@ $game{$time}{$a_team}{'home_team'}\n\n";
                foreach my $link ( @{$game{$time}{$a_team}{'url'}} ){
                    print "\t$link\n";
                }
                print "\n";
            }
        }    
    }
