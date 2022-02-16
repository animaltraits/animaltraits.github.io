# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Defines traits and conversions used for standardising raw observations

# Various metabolic rate conversions as used in Makarieva (2008)
CONVERSIONS <- c()

# Oxygen consumption to Joules
CONVERSIONS$O2ToJoules <- set_units(20, "J/ml")

# Q10 for standardising metabolic rate temperature of endotherms
CONVERSIONS$Q10 <- c(fish = 1.65, Amphibia = 2.21, Reptilia = 2.44, Cephalopoda = 2.5, other = 2)

# Note that respiratory quotient, for converting between volume of CO2
# production and O2 consumption, is not defined in here, because it depends on
# the metabolism in question, so there is no suitable single value. We only
# perform the conversion if the data source defines the appropriate respiratory
# quotient, and it has been recorded in the raw data file

# General conversions
# Molar mass for converting from moles to mass
CONVERSIONS$molarMass <- list(CO2 = as_units(44.01, "g/mol"))

# Density at STP
CONVERSIONS$density <- list(CO2 = as_units(1.977, "kg/m^3"), 
                            # Brain density from Iwaniuk, A. N., & Nelson, J. E.
                            # (2002). Can endocranial volume be used as an
                            # estimate of brain size in birds? Canadian Journal
                            # of Zoology, 80, 16–23. Also Stephan H, Frahm H,
                            # Baron G: New and Revised Data on Volumes of Brain
                            # Structures in Insectivores and Primates. Folia
                            # Primatol 1981;35:1-29. doi: 10.1159/000155963
                            brain = as_units(1.036, "g/mL"))


# File which specifies what traits should be read from the raw data, and
# included in the observations.csv file, and how they should be standardised
traits_list <- list(
  list("body mass", units = "kg"),
  list("metabolic rate", units = "W", temperature = 25, conversions = CONVERSIONS),
  list("mass-specific metabolic rate", units = "W/kg", temperature = 25, conversions = CONVERSIONS),
  list("brain size", units = "kg", conversions = CONVERSIONS) # Brain size can be either mass or volume as desired
)
