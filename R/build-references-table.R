# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

library(JUtils)
source("AT-functions.R")
source("constants.R")

# Extracts the references to be added to the manuscript 


# First get all observations
obs <- ReadStandardisedObservations()

all <- unique(obs$fullReference)


# Now we need to work out what the reference number is in the endnote reference
# document endnoterefs.docx.

# endnoterefs.txt is a text file created as follows: 
# Create new word document (endnoterefs.docx), select all references in endnote
# library, insert selected references into word doc, use Nature output style,
# then save as text (UTF-8).
# First check that the text file is newer than the Word doc
textInfo <- file.info("../endnoterefs.txt")
docInfo <- file.info("../endnoterefs.docx")
if (textInfo$mtime < docInfo$mtime)
  warning("Text version of endnoterefs.doc is older than Word version: references may be incorrect")

endnoteRefs <- readLines("../endnoterefs.txt", encoding = "UTF-8")
# Skip lines without a tab
endnoteRefs <- endnoteRefs[grep("\\t", endnoteRefs)]
endnoteRefs <- tolower(endnoteRefs)
# Extract reference numbers from endnoteRefs
refNums <- as.numeric(sub("\t.*", "", endnoteRefs))
titles <- sub("^[^)]*[0-9][a-f]?)\\. ", "", all) # Remove authors
# This is tricky - Nature referencing doesn't include the title of book chapters, so use the book title
titles <- sub("^.* In: .*editors. ", "", titles)

titles <- sub("\\. .*$", "", titles)
titles <- sub("\\? [^?]*$", "", titles)
titles <- tolower(titles)

# Returns the index of the Endnote reference that best matches the specified title
refIdx <- sapply(titles, grep, endnoteRefs, fixed = TRUE)



# Lots of error checking
if (!is.numeric(refIdx)) {
  missing <- which(sapply(refIdx, length) == 0)
  dups <- which(sapply(refIdx, length) > 1)
  intro <- "There seem to be references in the database that are either missing or duplicated in the Endnote document.\n"
  missingD <- ""
  if (length(missing) > 0)
    missingD <- sprintf("Missing:\n    %s", JToSentence(names(refIdx)[missing], sep = "\n    ", conjunction = "\n    "))
  dupsD <- ""
  if (length(dups) > 0)
    dupsD <- sprintf("Duplicated:\n    %s", JToSentence(names(refIdx)[dups], sep = "\n    ", conjunction = "\n    "))
  msg <- sprintf("%s%s%s", intro, missingD, dupsD)
  stop(msg)
}
# Check for duplicates
t <- table(refIdx)
for (dup in as.numeric(names(t[t > 1]))) {
  dups <- which(refIdx %in% dup)
  intro <- "There seem to be multiple references in the database that match the same document in Endnote\n"
  dupsD <- sprintf("Duplicated:\n    %s\n", JToSentence(names(refIdx)[dups], sep = "\n    ", conjunction = "\n    "))
  matchD <- sprintf("Matched reference:\n    %s\n", endnoteRefs[dup])
  msg <- sprintf("%s%s%s", intro, dupsD, matchD)
  warning(msg)
}
if (sum(t > 1) > 0) stop("Stopping due to duplicates")
# Now refIdx is index from all into refNums



for (trait in c("Metabolic rate", "Body mass", "Brain size")) {

  r <- unique(obs$fullReference[!is.na(obs[[TraitNames[trait]]])])
  nums <- match(r, all)
  # nums tells us the index of the reference in "all". We need to map that to a reference number.
  # use refIdx as an index into refNums
  refs <- refNums[refIdx[nums]]
  # Sort them to make them pretty
  refs <- sort(refs)
  # Sanity check
  if (any(duplicated(refs))) stop(sprintf("Duplicate reference numbers in %s", trait))
  cat(sprintf("%s references\n%s\n\n", trait, JToSentence(refs, sep = ", ", conjunction = ", ")))
}


