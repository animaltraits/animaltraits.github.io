# AnimalTraits data processing

This directory contains the R code for transforming raw animal trait
observations into a standardised form, plus some functions for
reporting on and plotting the results.  Raw observations are recorded
in CSV files with a predefined set of columns.  Observations are read
in, checked for errors, converted to standard units, and written to a
CSV file and a spreadsheet.

To run the conversion, execute [`analysis.R`](analysis.R).

To generate the figures for the puyblication, execute [`figures-and-stats.R.R`](figures-and-stats.R).

R files for performing the standardisation are in the sub-directory [`standardisation`](standardisation).

Input and output directory and file names are defined in [`standardisation/constants.R`](standardisation/constants.R).

The list of traits and units to be written to the output file is
defined in [`standardisation/traits-config.R`](standardisation/traits-config.R). It also contains
conversion factors, eg. O2 consumption to Joules. You can edit this file if you wish to re-generate the database with different units or conversion factors. For example, to generate the database with brain sizes in grams, edit [`standardisation/traits-config.R`](standardisation/traits-config.R) and change `list("brain size", units = "kg"` to `list("brain size", units = "g"`, then execute [`analysis.R`](analysis.R).

The file [`AnimalTraits.Rproj`](AnimalTraits.Rproj) is a Rstudio project file.


## Utility functions

The file [`AT-functions.R`](AT-functions.R) contains 2 functions that may be useful to users of the database who are using `R`. Feel free to download the script to include in your own projects. The functions are:

| Function | Description |
| -------- | ----------- |
| `ReadStandardisedObservations` | Reads the observations database from a CSV file. Enforces the correct encoding. |
| `SpeciesTraitsFromObservations` | Given a dataframe of observations, aggregates them into species-level traits. |

Both functions are documented within the source file.
