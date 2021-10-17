# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# ==== Metabolic rate functions ====================================

# Conversion of metabolic rate (q) from recorded temperature
# to specified temperature using Q10 method
ConvertQ10 <- function(newTemp, q10, q, recordedTemp) q * q10 ^ ((newTemp - recordedTemp) / 10)

# Choose a Q10 value from a conversions list. The conversions list should have a
# field named "Q10" which is itself a list, containing Q10 values named for the taxa they apply to.
# Eg. 
# conversions$Q10 <- c(other = 2, fish = 1.65, Amphibia = 2.21, Reptilia = 2.44, Cephalopoda = 2.5)
#
# The fallback taxon "other" is used if no others apply.
ChooseQ10 <- function(rawRow, conversions) {
  # Try to find a Q10 value which matches the taxon specified in rawRow
  available <- names(conversions$Q10)
  for (rank in c("phylum", "class", "order", "family", "genus")) {
    taxon <- rawRow[[1, rank]]
    if (taxon %in% available) {
      q10 <- conversions$Q10[taxon]
      # cat(sprintf("Got Q10, rank %s, %s, value %g\n", rank, taxon, q10))
      return(q10)
    }
  }
  if ("other" %in% available)
    return(conversions$Q10[["other"]])
  stop("No Q10 conversion available")
}

# Convert a volume (production or consumption) value to an energy value by
# applying the appropriate conversion factor(s).
# 
# Currently handles production of CO2 or consumption of O2.
ConsumptionToEnergy <- function(value, what, respiratoryQuotient, conversions) {
  
  # There are 2 possible ways to convert from CO2 production:
  # 1. using respiratoryQuotient defined in the raw data
  # 2. using direct conversion factor defined in code (conversions$CO2ToJoules)
  if (what == "CO2") {
    # Use respiratoryQuotient if it is defined
    if (!is.na(respiratoryQuotient)) {
      # Convert from production of CO2 to consumption of O2 using respiratory quotient
      value <- value / respiratoryQuotient
      what <- "O2"
    } else if (!is.null(conversions$CO2ToJoules)) {
      # COnvert directly from CO2 to energy
      value <- value * conversions$CO2ToJoules
    } else 
      stop("Unable to convert consumption of CO2 to metabolic rate, neither respiratory quotient nor conversion from CO2 production to energy use are defined")
  } 
  
  if (what == "O2")
    value <- value * conversions$O2ToJoules
  else if (what != "CO2") # CO2 has already been handled
    stop(sprintf("Unknown or missing substance (%s) for volume measurement", what))
  
  value
}

# Attempts to return TRUE if the specified taxonomic class needs to have
# metabolic rate temperature standardised, i.e. it is not endothermic.
needsMRTemperatureTransform <- function(clss) {
  # For now, just assume birds and mammals are endothermic. 
  # Of course, it's actually more complicated than that
  clss != "Aves" && clss != "Mammalia"
}

# Builds and returns a 1-row data frame with metabolic rate columns
buildMetabolicRateRow <- function(val, colName, unitsColName, row, addOriginalCols) {
  rq <- row$respiratoryQuotient
  if (is.null(rq)) rq <- NA
  t <- row$temperature
  if (is.null(t)) t <- NA
  if (addOriginalCols) {
    BuildTraitRow(val, colName, unitsColName, row, 
                  `original respiratoryQuotient` = rq,
                  `original temperature` = t)
  } else {
    # Don't add any original columns
    buildValueAndUnitsRow(val, colName, unitsColName)
  }
}

# Given a set of rows representing a single observation, attempts to
# extract/derive metabolic rate in the requested units and standardised to the
# specified temperature.
#
# Returns NULL if metabolic rate isn't defined, or cannot be derived.
deriveMetabolicRateFromObservation <- function(rawRows, desiredUnits, standardTemp, conversions, colName, unitsColName, addOriginalCols) {
  # Get raw value
  measurementType <- "metabolic rate"
  rawRow <- measurementRow(rawRows, measurementType)
  q <- extractMeasurementFromObservation(rawRow, measurementType)
  
  if (is.null(q))
    return(buildMetabolicRateRow(NULL, colName, unitsColName, NULL, addOriginalCols))
  # What is the substance that is being measured (e.g. CO2 or O2)?
  substance <- attr(q, "substance")

  # Is this metabolic rate mass-specific?
  haveMS <- unitsIndicateMassSpecific(units(q))
  # Get the mass for this observation
  mass <- extractMeasurementFromObservationRows(rawRows, "mass")
  
  # Function to convert from mass-specific metabolic rate to whole body if it's not already
  .requireWholeBodyMR <- function() {
    if (haveMS) {
      # Convert from mass-specific to whole body - multiply by mass.
      # We have to do this, because otherwise we end up with units such as g/g/s which is simplified to 1/s
      q <<- q * mass
      haveMS <<- FALSE
    }
  }
  
  # Is it an amount of substance, i.e. moles
  if (numeratorIndicatesAmount(units(q))) {
    # Convert from mass-specific to whole body - multiply by mass.
    # We have to do this, because otherwise we end up with units such as g/g/s which is simplified to 1/s
    .requireWholeBodyMR()
    
    # Get conversion from moles to mass, i.e. molar mass for the substance
    molarMass <- conversions$molarMass[[substance]]
    if (!is.null(molarMass)) {
      q <- q * molarMass
    }
  }
  
  # Is it a mass?
  if (numeratorIndicatesMass(units(q))) {
    # Convert from mass-specific to whole body - multiply by mass.
    # We have to do this, because otherwise we end up with units such as g/g/s which is simplified to 1/s
    .requireWholeBodyMR()

    # Get conversion from volume to mass, i.e. density for the substance
    density <- conversions$density[[substance]]
    if (!is.null(density)) {
      q <- q / density
    }
  }
  
  # Is it a volume?
  if (numeratorIndicatesVolume(units(q))) {
    # Require a substance to be specified so that we can convert to energy
    q <- ConsumptionToEnergy(q, substance, rawRow$respiratoryQuotient, conversions)
  }
  
  # Do we need to convert from or to mass-specific MR?
  wantMS <- unitsIndicateMassSpecific(desiredUnits)
  if (haveMS != wantMS) {
    if (is.null(mass)) {
      # Can't convert without mass. I don't think this needs to be reported
      #ReportLines(rawRows, "Cannot convert between mass-specific and whole body metabolic rate because mass is not available for observation")
      return(buildMetabolicRateRow(NULL, colName, unitsColName, NULL, addOriginalCols))
    }
    if (wantMS && !haveMS) {
      # Convert to mass-specific metabolic rate - divide by mass
      q <- q / mass
    } else if (!wantMS && haveMS) {
      # Convert from mass-specific to whole body - multiply by mass
      q <- q * mass
    }
  }
  
  # Convert to desired output units
  q <- set_units(q, desiredUnits, mode = "standard")
  
  # Convert to standard temperature
  if (needsMRTemperatureTransform(rawRow$class) && !is.null(standardTemp)) {
    if (is.na(rawRow$temperature))
      stop("Missing temperature for metabolic rate")
    if (rawRow$temperature != standardTemp)
      q <- ConvertQ10(standardTemp, ChooseQ10(rawRow, conversions), q, as.numeric(rawRow$temperature))
  }
  
  return(buildMetabolicRateRow(q, colName, unitsColName, rawRow, addOriginalCols))
}

