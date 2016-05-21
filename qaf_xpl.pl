#!/usr/bin/perl

use strict;

use DBI;
use Statistics::Descriptive;

my $especialitat = shift @ARGV;
my $yearmonth = shift @ARGV;

my $year = 0;
my $month = 0;
my $nmonth = 0;
my $nyear = 0;

if ( $yearmonth ) {
  ($year,$month) = $yearmonth =~ m/(\d\d\d\d)(\d\d)/;
  if ( $month < 12 ) {
    $nmonth = sprintf("%02d",$month+1);
    $nyear = $year;
  } else {
    $nmonth = "01";
    $nyear = sprintf("%d",$year+1);
  }
}

my $dbfilename = "qaf.db";

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfilename","","",{AutoCommit => 0});


my $srv = $dbh->prepare("SELECT * FROM serveis");
$srv->execute();
my $names = {};
while ( my $st = $srv->fetchrow_hashref() ) {
  my $query = "SELECT * FROM nomenaments WHERE centre IN (SELECT id FROM centres WHERE servei = (SELECT id FROM serveis WHERE st=?));";
  if ( $year && $month ) {
    $query = "SELECT * FROM nomenaments WHERE  nDate >= \"$year-$month-01\" AND nDate <= \"$nyear-$nmonth-01\" AND centre IN (SELECT id FROM centres WHERE servei = (SELECT id FROM serveis WHERE st=?));";
  }
  my $sth = $dbh->prepare($query);
  if ( $especialitat ) {
    $query = "SELECT * FROM nomenaments WHERE especialitat IN (SELECT id FROM especialitats WHERE codi=?) AND centre IN (SELECT id FROM centres WHERE servei = (SELECT id FROM serveis WHERE st=?));";
    if ( $year && $month ) {
      $query = "SELECT * FROM nomenaments WHERE nDate >= \"$year-$month-01\" AND nDate <= \"$nyear-$nmonth-01\" AND especialitat IN (SELECT id FROM especialitats WHERE codi=?) AND centre IN (SELECT id FROM centres WHERE servei = (SELECT id FROM serveis WHERE st=?));";
    }
    $sth = $dbh->prepare($query);
    $sth->execute($especialitat,$st->{st});
  } else {
    $sth->execute($st->{st});
  }
  $names->{$st->{st}} = $st->{name};
  print "$st->{st}\t$st->{name}\n";
  my $stat = Statistics::Descriptive::Full->new();
  my @data = ();
  while ( my $nom = $sth->fetchrow_hashref() ) {
    if ( $nom->{nordre} < 100000 ) {
      $stat->add_data($nom->{nordre});
      push(@data,$nom->{nordre});
    }
  }
  $sth->finish();
  my $hash = $stat->frequency_distribution_ref(10);
  dumpHash($hash,$st->{st});
}

plotHashes($names,$especialitat);

$dbh->disconnect();

sub plotHashes {
  my $names = shift;
  my $especialitat = shift;
  my @string = ();
  foreach my $key ( sort {$a <=> $b} keys %{$names} ) {
    push(@string,"\"dat/$key.dat\" title \"$names->{$key}\" with lines lw 10");
  }
  my $string = join(", ",@string);
  open(PLT,">dat/tmp.plt");
  print PLT <<EOF;
set xrange[000:100000]
set encoding iso_8859_1
set terminal postscript enhanced color
set output "histogram.eps"
set samples 10
set xlabel "Número d'ordre a la borsa"
set ylabel "Freqüència de Nomenaments"
set title "Freqüència nomenaments segons àrea territorial 2015/2016 ($especialitat)"
plot $string
EOF
  close(PLT);
  system("gnuplot dat/tmp.plt");
  system("convert -rotate 90 -flatten histogram.eps histogram.png");
}

sub dumpHash {
  my $hash = shift;
  my $st = shift;
  open(DAT,">dat/$st.dat");
  foreach my $key ( sort { $a <=> $b } %{$hash} ) {
    if ( $hash->{$key} ) {
      print DAT "$key\t$hash->{$key}\n";
    } else {
      print DAT "$key\t0.0\n";
    }
  }
  close(DAT);
}

