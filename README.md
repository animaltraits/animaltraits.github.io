## Welcome to AnimalTraits

### AnimalTraits: a curated animal trait database for body mass, metabolic rate and brain size

[![DOI](https://zenodo.org/badge/401195184.svg)](https://zenodo.org/badge/latestdoi/401195184)

This is the AnimalTraits project. It contains two components: 

- The raw data and R scripts used to compile the database; 
- Source for the website. 

The database is described in the paper:

Herberstein, M. E. et al. 2021. AnimalTraits: a curated animal trait database for body mass, metabolic rate and brain size

The database can be downloaded from the [AnimalTraits website](https://animaltraits.org/).

#### Database compilation

To compile the database, trait observations were manually extracted from peer-reviewed publications. Observations were recorded in CSV files, which we term _raw_ files. The raw files are stored in a directory structure within the [`data`](data) directory.

Raw files are read by a set of R scripts that standardise the observations and compile the result into a single spreadsheet. The scripts are in the [`R`](R) directory (and its sub-directories). The output database is written to the `output` directory (which is not checked in to git). The compiled database is written to two files, UTF-8 encoded `observations.csv` and the Excel spreadsheet format `observations.xlsx`. In addition, the file `column-documentation.csv` is copied from the `data` directory into the `output` directory. The data content of the two `observations.*` files is equivalent, although the spreadsheet contains a second worksheet that contains the documentation from the `column-documentation.csv` file. To summarise, `observations.xlsx = observations.csv + column-documentation.csv`.

The database compilation process ends by copying the finished products from the `output` directory into the website `docs` directory, so they are available for download from the website. The downloadable files are [`docs/observations.csv`](docs/observations.csv), [`docs/observations.xlsx`](docs/observations.csv) and the documentation file [`docs/column-documentation.csv`](docs/column-documentation.csv).

#### Website

The website is intended to provide straightforward access to the compiled database. The website source is in the [`docs`](docs) directory, and the website is available at https://animaltraits.org/.

