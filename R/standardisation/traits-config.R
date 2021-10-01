# Defines traits and conversions used for standardising raw observations

# Various metabolic rate conversions as used in Makarieva (2008)
CONVERSIONS <- c()
# Oxygen consumption to Joules
CONVERSIONS$O2ToJoules <- set_units(20, "J/ml")
# Q10 for standardising metabolic rate temperature of endotherms
CONVERSIONS$Q10 <- c(fish = 1.65, Amphibia = 2.21, Reptilia = 2.44, Cephalopoda = 2.5, other = 2)
# Respiratory quotient, for converting volume of CO2 production or O2
# consumption. Applied to Dark respiration rates in green leaves (Table S10),
# Dark respiration rates in seedlings and saplings of vascular plants (Table
# S11), Endogenous respiration rates in heterotrophic prokaryotes (Table S1a)
#THIS IS NOT USED, JUST HERE FOR DOCUMENTATION 
#CONVERSIONS$respiratoryQuotient <- 1

# General conversions
# Molar mass for converting from moles to mass
CONVERSIONS$molarMass <- list(CO2 = as_units(44.01, "g/mol"))
# Density at STP
CONVERSIONS$density <- list(CO2 = as_units(1.977, "kg/m^3"), 
                            # Brain density from Iwaniuk, A. N., & Nelson, J. E.
                            # (2002). Can endocranial volume be used as an
                            # estimate of brain size in birds? Canadian Journal
                            # of Zoology, 80, 16–23.
                            # Also Stephan H, Frahm H, Baron G: New and Revised Data on Volumes of Brain Structures in Insectivores and Primates. Folia Primatol 1981;35:1-29. doi: 10.1159/000155963
                            brain = as_units(1.036, "g/mL"))


# File which specifies what traits should be read from the raw data, and
# included in the observations.csv file, and how they should be standardised
traits_list <- list(
  list("mass", units = "kg"),
  list("metabolic rate", units = "W", temperature = 25, conversions = CONVERSIONS),
  list("mass-specific metabolic rate", units = "W/kg", temperature = 25, conversions = CONVERSIONS),
  list("brain size", units = "g", conversions = CONVERSIONS) # Brain size can be either mass or volume as desired
)