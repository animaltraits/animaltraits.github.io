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
COLS_DOC_FILE <- "../data/database column definitions.xlsx"