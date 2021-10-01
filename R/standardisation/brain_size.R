# ==== Brain size functions ====================================

deriveBrainSizeFromObservation <- function(rawRows, desiredUnits, conversions, colName, unitsColName) {
  # Get brain size measurement
  measurementType <- "brain size"
  rawRow <- measurementRow(rawRows, measurementType)
  bs <- extractMeasurementFromObservation(rawRow, measurementType)
  if (is.null(bs))
    return(BuildTraitRow(NULL, colName, unitsColName, NULL))
  
  # Convert from volume to mass or from mass to volume, as requested and required
  wantMass <- unitsContainType(desiredUnits, "numerator", "g")
  haveMass <- numeratorIndicatesMass(units(bs))
  wantVolume <- unitsContainType(desiredUnits, "numerator", "L")
  haveVolume <- numeratorIndicatesVolume(units(bs))
  
  # Check requested and supplied units
  if (!wantMass && !wantVolume)
    stop(sprintf("Brain size units must be either mass or volume, (%s requested)", desiredUnits))
  if (!haveMass && !haveVolume) {
    ReportLines(rawRows, "Brain size units are neither volume nor mass")
    return(BuildTraitRow(NULL, colName, unitsColName, NULL))
  }
  
  # Conversion required?
  if (wantMass != haveMass) {
    # Convert volume to mass. Get brain density
    brainDensity <- conversions$density[["brain"]]
    if (is.null(brainDensity))
      stop("Missing density for converting between brain volume and mass")
    if (wantMass) {
      # Convert from volume to mass
      bs <- bs * brainDensity
    } else {
      # Convert from mass to volume
      bs <- bs / brainDensity
    }
  }

  # Convert to desired output units
  bs <- set_units(bs, desiredUnits, mode = "standard")

  # Return 1-row data frame with standardised + preserved original values  
  BuildTraitRow(bs, colName, unitsColName, rawRow)
}

