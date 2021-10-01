This directory contains functions for converting raw observations from multiple CSV files into a single standardised CSV file.
The main function for standardising observations is StandardiseObservations in standardise.R.

Files:
standardise.R      - functions for standardising obervations
aggregation.R      - functions for converting standardised observations to species-level traits

traits-config.R    - defines output traits, units and conversions to be used when standardising raw traits
brain_size.R       - function for deriving a standardised brain size value from a raw observation
mass.R             - function for deriving a standardised mass value from a raw observation
metabolic_rate.R   - function for deriving a standardised metabolic rate value from a raw observation

constants.R        - set of common definitions: file and directory names, known trait names, raw data columns...
data_checks.R      - functions for performing various checks on raw data, such as ensuring taxa are known
raw_data.R         - functions for dealing with raw data - reading, unit conversion etc.
utils.R            - some general purpose utility functions
README.txt         - this file
