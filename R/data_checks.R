# Data checks

library(taxize)

CheckMeasurementTypes <- function(data, knownTypes) {
  ReportLines(data[!(data$measurementType %in% knownTypes), ], "Unknown or invalid measurementType")
}

# Checks taxa in data against an external names database
CheckTaxa <- function(data, useCachedResults = TRUE, verbose = FALSE) {

  ranks <- c("phylum", "class", "order", "family", "genus", "species")
  
  orderTaxa <- function(taxa) {
    taxa[order(taxa$rank, taxa$name), ]
  }
  
  # Build a list of taxa (with ranks) to be checked
  toCheck <- data.frame(rank = character(), name = character(), stringsAsFactors = FALSE)
  for (rank in ranks) {
    # Note that data is a tibble, hence weird [[]] syntax to select a column
    toCheck <- rbind(toCheck, data.frame(rank = rank, name = as.character(unique(data[[rank]])), stringsAsFactors = FALSE), stringsAsFactors = FALSE)
   
    # Report missing taxon names
    missing <- is.na(data[[rank]]) | data[[rank]] == ""
    if (any(missing)) {
      ReportLines(data[missing, ], sprintf("Missing value for %s", rank))
    }
  }
  
  # Get the list of previously checked taxa
  if (useCachedResults && file.exists(CHECKED_TAXA_FILE)) {
    allChecked <- read.csv(CHECKED_TAXA_FILE, stringsAsFactors = FALSE)
    # Only need to check taxa which haven't been checked before
    # To throw out names which aren't referenced any more, set all.x = T rather than all = T
    allChecked <- merge(toCheck, allChecked, all.x = TRUE)
    uncheckedIdx <- is.na(allChecked$status)
    toCheck <- allChecked[uncheckedIdx, ]
    preChecked <- allChecked[!uncheckedIdx, ]
  } else {
    preChecked <- data.frame()
  }

  # Checks that a name resolves to the expected rank, e.g. that "Acanthizidae"
  # is a family. Not vectorised - name must have length == 1. This function is
  # very conservative (i.e. accepting)) because values in "resolved" are
  # extremely inconsistent
  checkRankIsCorrect <- function(name, rank, resolved) {
    # Work out which rows in resolved apply to name
    idxs <- which(startsWith(tolower(resolved$matched_name), tolower(name)) &
                    !endsWith(resolved$classification_path_ranks, "|") &
                    resolved$classification_path_ranks != "")
    # resolved$classification_path_ranks  contains a "|" separated list of ranks
    # - the last one in the list is the rank of the name
    resolvedRanks <- sapply(resolved$classification_path_ranks[idxs], strsplit, "\\|")
    resolvedRanks <- unlist(sapply(resolvedRanks, function(v) v[length(v)]))

    # Be conservative: allow it if there are no ranks reported, and accept any
    # resolution with correct rank (not just the best)
    good <- length(resolvedRanks) == 0 || 
      (length(resolvedRanks) == 1 && resolvedRanks == "") ||
      "unranked clade" %in% resolvedRanks || 
      "unranked" %in% resolvedRanks || 
      tolower(rank) %in% tolower(resolvedRanks)
    if (!good) {
      cat(sprintf("Bad %s '%s':\n\t%s\n\tMatch types %s\n", name, rank,
                  paste(unique(tolower(resolvedRanks)), collapse = ", "),
                  paste(unique(resolved$match_type[idxs]), colapse = ", ")))
    }
    good
  } 
  
  # Checks whether each of the rows in toCheck was resolved correctly, i.e. it
  # is known and has the correct rank. Returns vector of reasons for failure, ""
  # if valid
  wasResolvedCorrectly <- function(toCheck, resolved) {
    unknown <- attr(resolved, "not_known")
    
    sapply(1:nrow(toCheck), function(i) {
      # Fails if it's in the unknown list,
      # or if it's known but has the wrong rank
      name <- toCheck[i, "name"]
      rank <- toCheck[i, "rank"]
      if (name %in% unknown) {
        return(sprintf("Unknown taxon %s (expected to be a %s)", name, rank))
      } else if (!checkRankIsCorrect(name, rank, resolved)) {
        return(sprintf("%s is known but is not ranked as a %s", name, rank))
      }
      return("")
    })
  }
  
  # Check one rank at a time
  for (rank in unique(toCheck$rank)) {
    taxa <- as.character(toCheck[toCheck$rank == rank, "name"])
    # Query in blocks of limited size, since gnr_resolve seems to not return once queries get too big
    MAX_PER_QUERY <- 200
    
    for (block in 1:ceiling(length(taxa) / MAX_PER_QUERY)) {
      start <- 1 + (block - 1) * MAX_PER_QUERY
      end <- min(length(taxa), block * MAX_PER_QUERY)
      if (verbose)
        cat(sprintf("Querying for %d-%d of %d %s names\n", start, end, length(taxa), rank))
      resolved <- gnr_resolve(taxa[start:end], fields = "all")
      
      # Fill in status column based on result of query
      failureReasons <- wasResolvedCorrectly(toCheck[toCheck$rank == rank, ][start:end, ], resolved)
      toCheck[toCheck$rank == rank, "status"][start:end] <- ifelse(failureReasons == "", "valid", "invalid")
      toCheck[toCheck$rank == rank, "reason"][start:end] <- failureReasons
      toCheck[toCheck$rank == rank, "checkedAt"][start:end] <- format(Sys.time())
    }
  }
  
  # Combine with previously checked taxa
  allChecked <- orderTaxa(rbind(preChecked, toCheck, stringsAsFactors = FALSE))
  
  # Save to cache
  write.csv(allChecked, file = CHECKED_TAXA_FILE, row.names = FALSE)

  # Report bad taxa
  for (i in which(allChecked$status == "invalid")) {
    rank <- allChecked[i, ]$rank
    name <- allChecked[i, ]$name
    reason <- allChecked[i, ]$reason
    ReportLines(data[data[[rank]] == name, ], sprintf("Invalid %s '%s': %s", rank, name, reason))
  }
  
  # Special case - check for order "Primate"
  ReportLines(data[data[["order"]] == "Primate", ], "Invalid order 'Primate': should be 'Primates'")
}

# Checks for species which have the same name but different higher taxa
CheckTaxaMismatches <- function(obs) {
  traits <- SpeciesTraitsFromObservations(obs)
  # Find duplicate species names
  dups <- table(traits$species)
  dups <- dups[dups > 1]
  
  for (sp in names(dups)) {
    rows <- traits[traits$species == sp, ]
    .colDiffers <- function(col) length(unique(rows[[col]])) > 1
    
    diffCols <- Filter(.colDiffers, RANK_COLS)
    ReportLines(obs[obs$species == sp, ],
                sprintf("Species %s differ in %s (%s)",
                        sp, paste(diffCols, collapse = ", "),
                        paste(rows[, diffCols], collapse = ", ")))
  }
}

CheckReferences <- function(data) {
  # Check 1 reference per raw file
  nrefs <- setNames(
    aggregate(data$inTextReference, list(data$file), function(x) length(unique(x))),
    c("citation", "nrefs"))
  if (any(nrefs$nrefs != 1)) {
    bad <- which(data$file %in% nrefs$file[nrefs$nrefs > 1])
    ReportLines(data[bad, ], "Multiple references in 1 raw file (or inTextReference is not unique)")
  }
  
  bad <- is.na(data$inTextReference) | data$inTextReference == ""
  ReportLines(data[bad, ], "Missing or invalid inTextReference")
}

# Draws scatter plots (in output/QA) for each class with labels at very high
# resolution, with points that might need checking highlighted.
CheckValueOutliers <- function(obs, outDir, reportTraits = "brain size", reportClasses = "") {
  
  # reportClasses <- "Insecta"

  # For each trait to be checked...
  for (trait in c("brain size", "metabolic rate")) {
    
    # For each class...
    for (cl in unique(obs$class)) {
      
      cobs <- na.omit(obs[obs$class == cl, c("mass", trait, "species", "order", "observationID", "file", "line")])
      if (nrow(cobs) > 1) {
        JPlotToPNG(file.path(outDir, sprintf("%s-%s.png", trait, cl)), {
          par(mar = c(8, 8, 6, 1))
          DebuggingPlot(cobs, "mass", trait, main = cl, cex.main = 10, cex.axis = 6, cex.lab = 10)
          
          # Draw linear regression of log/log values
          df <- data.frame(x = log(cobs$mass), y = log(cobs[[trait]]))
          l <- lm(y ~ x, data = df)
          xs <- seq(min(cobs$mass), max(cobs$mass), length.out = 200)
          ys <- exp(predict(l, newdata = data.frame(x = log(xs))))
          lines(xs, ys)
          
          # Identify points that warrant a closer look
          dubious <- cooks.distance(l) > 4 / nrow(cobs)
          points(cobs[dubious, c("mass", trait)], pch = "*", col = "red", cex = 10)
          if (trait %in% reportTraits && cl %in% reportClasses) {
            for (di in which(dubious)) {
              cat(sprintf("%s %s too %s, species %s, line %d, file %s\n",
                            cl, trait, ifelse(l$residuals[di] > 0, "large", "small"),
                            cobs$species[di], cobs$line[di], cobs$file[di]))
                            
            }
          }
        },
        width = 3000, height = 2000)
      }
    }
  }
}

# Detects species which are so highly variable that they are suspicious. Uses 2
# tests: either coefficient of variation is > 0.8, or the maximum trait value
# within the species is >= 0.8 * minimum.
HighlyVariableSpecies <- function(obs, trait, minCV = 0.9, minFactor = 8) {
  df <- na.omit(obs[, c("species", trait)])
  
  .isBad <- function(sp) {
    x <- df[[trait]][df$species == sp]
    cv <- sd(x) / mean(x)
    factor <- max(x) / min(x)
    cv > minCV || factor > minFactor
  }
  
  Filter(.isBad, unique(df$species))
}

ReportHighlyVariableSpecies <- function(obs, traits = c("mass", "metabolic rate", "brain size")) {
  noProbs <- TRUE
  
  for (tr in traits) {
    unitsCol <- paste(tr, "- units")
    origVal <- paste("original", tr)
    origUnits <- sprintf("original %s - units", tr)
    trComments <- paste(tr, "- comments")
    for (sp in HighlyVariableSpecies(obs, tr)) {
      df <- na.omit(obs[obs$species == sp, c("species", tr, unitsCol, origVal, origUnits, trComments, "file", "line")])
      if (nrow(df) > 1) {
        # Allow values to be marked as checked and ok. Report if there are ANY rows which haven't been checked
        if (any(!grepl("DONTWARN", df[[trComments]]))) {
          print(as.data.frame(df[order(df[[tr]]), ]))
          noProbs <- FALSE
        }
      }
    }
  }
  
  if (noProbs) {
    cat("There were no unchecked outliers detected\n")
  }
}

# Compares the columns in the standardised data set with the columns documented in the documentation spreadsheet
CheckColumnDoco <- function(docFile = COLS_DOC_FILE) {
  doco <- read_excel(docFile)
  obs <- ReadStandardisedObservations()
  
  if (!isTRUE(all.equal(doco$Column, names(obs)))) {
    msg <- "Columns in the generated database do not match the documented columns"
    stop(msg)
  }
}
