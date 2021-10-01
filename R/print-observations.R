# Script to help diagnose possible data problems by printing out the relevant observations and traits

source("standardisation/standardise.R", local = TRUE)
source("sociality.R", local = TRUE)

ShowObservations <- function(species) {
  obs <- ReadStandardisedObservations()
  traits <- TraitsFromObsAndSpecies(obs, groupOnSpeciesOnly = FALSE, socialityCsvs = SOCIALITY_CSVS)
  
  bo <- obs[obs$species == species,]
  cat(sprintf("Observations for species %s\n", species))
  print(as.data.frame(bo[, c("file", "line", "mass", "mass - units", "brain size", "brain size - units", "metabolic rate", "metabolic rate - units")]))

  cat(sprintf("Traits for species %s\n", species))
  bt <- traits[traits$species == species,]
  print(as.data.frame(bt[, c("mass", "mass - units", "brain size", "brain size - units", "metabolic rate", "metabolic rate - units", "sociality")]))
}

ShowObservations("Mephitis mephitis")
