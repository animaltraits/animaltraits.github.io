# The animal traits database
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

source("standardisation/constants.R")

# Mapping from trait display names to column names
TraitNames <- c("Metabolic rate" = "metabolic rate",
                "Mass-specific metabolic rate" = "mass-specific metabolic rate",
                "Mass" = "mass",
                "Brain size" = "brain size")


# Colours keyed on class + reptile orders
CLASS_COLOURS <- c(Arachnida = "#e6194B", Aves = "#3cb44b", Chilopoda = "#ffe119", Insecta = "#4363d8", Malacostraca = "#f58231", Mammalia = "#911eb4", Reptilia = "#42d4f4", Gastropoda = "#f052e6", Clitellata = "#bfef45", Amphibia = "#fabebe", 
                   Crocodilia = "#42d4f4", Squamata = "#e6beff", Testudines = "#9A6324", # Reptile orders
                   "#469990", "#fffac8", "#800000", "#aaffc3", "#808000", "#ffd8b1", "#000075", "#a9a9a9")


# File that documents the database columns
COLS_DOC_FILE <- "../data/database-column-definitions.xlsx"
# CSV file that is created by reading the Excel file
COLS_DOC_CSV_FILE <- "column-documentation.csv"
