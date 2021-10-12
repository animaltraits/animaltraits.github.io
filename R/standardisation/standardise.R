# The animal traits database
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Functions to standardise trait observations

suppressMessages(library(udunits2, quietly = TRUE))
suppressMessages(library(units, quietly = TRUE))
library(tibble)
library(readr)


source("standardisation/mass.R")
source("standardisation/brain_size.R")
source("standardisation/metabolic_rate.R")
source("standardisation/raw_data.R")


################################################################
# Standardisation functions


.rowDifferences <- function(rows) {
  for (i in (seq(length.out = nrow(rows) - 1) + 1)) {
    r <- all.equal(rows[1, ], rows[i, ])
    if (!isTRUE(r)) {
      # Remove unwanted portion of message - rely on the syntax of the string returned from all.equal to not change
      return(sub(":.*", "", r))
    }
  }
  NULL  
}

# Remove blanks and NAs from a vector
.rmBlanks <- function(v) {
  v <- na.omit(v)
  v[v != ""]
}

# Calls a function once for each unique observation ID in the data
# @return A data frame with a row for each unique observationID and columns returned by calling \code{fun}.
iterateObservations <- function(data, fun, ...) {
  do.call(rbind, lapply(unique(data$observationID), function(obsId) {
    rows <- data[data$observationID == obsId, ]
    tryCatch(
      fun(rows, ...),
      # Stop on an error because we require a result for every observation
      error = function(e) StopOnLines(rows, e)
    )
  }))
}

extractAndStandardiseTraitsFromDirOrFile <- function(dirOrFile, traitsList, checkTaxa = TRUE, ignoreFiles = character(0)) {
  # Read in data
  data <- readDirOrFile(dirOrFile, ignoreFiles = ignoreFiles)
  
  # Check for any observed traits which aren't configured in the traits list
  obsTraits <- unique(data$measurementType)
  notConfigured <- !(obsTraits %in% sapply(traitsList, function(t) t[[1]]))
  if (any(notConfigured))
    message(sprintf("The following traits have been observed but are not configured for analysis: %s", paste(obsTraits[notConfigured], collapse = ",")))
  
  # Various data checks
  CheckMeasurementTypes(data, MEASUREMENT_TYPES)
  CheckReferences(data)
  if (checkTaxa)
    CheckTaxa(data)
  
  # Meta data for each observation: species etc
  meta <- do.call(rbind, lapply(unique(data$observationID), function(obsId) {
    obs <- data[data$observationID == obsId, ]
    # Check that meta columns are identical for all rows with the same observation ID
    # TODO For now, we accept a loose definition of an observation which allows sample size to vary,
    # but really should handle it differently somehow. Perhaps they are different observations
    checkCols <- META_COLS[META_COLS != "sampleSizeValue" & META_COLS != "line"]
    dif <- .rowDifferences(obs[, checkCols])
    if (!is.null(dif)) {
      msg <- sprintf("Data entry problem: metadata values are not consistent across rows with observationID %s, %s differs", obsId, dif)
      ReportLines(obs, msg)
    }
    # Meta columns are identical, so just take the first row
    obs[1, META_COLS]
  }))
  
  # Function to derive standardised trait values for all rows given a trait type
  deriveTrait <- function(traitSpec) {
    cat(sprintf("Standardising %s...\n", traitSpec[[1]]))
    # Switch based on trait type
    switch(traitSpec[[1]],
            # Mass
            mass =                           iterateObservations(data, deriveMassFromObservation, traitSpec$units, 'mass', 'mass - units'),
            # Metabolic rate (whole body)
            `metabolic rate` =               iterateObservations(data, deriveMetabolicRateFromObservation, traitSpec$units, traitSpec$temperature, traitSpec$conversions, 'metabolic rate', 'metabolic rate - units', addOriginalCols = TRUE),
            # Metabolic rate (mass-specific)
            `mass-specific metabolic rate` = iterateObservations(data, deriveMetabolicRateFromObservation, traitSpec$units, traitSpec$temperature, traitSpec$conversions, 'mass-specific metabolic rate', 'mass-specific metabolic rate - units', addOriginalCols = FALSE),
            # Brain size
            `brain size` =                   iterateObservations(data, deriveBrainSizeFromObservation, traitSpec$units, traitSpec$conversions, 'brain size', 'brain size - units'),
            
            stop(sprintf("An unknown trait '%s' has been configured", traitSpec[1]))
    )
  }
  
  # Standardise trait values.   
  # For each output trait specification, derive the trait values
  traits <- lapply(traitsList, deriveTrait)
  
  # Sanity check (i.e. check for processing bugs). All values of a trait observation should have exactly the same units
  invisible(sapply(traits, function(t) { 
    units <- unique(.rmBlanks(t[,2]))
    if (length(units) != 1) {
      stop(sprintf("Units standardisation failed for %s, got %s\n", colnames(t)[2], paste(sprintf("'%s'", units), collapse = ", ")))
    }
  }))
  
  # Combine meta columns and trait values
  allObs <- cbind(meta, do.call(cbind, traits))
  
  # Check for data problems - disagreements between ranks for the same species
  CheckTaxaMismatches(allObs)

  allObs
}


#' Reads in raw observations from one or more CSV files, checks and standardises
#' them, and writes the result to a single CSV file.
#'
#' @return The observations dataset, but including extra columns that can be
#'   used to trace observations back to their raw source data.
#'
#' @param rawDirOrFile Name of a CSV file or directory containing multiple CSV
#'   files. Each file must have the same columns.
#' @param traitsList List traits to be output, together with output units and
#'   optionally with conversion parameters.
#' @param outFile Name of the output CSV file to be written.
#' @param checkTaxa If TRUE, all taxon names are checked against an external
#'   database of taxon names. Names which are not found in the database are
#'   reported.
#' @param ignoreFiles List of files in the `rawDirOrFile` directory which should
#'   not be read.
StandardiseObservations <- function(rawDirOrFile = RAW_DATA_DIR, traitsList, 
                                    outFile = file.path(OUTPUT_DIR, OBS_FILE), 
                                    checkTaxa = TRUE, ignoreFiles = character(0)) {
  if (length(rawDirOrFile) == 0)
    rawDirOrFile <- RAW_DATA_DIR
  obs <- extractAndStandardiseTraitsFromDirOrFile(rawDirOrFile, traitsList, checkTaxa, ignoreFiles = ignoreFiles)
  
  outputDir <- dirname(outFile)
  if (!dir.exists(outputDir))
    dir.create(outputDir)
  
  # Reorder columns to put the internal (reference) columns last
  cols <- names(obs)
  refCols <- c("observationID", "file", "line", "modified")
  productionCols <- cols[!cols %in% refCols]
  debugCols <- c(productionCols, refCols)

  # Create a CSV file with 1 row / observation, each trait (and units) in columns
  write.csv(obs[, productionCols], outFile, na = "", row.names = FALSE, fileEncoding = "UTF-8")
  # This is faster but seems to crash R intermittently!
  #write_csv(obs[, productionCols], outFile, na = "")
  
  invisible(obs[, debugCols])
}

