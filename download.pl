#!/usr/bin/perl

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
my $req = HTTP::Request->new(GET => 'http://www.sindicat.net/nomenaments/avui/');
my $res = $ua->request($req);

my @content = split(/\n+/,$res->content);
foreach my $line ( @content ) {
  if ( $line =~ m/(http:\/\/www\.sindicat\.net\/nomenaments\/avui\/\?data=([^"]+))/gi ) {
    my ($url,$date) = ($1,$2);
    my ($day,$month,$year) = $date =~ m/(\d+)\/(\d+)\/(\d+)/gi;
    if ( $day && $month && $year && ( $year < 2100 ) ) {
      print "$url\t$date\t$year,$month,$day\n";
      unless ( -e "files/$year-$month-$day.html" ) {
	system("curl $url -o files/$year-$month-$day.html");
      }
    }
  }
}
