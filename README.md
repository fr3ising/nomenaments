Scripts per construir una base de dades de nomenaments d'ensenyament
i exemple de representació gràfica d'un histograma de freqüències
de nomenaments per servei territorial i especialitat.

Com fer-lo servir:

git clone https://github.com/fr3ising/nomenaments.git

mkdir files
mkdir dat
perl download.pl
perl qaf_db.pl

La darrera comanda genera una base de dades sqlite anomenada qaf.db

perl qaf_xpl.pl [CODI ESPECIALITAT] <- Opcional

Aquesta comanda genera un fitxer histogram.png amb la distribució
de freqüències representada gràficament.

Dependències de:

- Statistics::Descriptive al CPAN
- Gnuplot
- DBI::SQlite
- curl
- LWP::UserAgent
- Imagemagick
