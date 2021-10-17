# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Functions to aid in working with the AnimalTraits database

library(tibble)


# Returns the first non-empty element in a vector
FirstNonBlank <- function(v) v[v != ""][1]

#' Reads in the standardised observations, and returns them as a tibble (i.e. a
#' slightly altered data frame).
#'
#' This function is mainly a wrapper around \code{read.csv} with some important
#' defaults, in particular the encoding is \code{UTF-8}.
#'
#' @param fileName Name of the CSV file to read. Defaults to "observations.csv".
#' @param dataDir Location of observations CSV file. Defaults to the current
#'   directory.
#' @param adjustColumnNames If TRUE, column names will be converted to names
#'   that are syntactically valid R variable names. This makes the data frame
#'   easier to manipulate, but makes ugly names.
ReadStandardisedObservations <- function(fileName = "observations.csv", adjustColumnNames = FALSE) {

  # For internal use, allow file to be located in ../output
  altFilename <- file.path(OUTPUT_DIR, fileName)
  if (!file.exists(fileName) && file.exists(altFilename))
    fileName <- altFilename
  
  # WARNING! Don't use read_csv because it seems to read numbers incorrectly!
  # Values for mass which are in scientific notation are not read properly - the
  # exponent is ignored! Note that this seems to have been fixed as of 2.0.1. I
  # will keep using read.csv in case someone has an old version of readr
  # installed
  as_tibble(read.csv(file = fileName, 
                     encoding = "UTF-8",
                     stringsAsFactors = FALSE, 
                     check.names = adjustColumnNames))
}

#' Given standardised observations, groups them to species-level traits. This is
#' done by grouping observations into species, then taking the mean trait value
#' (after accounting for sample size).
#'
#' @param obs Data frame (or tibble) of standardised observations (see
#'   \code{ReadStandardisedObservations}).
#' @param combineSexes If TRUE (the default), the value in the \code{sex} column
#'   is ignored when grouping.
#' @param excludeMorphospecies If TRUE (the default), morphospecies (e.g.
#'   "Lycosa sp.") are excluded from the dataset before aggregation.
#' @param aggregationFn Function used to convert multiple trait values for a
#'   single species into one value. Defaults to \code{mean}.
#' @param groupOnSpeciesOnly If TRUE, only species name is used for aggregation.
#'   This is useful when different sources disagree on higher taxa (e.g. family)
#'   for a species.
#'
#' @seealso \code{\link{ReadStandardisedObservations}}
#'
#' @examples 
#' obs <- ReadStandardisedObservations()
#' traits <- SpeciesTraitsFromObservations(obs)
#' 
SpeciesTraitsFromObservations <- function(obs, combineSexes = TRUE, excludeMorphospecies = TRUE, aggregationFn = mean, groupOnSpeciesOnly = FALSE) {
  # Expand out to 1 observation sample per row
  idx <- rep(1:nrow(obs), obs$sampleSizeValue)
  xobs <- obs[idx, ]
  
  # Optionally exclude morphospecies, i.e. "Genus sp" or "Genus sp.1"
  if (excludeMorphospecies) {
    morpho <- grepl("^sp\\.?[[:digit:][:blank:]]*$|^spp\\..*", xobs$specificEpithet, ignore.case = TRUE)
    xobs <- xobs[!morpho, ]
  }
  
  # Ignore all "original" columns
  colNames <- grep("^original", names(obs), invert = TRUE, value = TRUE)

  # We need to exclude any columns which contain observation specific values
  # (other than the actual traits)
  obsCols <- c("observationID", "sampleSizeValue", "modified", "reference", "file", "line", 
               SOURCE_COLS,
               grep(" - method$| - comments$| - metadata comment$", names(obs), value = TRUE),
               grep("^original", names(obs), value = TRUE))
  if (combineSexes) {
    obsCols <- c(obsCols, "sex")
  }
  
  # Allow column names to be adjusted or not (i.e. are non-valid name characters replaced with "."?)
  unitsCols <- grep(" - units$|...units$", colNames, value = TRUE)
  # Fill in all units (all values of a trait are in the same units)
  for (uc in unitsCols) {
    xobs[[uc]] <- FirstNonBlank(xobs[[uc]])
  }
  
  # Work out columns to group on, and which are trait columns
  groupingCols <- c(META_COLS, unitsCols)
  # NOW remove all observation specific columns
  groupingCols <- groupingCols[!groupingCols %in% obsCols]
  if (groupOnSpeciesOnly) {
    # Hack to work around bad data - allow data to be aggregated ignoring higher
    # taxa, because sometimes e.g. family names differ for the same species
    groupingCols <- groupingCols[!groupingCols %in% RANK_COLS | groupingCols == "species"]
  }
  traitCols <- colNames[!colNames %in% c(groupingCols, obsCols)]
  
  # Create a formula to specify grouping and summarised variables. The formula
  # interface allows NAs in grouping variables. The LHS specifies columns to be
  # aggregated (i.e. trait values), while the RHS specifies the grouping columns
  # (i.e. columns that identify a species or group). This code is complicated by
  # the need to add back ticks to handle spaces in column names,
  f <- as.formula(paste("cbind(", paste0("`", traitCols, "`", collapse = ", "), ")", 
                        "~", 
                        paste0("`", groupingCols, "`", collapse = " + ")))
  
  aggregate(f, xobs, FUN = aggregationFn, na.rm = TRUE, na.action = na.pass)
}

