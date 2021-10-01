Animal traits data processing
=============================

This directory contains the R code for transforming raw animal trait
observations into a standardised form, plus some functions for
reporting on and plotting the results.  Raw observations are recorded
in CSV files with a predefined set of columns.  Observations are read
in, checked for errors, converted to standard units, and written to a
single output CSV file.

To run the conversion, execute `analysis.R`.

R files for performing the standardisation are in the sub-directory `standardisation`.

Input and output directory and file names are defined in `standardisation/constants.R`.

The list of traits and units to be written to the output file is
defined in `standardisation/traits-config.R`. It also contains
conversion factors, eg. O2 consumption to Joules.

Whenever the database is re-generated, the database files
(`../output/observations.csv`, `../output/observations.xlsx` and
`../output/column-documentation.csv`) should be uploaded to the website at
https://github.com/animaltraits/animaltraits.github.io.
