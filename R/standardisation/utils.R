# General functions which don't fit elsewhere

FirstNonBlank <- function(v) v[v != ""][1]

TrimWS <- function(str) ifelse(is.null(str), str, gsub("^[[:space:]]+|[[:space:]]+$", "", str))


