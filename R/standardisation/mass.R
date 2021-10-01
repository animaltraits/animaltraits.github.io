# ==== Mass functions ====================================

deriveMassFromObservation <- function(rows, desiredUnits, colName, unitsColName) {
  row <- measurementRow(rows, "mass")
  m <- deriveMeasurementFromObservation(row, "mass", desiredUnits)
  # Construct a row with standardised values and preserved original values
  BuildTraitRow(m, colName, unitsColName, row)
}

