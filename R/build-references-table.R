# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

library(JUtils)
source("AT-functions.R")
source("constants.R")

# Extracts the references to be added to the manuscript 

obs <- ReadStandardisedObservations()

all <- unique(obs$fullReference)

FIRST_REFNUM <- 19

for (trait in c("Metabolic rate", "Mass", "Brain size")) {
  
  r <- unique(obs$fullReference[!is.na(obs[[TraitNames[trait]]])])
  nums <- match(r, all) + FIRST_REFNUM
  cat(sprintf("%s\n%s\n\n", trait, JToSentence(nums, sep = ", ", conjunction = ", ")))
}


refs <- data.frame(ID = seq_along(all) + FIRST_REFNUM, ref = all)
writeLines(sprintf("%d\t%s", refs$ID, refs$ref), "../refs.txt", useBytes = TRUE)
