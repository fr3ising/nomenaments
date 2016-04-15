#!/usr/bin/perl

use strict;

use DBI;
use HTML::Entities;

my $dbfilename = "qaf.db";

createDatabase($dbfilename);

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfilename","","",{AutoCommit => 0});
my @nomenaments = ();
print "Parsing files\n";
foreach my $file ( <files/*.html> ) {
  my @fileNoms = parseFile($file,$dbh);
  push(@nomenaments,@fileNoms);
}

print "Populating centres and especialitats\n";
my $centreInsert = $dbh->prepare("INSERT OR IGNORE INTO centres (nom,servei) VALUES (?,(SELECT id FROM serveis WHERE st=?));");
my $especialitatInsert = $dbh->prepare("INSERT OR IGNORE INTO especialitats (codi) VALUES (?);");
foreach my $nom ( @nomenaments ) {
  $centreInsert->execute($nom->{nomCentre},$nom->{servei});
  $centreInsert->finish();
  $especialitatInsert->execute($nom->{codi});
  $especialitatInsert->finish();
}

$dbh->commit();

my $centreQuery = $dbh->prepare("SELECT id FROM centres WHERE nom=?;");
my $especialitatQuery = $dbh->prepare("SELECT id FROM especialitats WHERE codi=?;");

my $nomenamentInsert = $dbh->prepare("
INSERT OR IGNORE INTO nomenaments (nordre,nDate,nStart,nEnd,
                                   jornada,centre,especialitat)
                 VALUES (?,?,?,?,?,?,?);
");

print "Populating main table\n";
foreach my $nom ( @nomenaments ) {
  $centreQuery->execute($nom->{nomCentre});
  my $ch = $centreQuery->fetchrow_hashref();
  $centreQuery->finish();
  $especialitatQuery->execute($nom->{codi});
  my $eh = $especialitatQuery->fetchrow_hashref();
  $especialitatQuery->finish();
  $nomenamentInsert->execute($nom->{nOrdre},
			     $nom->{nDate},
			     $nom->{nStart},
			     $nom->{nEnd},
			     $nom->{jornada},
			     $ch->{id},
			     $eh->{id});
  $nomenamentInsert->finish();
}

$dbh->commit();

$dbh->disconnect();

sub parseFile {
  my $filename = shift;
  my $dbh = shift;
  my @nomenaments = ();
  my $startText = "img src=\"../../disseny_n/linea vermella iac.jpg";
  my $endText = "</table>";
  open(HTML,"< :encoding(Latin1)",$filename);
  my @lines = <HTML>;
  close(HTML);
  my $parseFlag = 0;
  my $bufferFlag = 0;
  my $buffer = "";
  foreach my $line ( @lines ) {
    chomp($line);
    $line =~ s/\A\s+//gi;
    $line =~ s/\s+\Z//gi;
    $line =~ s/>\s+</></gi;
    if ( $line =~ m/$startText/ ) {
      $parseFlag = 1;
    }
    if ( $parseFlag ) {
      if ( $line =~ m/<tr>/ ) {
	$buffer = "";
	$bufferFlag = 1;
      }
      if ( $bufferFlag ) {
	$buffer .= "$line";
      }
      if ( $line =~ m/<\/tr>/ ) {
	$buffer .= "$line";
	my $nom = parseRow($buffer);
	if ( $nom->{nOrdre} =~ m/\d/gi && $nom->{nOrdre} > 0 ) {
	  push(@nomenaments,$nom);
	}
	$buffer = 0;
      }
    }
    if ( $line =~ m/$endText/ ) {
      last;
    }
  }
  @nomenaments;
}

sub insertNomenament {
  my $nom = shift;
  my $dbh = shift;
  if ( $nom->{nOrdre} !~ m/\d/ ) {
    return;
  }
  my $sth = $dbh->prepare("SELECT id FROM serveis WHERE st=?;");
  $sth->execute($nom->{servei});
  my $st = $sth->fetchrow_hashref();
  $sth = $dbh->prepare("INSERT OR IGNORE INTO centres (nom,servei) VALUES (?,?);");
  $sth->execute($nom->{nomCentre},$st->{id});
  $dbh->commit();
  my $sth = $dbh->prepare("SELECT id FROM centres WHERE nom=?;");
  $sth->execute($nom->{nomCentre});
  my $st = $sth->fetchrow_hashref();
  my $centreId = $st->{id};
  print "$centreId\n";
}

sub parseRow {
  my $row = shift;
  my @array = split(/<\/td><td>/,$row);
  $array[0] =~ s/.*>//gi;
  $array[-1] =~ s/<.*//gi;
  $array[3] =~ s/\A\s*\d*\s*//gi;
  $array[4] =~ s/,/./gi;
  $array[7] =~ s/-\Z//gi;
  my $nom = {
	     servei => $array[0],
	     nDate => convertDate($array[1]),
	     nOrdre => $array[2],
	     nomCentre => $array[3],
	     jornada => $array[4],
	     nStart => convertDate($array[5]),
	     nEnd => convertDate($array[6]),
	     codi => uc($array[7])
	    };
  $nom;
}

sub convertDate {
  my $src = shift;
  my ($day,$month,$year) = split(/\//,$src);
  if ( $year < 2000 ) {
    $year = "20$year";
  }
  my $out = sprintf("$year-%02d-%02d",$month,$day);
  if ( $month && $day ) {
    $out;
  } else {
    "";
  }
}

sub createDatabase {
  my $filename = shift;
  system("rm -rf $filename");
  my $dbh = DBI->connect("dbi:SQLite:dbname=$filename","","");

  my $especialitats = <<EOF;
CREATE TABLE especialitats
(
id INTEGER PRIMARY KEY AUTOINCREMENT,
codi TEXT NOT NULL UNIQUE,
name TEXT
);
EOF

  my $serveis = <<EOF;
CREATE TABLE serveis
(
id INTEGER PRIMARY KEY AUTOINCREMENT,
st INTEGER NOT NULL UNIQUE,
name TEXT
);
EOF

  my $centres = <<EOF;
CREATE TABLE centres
(
id INTEGER PRIMARY KEY AUTOINCREMENT,
nom TEXT NOT NULL UNIQUE,
servei INTEGER REFERENCES serveis(id)
);
EOF

  my $nomenaments = <<EOF;
CREATE TABLE nomenaments
(
id INTEGER PRIMARY KEY AUTOINCREMENT,
nordre INTEGER,
nDate TEXT,
nStart TEXT,
nEnd TEXT,
jornada REAL,
centre INTEGER REFERENCES centres(id),
especialitat INTEGER REFERENCES especialitats(id)
);
EOF
  $dbh->prepare($especialitats)->execute();
  $dbh->prepare($serveis)->execute();
  $dbh->prepare($centres)->execute();
  $dbh->prepare($nomenaments)->execute();
  my $hServ = {
	       1 => "Barcelona Consorci",
	       2 => "Barcelona Comarques",
	       3 => "Baix Llobregat",
	       4 => "Vallés Occidental",
	       5 => "Maresme Vallés Or.",
	       6 => "Catalunya Central",
	       17 => "Girona",
	       25 => "Lleida",
	       43 => "Tarragona",
	       44 => "Terres de l'Ebre"
	      };
  my $sth = $dbh->prepare("INSERT INTO serveis (st,name) VALUES (?,?);");
  foreach my $key ( sort {$a <=> $b} keys %{$hServ} ) {
    $sth->execute($key,$hServ->{$key});
  }
  $dbh->disconnect();
}
