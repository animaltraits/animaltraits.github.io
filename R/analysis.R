#!Rscript

# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Converts trait data in "raw" format into a single, unnormalised CSV file, in
# the "output" directory. The output traits and units, and the conversions to be
# applied, are defined in the file traits-config.R. 
#
# Also runs various error checks and quality control measures. 
# 
# The compiled database is written to the ../output directory, and also to 



library(readxl) # For checking the documentation
library(xlsx) # For exporting to Excel

#install.packages("devtools")
#devtools::install_github("JimMcL/JUtils")
library(JUtils) # Simplifies plotting to files

source("standardisation/standardise.R")
source("constants.R")
source("AT-functions.R") # For reading in the database
source("data_checks.R")
source("plot_observations.R") # For error detection plots


# Conversions should be defined in config files

# Export the observations, together with the column documentation, into an Excel spreadsheet
ExportToExcel <- function(obs = ReadStandardisedObservations(),
                          docFile = COLS_DOC_FILE,
                          filename = file.path(OUTPUT_DIR, "observations.xlsx"),
                          outDocFile = file.path(OUTPUT_DIR, COLS_DOC_CSV_FILE)) {
  write.xlsx2(as.data.frame(obs), filename, "Observations", row.names = FALSE, showNA = FALSE)
  doco <- read_excel(docFile)
  write.xlsx2(as.data.frame(doco), filename, "Column descriptions", append = TRUE, row.names = FALSE, showNA = FALSE)
  
  # Also write the column documentation to a CSV file
  write.csv(as.data.frame(doco), outDocFile, row.names = FALSE, na = "")
}

CopyFilesToWebsite <- function(files = c(file.path(OUTPUT_DIR, "observations.csv"),
                                         file.path(OUTPUT_DIR, "observations.xlsx"),
                                         file.path(OUTPUT_DIR, COLS_DOC_CSV_FILE)),
                               websiteDir = "../docs") {
  copied <- file.copy(files, websiteDir, overwrite = TRUE)
  if (any(!copied)) {
    stop(sprintf("Copy failed: %s to %s\n", JToSentence(files[!copied]), websiteDir))
  }
}


# Treat any warnings as errors
options(warn = 2)
# Read in raw data, and convert to standard units etc. then write to another CSV
dirOrFile <- commandArgs(TRUE)
source("standardisation/traits-config.R") # Defines traits_list and CONVERSIONS
# Output is to a CSV file
cat("Compiling and standardising observations...\n")
# NOTE that obs here includes debugging columns, but they are NOT written to the output database
obs <- StandardiseObservations(dirOrFile, traits_list, checkTaxa = TRUE)

# Checks that the columns in the generated database exactly match the columns that are documented
CheckColumnDoco()

# QA - generate reports to aid in manual checking for errors in the data 
QA_DIR <- file.path(OUTPUT_DIR, "QA")

# Generate plots for checking values. Possible dubious values can optionally be
# reported to the console by specifying reportTraits and reportClasses.
CheckValueOutliers(obs, QA_DIR, reportTraits = "", reportClasses = "")

# Report on suspiciously high within-species variation
JReportToFile(file.path(QA_DIR, "suspicious-variation.txt"), {
  cat("This file contains species whose variation in a trait value is suspiciously large.\n")
  cat("This can indicate a data problem, although it may not.\n")
  cat("\n")
  
  ReportHighlyVariableSpecies(obs)
})

cat("Exporting to Excel...\n")
ExportToExcel()
cat("Copying files to website folder...\n")
CopyFilesToWebsite()
