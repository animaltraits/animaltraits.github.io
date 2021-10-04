library(JUtils)
source("AT-functions.R")

# Extracts the references to be added to the manuscript 

obs <- ReadStandardisedObservations()

all <- unique(obs$fullReference)

FIRST_REFNUM <- 17

for (trait in c("Metabolic rate", "Mass", "Brain size")) {
  
  r <- unique(obs$fullReference[!is.na(obs[[TraitNames[trait]]])])
  nums <- match(r, all) + FIRST_REFNUM
  cat(sprintf("%s\n%s\n\n", trait, JToSentence(nums, sep = ", ", conjunction = ", ")))
}


refs <- data.frame(ID = seq_along(all) + FIRST_REFNUM, ref = all)
writeLines(sprintf("%d\t%s", refs$ID, refs$ref), "../refs.txt", useBytes = TRUE)
