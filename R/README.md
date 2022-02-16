# AnimalTraits data processing

This directory contains the R (https://www.r-project.org/) code for transforming raw animal trait
observations into a standardised form, plus some functions for
reporting on and plotting the results.  Raw observations are recorded
in CSV files with a predefined set of columns.  Observations are read
in, checked for errors, converted to standard units, and written to a
CSV file and a spreadsheet. 

To run the conversion, execute the R script [`analysis.R`](analysis.R).

The list of traits and units to be written to the output file is
defined in [`standardisation/traits-config.R`](standardisation/traits-config.R). It also contains
conversion parameters, eg. O2 consumption to Joules. You can edit the file if you wish to re-generate the database with different units or conversion parameters. For example, to generate the database with brain sizes in grams, edit [`standardisation/traits-config.R`](standardisation/traits-config.R) and change `list("brain size", units = "kg"` to `list("brain size", units = "g"`, then execute [`analysis.R`](analysis.R). Read the comments in the script for further information.

To generate the figures for the publication, execute [`figures-and-stats.R`](figures-and-stats.R).

R files for performing the standardisation are in the sub-directory [`standardisation`](standardisation).

Input and output directory and file names are defined in [`standardisation/constants.R`](standardisation/constants.R).


The file [`AnimalTraits.Rproj`](AnimalTraits.Rproj) is an Rstudio project file.

The scripts use a number of external packages. Most can be installed from [`The Comprehensive R Archive Network (CRAN)`](https://cran.r-project.org/). The [`JUtils`](https://github.com/JimMcL/JUtils) package is only available from GitHub; refer to its [`README`](https://github.com/JimMcL/JUtils) for installation instructions.


## Utility functions

The file [`AT-functions.R`](AT-functions.R) contains 2 functions that may be useful to users of the database who are using `R`. Feel free to download the script to include in your own projects. The functions are:

| Function | Description |
| -------- | ----------- |
| `ReadStandardisedObservations` | Reads the observations database from a CSV file. Enforces the correct encoding. |
| `SpeciesTraitsFromObservations` | Given a dataframe of observations, aggregates them into species-level traits. |

Both functions are documented within the source file.
