# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Some functions for dealing with raw data
suppressMessages(library(data.table))


NUMBER_REGEX <- "[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?"

# Converts a character vector to a numeric vector. The input may contain either
# numbers or numeric ranges of the form "<number>-<number>".
# Throws an error if the input contains values which can't be converted.
convertNumberOrRange <- function(v) {
  numberPattern <- paste0("^[[:space:]]*",
                          NUMBER_REGEX,
                          "[[:space:]]*$")
  rangePattern <- paste0("^[[:space:]]*(",
                         NUMBER_REGEX,
                         ")[[:space:]]*-[[:space:]]*(",
                         NUMBER_REGEX,
                         ")[[:space:]]*$")
  numberOrRangePattern <- paste0("(", numberPattern, "|", rangePattern, ")")
  if (!all(grepl(numberOrRangePattern, v))) {
    # This error message is an evil hack - it makes assumptions about what is being
    # converted and how values correspond to line numbers in the source file
    stop(sprintf("Invalid measurement values (not a number or a range) at line(s) %s", 
                 paste(which(!grepl(numberOrRangePattern, v)) + 1, collapse = ", ")))
  }
  
  extractRange <- function(vr) {
    # Extract a number from a part of a string, where the limits (start and stop
    # indices) of the number are identified by match data from a call to
    # regexec.
    # @param matchData Value returned by regexec
    # @param index Index of matched group within matchData
    # @param str String to extract the value from
    getGroup <- function(matchData, index, str) {
      as.numeric(substr(str, matchData[index], matchData[index] + attr(matchData, "match.length")[index] - 1))
    }
    
    m <- regexec(rangePattern, vr)
    sapply(1:length(m), function(i) {
      mean(c(getGroup(m[[i]], 2, vr[i]), getGroup(m[[i]], 4, vr[i])))
    })
  }
  
  # We can assume every value is either a simple number or a range
  ranges <- grepl(rangePattern, v)
  numbers <- !ranges
  x <- numeric(length(v))
  # Convert numbers
  x[numbers] <- type.convert(v[numbers])
  # Convert ranges
  x[ranges] <- extractRange(v[ranges])
  x
}

# Removes a byte-order mark from the first column name
fixByteOrderMark <- function(d) {
  col1 <- names(d)[1]
  
  # Reading in a BOM using UTF-8 encoding seems to add this text prefix to the first column name: 
  utf8Pre <- "X.U.FEFF."
  if (startsWith(col1, utf8Pre)) {
    d <- setnames(d, col1, substring(col1, nchar(utf8Pre) + 1))
  } else {
    # Handle binary BOM
    bytes <- charToRaw(col1)
    # Although this is not actually the BOM
    # (https://en.wikipedia.org/wiki/Byte_order_mark), it seems to be what fread
    # returns when it encounters a BOM
    BOM <- as.raw(c(0xef, 0x2e, 0x2e))
    if (all(sapply(seq_along(BOM), function(i) BOM[i] == bytes[i]))) {
      d <- setnames(d, col1, substring(col1, length(BOM) + 1))
    }
  }
  d
}

TrimWS <- function(str) ifelse(is.null(str), str, gsub("^[[:space:]]+|[[:space:]]+$", "", str))

# Copies the value from row 1, specified column, into all blank values of the column.
# This is so that source file values only need be entered once, in the first row.
fillSourceColumn <- function(data, column, file) {
  blanks <- which(data[[column]] == "" | is.na(data[[column]]))
  if (1 %in% blanks) {
    stop(sprintf("Missing source value %s in %s, row 1", column , file))
  }
  data[blanks, column] <- data[1, column]
  data
}

# Reads a single csv file of trait data, adjusting as appropriate:
# * observationID is prepended with the file name to make it unique across files.
# * Columns for file name and line number are added to aid in error reporting.
readRawDataFile <- function(file, rangeToMidRange = TRUE) {
  tryCatch({
    # fread now reads in CSV files with a BOM (or possibly due to *NIX line
    # endings) as a single column! data.table v1.12.8
    #d <- as_tibble(fread(file, fill = TRUE))
    # read.csv is slower but more reliable than fread
    d <- as_tibble(read.csv(file, encoding = "UTF-8"))
    
    # Handle stupid byte order mark. read.csv handles it internally, fread doesn't :(
    # It seems that read.csv no longer handles it!
    d <- fixByteOrderMark(d)
    
    # Check all columns are present. If not, treat it as a fatal error because otherwise errors will snowball
    cols <- names(d)
    optCols <- which(cols %in% OPTIONAL_COLS)
    if (length(optCols) > 0)
      cols <- cols[-optCols]
    if (!setequal(cols, REQUIRED_COLS)) {
      msg <- "Incorrect column names:"
      missing <- REQUIRED_COLS[!REQUIRED_COLS %in% cols]
      if (length(missing) > 0)
        msg <- sprintf("%s\n    Missing: %s", msg, paste(missing, collapse = ", "))
      extra <- cols[!cols %in% REQUIRED_COLS]
      if (length(extra) > 0)
        msg <- sprintf("%s\n    Present but not allowed: %s", msg, paste(extra, collapse = ", "))
      stop(msg)
    }
    
    # Tell each row what file and line it came from
    nr <- nrow(d)
    # d$file <- basename(file)
    d$file <- file
    d$line <- seq_len(nr) + 1 # + 1 is to allow for header line
    
    # Trim whitespace from measurement types and taxa columns
    for (col in c(RANK_COLS, "measurementType")) {
      if (col != "species") { # Haven't created species column yet
        d[[col]] <- unname(sapply(d[[col]], TrimWS))
      }
    }
    
    # Silently (?) omit lines with no measurementType
    d <- d[!is.na(d$measurementType) & d$measurementType != "", ]
    
    # Silently omit any rows with unknown genus
    d <- d[tolower(d$genus) != "genus" & tolower(d$genus) != "gen.", ]
    
    # Silently omit any rows with a non-empty ignore message
    if ("ignore" %in% names(d)) {
      d <- d[is.na(d$ignore) | is.null(d$ignore) | d$ignore == "", ]
      # Delete the column since 1) it's always empty, and 2) it's not in every file
      d$ignore <- NULL
    }
    
    # Silently assume that missing sample size are 1
    d$sampleSizeValue <- ifelse(is.na(d$sampleSizeValue), 1, d$sampleSizeValue)
    
    # Handle some unusual values. Start by trying to convert to a simple number
    values <- type.convert(d$measurementValue, as.is = TRUE)
    if (is.numeric(values)) {
      d$measurementValue <- values
    } else {
      d$measurementValue <- convertNumberOrRange(d$measurementValue)
    }
    
    # Report missing observation IDs
    if (any(is.na(d$observationID)))
      ReportLines(d[is.na(d$observationID), ], "Missing observationID")
    
    # Make observationID unique across files
    d$observationID <- paste(tools::file_path_sans_ext(basename(file)), d$observationID, sep = "::")
    
    # Add in a (non-Darwin core) species column by combining genus and specificEpithet
    d$species <- paste(d$genus, d$specificEpithet)
    
    # Record last modified time of the file for reporting purposes
    d$modified <- file.mtime(file)
    
    # Remove now obsolete reference column. It was in index into a list of references, now replaced by fullReference column
    d$reference <- NULL
    
    # Fill in data source values by copying from the first row
    for (col in SOURCE_COLS) {
      d <- fillSourceColumn(d, col, file)
    }
    
    d
  },
  error = function(e) stop(sprintf("\"%s\": %s", file, conditionMessage(e)), call. = FALSE)
  )
}

# If dirOrFile is a file, it is read and the result returned as a data frame
# (actually a "tibble"), otherwise is assumed to be a directory, and it is
# searched for all CSV files which are read, concatenated together, then
# returned.
#
# Files are read using the readRawDataFile function which adds some extra columns used
# for reporting and so on.
readDirOrFile <- function(dirOrFile, ignoreFiles = character(0)) {
  if (file_test("-f", dirOrFile))
    files <- dirOrFile
  else if (file_test("-d", dirOrFile))
    files <- list.files(dirOrFile, ".*\\.csv$", recursive = TRUE, full.names = TRUE)
  else
    stop(paste("No such file or directory: ", dirOrFile))
  
  # Remove ignored files from the list
  for (ignore in ignoreFiles)
    files <- files[!grepl(ignore, files, fixed = TRUE)]
  
  # Read them in
  # TODO allow handling of ranges in values to be configured. Currently just take midpoint
  data <- lapply(files, readRawDataFile)
  for (dd in data) {
    if (ncol(dd) != 24)
      stop(sprintf("Too %s columns in file %s: expected 25 got %d", 
                   ifelse(ncol(dd) > 25, "many", "few"), dd$file[1], ncol(dd)))
  }
  # Combine them into 1 data frame (actually a "tibble")
  data <- do.call(rbind, data)
  
  data
}


# Returns TRUE if the numerator (or denominator) of units contains a unit which
# can be converted to the reference type.
#
# @param units Units to be tested.
# @param numerator If "numerator" ("denominator"), the units which make up the
#   numerator (denominator) will be tested.
# @param refType Type to test against.
#
# @examples
# # Test if units for metabolic rate include mass in the denominator
# isMassSpecific <- unitsContainType(mrUnits, "denominator", "g")
#
# # Test if units represent volume
# isVolume <- unitsContainType(mrUnits, "numerator", "L")
# 
unitsContainType <- function(units, numerator_denominator, refType) {
  .littleRedCorvette <- function(from, to) {
    # Just a wrapper around udunits2::ud.are.convertible which crashes R if given a 0 length vector
    length(from) > 0 && length(to) > 0 && udunits2::ud.are.convertible(from, to)
  }
  # Look at the list of units in numerator or denominator as requested
  unitsList <- units(as_units(units))[[numerator_denominator]]
  # Check each unit individually, but also look at the list in its entirety, so that e.g. "m" "m" "m" is treated as a volume
  unitsList <- unique(c(unitsList, paste(unitsList, collapse = " ")))
  # Check whether any unit in the list can be converted to the reference type
  any(sapply(unitsList, .littleRedCorvette, refType))
}

# Returns TRUE if the specified units represent mass-specific metabolic rate
unitsIndicateMassSpecific <- function(units) {
  # Units represent mass-specific metabolic rate if the denominator contains a term for mass
  unitsContainType(units, "denominator", "g")
}

# Returns TRUE if some units in the numerator can be converted to litres
numeratorIndicatesVolume <- function(units) {
  # If something on the top can be converted to litres, it's volume
  unitsContainType(units, "numerator", "L")
}

# Returns TRUE if some units in the numerator can be converted to kg
numeratorIndicatesMass <- function(units) {
  # If something on the top can be converted to kg, it's mass
  unitsContainType(units, "numerator", "kg")
}

# Returns TRUE if some units in the numerator can be converted to moles
numeratorIndicatesAmount <- function(units) {
  # If something on the top can be converted to moles, it's an amount of substance
  unitsContainType(units, "numerator", "mol")
}

# Handles our extensions to unit specification strings, currently just
#
# "(S) u"
#
# Where "S" is substance (e.g. O2 or CO2) and "u" is units as understood by the
# units package.
# 
# Returns a list with components:
#  units - units instance
#  substance - string
extractUnits <- function(unitStr) {
  # Check for syntax "[(<substance>)] [x<factor>] <units>"
  m <- regexec("^([[:space:]]*\\((.*)\\)[[:space:]]*)?(x([-+0-9.eE]+)[[:space:]]*)?(.*)", unitStr)
  if (length(m) > 0) {
    m <- m[[1]]
    substance <- substr(unitStr, m[3], m[3] + attr(m, "match.length")[3] - 1)
    factr <- as.numeric(sub("^", "e", substr(unitStr, m[5], m[5] + attr(m, "match.length")[5] - 1), fixed = TRUE))
    units <- as_units(substr(unitStr, m[6], m[6] + attr(m, "match.length")[6] - 1))
    list(units = units, substance = substance, factor = factr)
  }
}

# Returns a vector of "file:line" or "file:(line-line)" strings.
LineSpecs <- function(rows, collapse = "\n\t") {
  .succinctLines <- function(nums) {
    if(length(nums) == 1)
      nums
    else
      sprintf("(%d-%d)", min(nums), max(nums))
  }
  agg <- aggregate(rows[, "line"], list(rows$file), .succinctLines)
  paste(agg[[1]], agg[[2]], sep = ":", collapse = collapse)
}

StopOnLines <- function(badLines, message, collapse = "\n\t") {
  if (nrow(badLines) > 0) {
    stop(paste(message, LineSpecs(badLines, collapse = collapse), sep = ": "), call. = FALSE)
  }
}

ReportLines <- function(badLines, message, collapse = "\n\t") {
  if (nrow(badLines) > 0) {
    message(paste(message, LineSpecs(badLines, collapse = collapse), "\n", sep = ":\n\t"))
  }
}

# Returns the subset of rows with the specified measurement type
measurementRow <- function(rows, measurementType) {
  rows[rows$measurementType == measurementType, ]
}

# Extract a single value, with units, from a single row
extractMeasurementFromObservation <- function(row, measurementType) {
  # Expect 0 or 1 values per type per observation
  if (nrow(row) > 1)
    stop(sprintf("Multiple %s measurements in one observation", measurementType))
  if (nrow(row) < 1)
    return(NULL)
  
  u <- extractUnits(row$measurementUnit)
  v <- set_units(row$measurementValue, u$units, mode = "standard")
  # We allow a factor with the units, eg. "(CO2) x6.4e-5 mm3".
  # Handle it by simply multiplying by the factor
  if (!is.na(u$factor) && u$factor != 0)
    v <- v * u$factor
  attr(v, "substance") <- u$substance
  
  v
}

# Extract a single value, with units, from the rows of an observation
extractMeasurementFromObservationRows <- function(rows, measurementType) {
  extractMeasurementFromObservation(measurementRow(rows, measurementType), measurementType)
}

# Extracts a measurement from an observation, and converts units using standard
# conversions (i.e. can only convert between units of the same type such as mass)
deriveMeasurementFromObservation <- function(row, measurementType, desiredUnits) {
  m <- extractMeasurementFromObservation(row, measurementType)
  
  # Convert to desired output units
  if (!is.null(m)) {
    m <- set_units(m, desiredUnits, mode = "standard")
  }
  
  m
}

# Returns a 1-row data frame with columns named colName and unitsColName, and
# values are the value from valueWithUnits and the units from valueWithUnits.
buildValueAndUnitsRow <- function(valueWithUnits, colName, unitsColName) {
  # Modified to return a 1-row data frame, 4/8/20, previously returned a vector
  # but that stopped working, presumably after R v4 upgrade
  if (is.null(valueWithUnits))
    v <- data.frame(NA, "")
  else
    v <- data.frame(drop_units(valueWithUnits), as.character(units(valueWithUnits)))
  names(v) <- c(colName, unitsColName)
  v
}

# Returns a single row data frame with the original trait values and units (i.e.
# as specified in the source document), but renamed appropriately, i.e. by prepending "original".
#
# @param ... Passed in to data.frame to allow custom columns to be preserved.
#   Values should never be NULL (but can be NA)
preserveOriginalValues <- function(row, valueColName, unitsColName, ...) {
  if (is.null(row) || nrow(row) == 0) {
    df <- data.frame(NA, "", ..., check.names = FALSE)
  } else {
    df <- data.frame(row$measurementValue, row$measurementUnit, ..., check.names = FALSE)
  }
  # Note that we carefully only change the first 2 column names
  data.table::setnames(df, c(1, 2), paste("original", c(valueColName, unitsColName)))
}

# Returns a single row data frame with the measurement method and comments,
# renamed for the measurement type. E.g. for brain size, "measurementMethod" =>
# "brain size - method", "comments" => "brain size => comments" and
# "metadataComment" => "brain size - comment"
preserveMethod <- function(colName, row) {
  if (is.null(row) || nrow(row) == 0) {
    df <- data.frame(NA, "", "")
  } else {
    df <- data.frame(row$measurementMethod, row$comments, row$metadataComment)
  }
  setnames(df, paste(colName, c("- method", "- comments", "- metadata comment")))

}

# Builds and returns a single-row data frame containing standardised trait value, method and preserved original values
BuildTraitRow <- function(val, colName, unitsColName, row, ...) {
  cbind(
    buildValueAndUnitsRow(val, colName, unitsColName),
    preserveMethod(colName, row),
    preserveOriginalValues(row, colName, unitsColName, ...)
  )
}


