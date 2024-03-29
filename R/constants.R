# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


# Mapping from trait display names to column names
TraitNames <- c("Metabolic rate" = "metabolic rate",
                "Mass-specific metabolic rate" = "mass-specific metabolic rate",
                "Body mass" = "body mass",
                "Brain size" = "brain size")


# Colours keyed on class + reptile orders
CLASS_COLOURS <- c(Arachnida = "#e6194B", Aves = "#3cb44b", Chilopoda = "#ffe119", Insecta = "#4363d8", Malacostraca = "#f58231", Mammalia = "#911eb4", Reptilia = "#42d4f4", Gastropoda = "#f052e6", Clitellata = "#bfef45", Amphibia = "#fabebe", 
                   Crocodilia = "#42d4f4", Squamata = "#e6beff", Testudines = "#9A6324", # Reptile orders
                   "#469990", "#fffac8", "#800000", "#aaffc3", "#808000", "#ffd8b1", "#000075", "#a9a9a9")

# Location of data files, relative to project or shiny directory
DATA_DIR <- "../data"
RAW_DATA_DIR <- file.path(DATA_DIR, "raw")
OUTPUT_DIR <- "../output"

# Name of CSV containing standardised observations
OBS_FILE <- "observations.csv"

# Name of CSV file containing taxon names which have previously been checked against the name server.
# This is used to (significantly) speed up data checking
CHECKED_TAXA_FILE <- file.path(DATA_DIR, "checked-taxa.csv")

# Known measurement types. Any measurement type not in this list is reported as an error
MEASUREMENT_TYPES <- c("metabolic rate", "body mass", "brain size")

# List of column names which contain non-measurement/trait data
RANK_COLS <- c("phylum", "class", "order", "family", "genus", "species", "specificEpithet")
# Columns that identify data source
SOURCE_COLS <- c("inTextReference", "publicationYear", "fullReference")
META_COLS <- c("observationID", RANK_COLS, "sex", "sampleSizeValue", SOURCE_COLS, "file", "line", "modified")

# Required column names in required order. If the column names in a raw data file don't match, it will be reported as an error
REQUIRED_COLS <- c("observationID", 
                   "phylum", "class", "order", "family", "genus", "specificEpithet", 
                   "sex", "measurementType", "measurementValue", "measurementUnit", 
                   "temperature", "respiratoryQuotient", "sampleSizeValue", "comments", "measurementMethod", "metadataComment", 
                   SOURCE_COLS
)
# reference is an obsolete column
# ignore is optional within raw files but removed from the data
OPTIONAL_COLS <- c("reference", "ignore")


RANK_PLURALS <- c(phylum = "phyla", class = "classes", order = "orders", family = "families", genus = "genera", species = "species")


# File that documents the database columns
COLS_DOC_FILE <- "../data/database-column-definitions.xlsx"
# CSV file that is created by reading the Excel file
COLS_DOC_CSV_FILE <- "column-documentation.csv"
