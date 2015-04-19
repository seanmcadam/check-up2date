#!/usr/bin/perl
#
# Run post up2date call
#
# First of Month, check last months updates.
# Daily Check this mornings updates
#
# [Thu Apr  2 04:03:06 2015] up2date installing packages: ['firefox-31.6.0-2.0.1.el5_11']
# [Tue Apr 14 04:01:20 2015] up2date installing packages: ['openssl-0.9.8e-33.0.1.el5_11', 'openssl-devel-0.9.8e-33.0.1.el5_11']
#

use Carp;
use Data::Dumper;
use Sys::Hostname;
use Date::Manip;
use strict;

my $DAYS = 16;

my $hostname = hostname;

my $dir = "/var/log/";

opendir( DIR, $dir ) || die "Failed to open DIR: $dir\n";
my @all_files = readdir(DIR);
close DIR;

my @files = map { $_ =~ /^up2date/ ? ($_) : () } @all_files;

my ( $now_sec, $now_min, $now_hour, $now_mday, $now_mon, $now_year, $now_wday, $now_yday, $now_isdst ) = localtime(time);
my %abbr = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6, Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12, );
$now_year += 1900;
$now_mon++;

my $now_date = ParseDate( sprintf( "%04d%02d%02d", $now_year, $now_mon, $now_mday ) );
my %up2date_lines;

my $search1 = "up2date installing packages:";

foreach my $file_name (@files) {
    my $file = $dir . $file_name;
    if ( !( open( UP2DATE, $file ) ) ) {
        warn "Unable to open $file\n";
        next;
    }

    while (<UP2DATE>) {
        chop;
        my $line = $_;
        if ( !( $line =~ /$search1/ ) ) { next; }

        if ( $line =~ /\[(.+)\] $search1 \[(.+)\]/ ) {
            my $d = $1;
            my $l = $2;
            $l =~ s/'//g;
            $l =~ s/ //g;

            $d =~ /(\w+) (\w+) +(\d+) (\d+):(\d+):(\d+) (\d+)/;
            my $line_year = $7;
            my $line_mon  = $2;
            my $line_day  = $3;

            my $date_string = sprintf( "%04d%02d%02d", $line_year, $abbr{$line_mon}, $line_day );
            my $line_date = ParseDateString($date_string);

            my $delta = DateCalc( $line_date, $now_date );

            my ( $d_y, $d_m, $d_w, $d_d, $d_h, $d_mi, $d_s ) = split( /:/, $delta );
            $d_y =~ s/\+//;
            $d_y =~ s/-//;

            if ( $DAYS >= ( ( $d_y * 365 ) + ( $d_m * 30 ) + ( $d_w * 7 ) + $d_d ) ) {
                my @items = split( /,/, $l );
                $up2date_lines{$date_string} = \@items;
            }
        }
    }
    close UP2DATE;
}

my @list = ();
foreach my $date ( keys(%up2date_lines) ) {
    push( @list, @{ $up2date_lines{$date} } )
}

print "Package Updates for the last $DAYS days for $hostname\n";

if ( !scalar @list ) {
    print "No packages updated\n";
}
else {
    print join( "\n", sort(@list) ) . "\n";
}

