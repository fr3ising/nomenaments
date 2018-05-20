Scripts per construir una base de dades de nomenaments d'ensenyament
i exemple de representació gràfica d'un histograma de freqüències
de nomenaments per servei territorial i especialitat.

# Dependències

Dependències de CPAN:
- Statistics::Descriptive
- DBI::SQlite
- LWP::UserAgent

Dependències externes:
- Gnuplot
- curl
- Imagemagick


# Com fer-lo servir:

## Obté el codi font

```
git clone https://github.com/fr3ising/nomenaments.git
```

## Instal·la les dependències

Del CPAN:

```
curl -LO http://xrl.us/cpanm
perl cpanm --installdeps .
```

Del sistema operatiu:

En sistemes Debian/Ubuntu:
```
sudo apt-get install curl imagemagick gnuplot
```

## Executa els scripts

```
mkdir files
mkdir dat
perl download.pl
perl qaf_db.pl
```

La darrera comanda genera una base de dades sqlite anomenada `qaf.db`.

```
perl qaf_xpl.pl [CODI ESPECIALITAT] # <- Opcional
```

Aquesta comanda genera un fitxer `histogram.png` amb la distribució
de freqüències representada gràficament.
