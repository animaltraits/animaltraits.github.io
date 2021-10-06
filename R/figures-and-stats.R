# The animal traits database
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

#install.packages("devtools")
#devtools::install_github("JimMcL/JUtils")
library(JUtils) # Simplifies plotting to files


######################################################################
# Some descriptive stats


# Prints out a summary of the data
SummariseAvailableData <- function(obs, title) {
  cat(paste(title, "\n"))
  for (col in c("phylum", "class", "order", "family", "genus", "species")) {
    if (col %in% names(obs)) {
      u <- unique(obs[[col]])
      n <- length(u)
      cat(sprintf("%d %s", n, ifelse(n == 1, col, RANK_PLURALS[col])))
      if (n < 10)
        cat(sprintf(": %s", paste(u, collapse = ", ")))
      cat("\n")
    }
  }
}

SummariseTraits <- function() {
  obs <- ReadStandardisedObservations()
  
  .nonBlanks <- function(v) !is.na(v) & v != ""
  
  data.frame(#Trait = TraitNames,
    Units = sapply(TraitNames, function(tn) FirstNonBlank(obs[, paste(tn, "- units")])),
    `Observations` = sapply(TraitNames, function(tn) sum(.nonBlanks(obs[, tn]))),
    `Species` = sapply(TraitNames, function(tn) length(unique(obs$species[.nonBlanks(obs[, tn])]))),
    `Data sources` = sapply(TraitNames, function(tn) length(unique(obs$fullReference[.nonBlanks(obs[, tn])]))),
    check.names = FALSE
  )
}


SummariseObservations <- function() {
  obs <- ReadStandardisedObservations()
  
  cat(sprintf("Total of %d observations from %d sources.\n", nrow(obs), length(unique(obs$file))))
  SummariseAvailableData(obs, "All taxa:")
  
  cat("\n")  
  for (t in TraitNames) {
    d <- na.omit(obs[, c("species", t)])
    cat(sprintf("%d observations of %s across %d species\n", nrow(d), t, length(unique(d$species))))
  }
  nObsAll <- nrow(na.omit(obs[,TraitNames]))
  # Build list of species with each trait
  speciesForTraits <- sapply(TraitNames, function(t) c(unique(obs[!is.na(obs[[t]]), "species"])))
  cat(sprintf("%d observations and %d species have values for all traits (%s)\n", nObsAll, length(Reduce(intersect, speciesForTraits)), paste(TraitNames, collapse = ", ")))
  
  .summariseSubset <- function(name, subset) {
    cat(sprintf("%s: %d observations in %d species\n", name, sum(subset), nrow(unique(obs[subset, "species"]))))
  }  
  hasMass <- !is.na(obs$mass)
  hasMR <- !is.na(obs$`metabolic rate`) & !is.na(obs$`mass-specific metabolic rate`)
  hasBrain <- !is.na(obs$`brain size`)
  .summariseSubset("Mass and metabolic rate", hasMass & hasMR)
  .summariseSubset("Mass and brain size", hasMass & hasBrain)
  .summariseSubset("Mass, brain size & metabolic rate", hasMass & hasBrain & hasMR)
  
  # Plot all points with species and observation ids to a big file, to aid error detection
  .dbgPlot <- function(filename, xCol, yCol) {
    JPlotToPNG(file.path(OUTPUT_DIR, filename), {
      DebuggingPlot(obs, xCol, yCol)
    }, width = 6000, height = 4000)
  }
  
  # Modifications for ICA conference 2019
  colours <- c(Arachnida = "#e6194B", Aves = "#3cb44b", Chilopoda = "#ffe119", Insecta = "#4363d8", Malacostraca = "#f58231", Mammalia = "#911eb4", Reptilia = "#42d4f4", Gastropoda = "#f032e6", Clitellata = "#bfef45", Amphibia = "#fabebe", "#469990", "#e6beff", "#9A6324", "#fffac8", "#800000", "#aaffc3", "#808000", "#ffd8b1", "#000075", "#a9a9a9")
  # Reorder observations so that spiders are last hence show up on the plot
  obs <- obs[rev(order(obs$class)), ]
  
  
  JPlotToPNG(file.path(OUTPUT_DIR, "MR-mass.png"), 
             PlotMRonMass(obs, legPos = "bottomright", legXInset = -.28, legYInset = .2, legCex = 1.3,
                          #main = "Whole-body Metabolic Rate on Mass", cex.main = 2,
                          categoriesCol = "class", 
                          catColourFn = function(cats) {colours[match(cats, names(colours))]},
                          ptOutlineCol = "#333333",
                          mar = c(5, 5.5, 2, 10) + .1, pch = 21,
                          maxXTicks = 10, maxYTicks = 9,
                          labelTransformed = FALSE)
             , aspectRatio = 16 / 9, res = 120)
  .dbgPlot("MR-mass dbg.png", "mass", "metabolic rate")
  JPlotToPNG(file.path(OUTPUT_DIR, "Brain-mass.png"), 
             PlotBrainSizeonMass(obs, legPos = "bottomright", legXInset = -.28, legYInset = .2, legCex = 1.3,
                                 #main = "Brain size on Mass", 
                                 categoriesCol = "class", 
                                 catColourFn = function(cats) {colours[match(cats, names(colours))]},
                                 ptOutlineCol = "#333333",
                                 mar = c(5, 5.5, 2, 10) + .1, pch = 21,
                                 maxXTicks = 9, maxYTicks = 8,
                                 labelTransformed = FALSE)
             , aspectRatio = 16 / 9, res = 120)
  .dbgPlot("Brain-mass dbg.png", "mass", "brain size")
  
  JPlotToPNG(file.path(OUTPUT_DIR, "MSMR-mass.png"), 
             PlotSpecificMRonMass(obs, legXInset = -.265, main = "Mass-specific Metabolic Rate on Mass", categoriesCol = "class"))
  .dbgPlot("MSMR-mass dbg.png", "mass", "mass-specific metabolic rate")
}


######################################################################
# Publication figure

# Draw the figure
.goFigure <- function(obs, legXInset = -0.6, arrowLength = 0.1) {
  
  .colFn <- function(cats) {CLASS_COLOURS[match(sub(" .*", "", cats), names(CLASS_COLOURS))]}
  
  # Label with RHS arrow
  .label <- function(x0, y0, x1, y1, label, adj = c(1, 0.5), ...) {
    arrows(x0, y0, x1, y1, length = arrowLength)
    text(x0, y0, label, adj = adj, ...)
  }
  # Label with arrow from centre going up
  .mulabel <- function(x0, y0, x1, y1, label, ...) .label(x0, y0, x1, y1, label, adj = c(0.5, 1), ...)
  

  # Create a new column, category, which is class except for reptiles, when it is order because Reptilia is paraphyletic
  categoriesCol = "class"
  obs$Group <- ifelse(obs$class == "Reptilia", obs$order, obs$class)
  categoriesCol <- "Group"
  
  layout(matrix(1:2, nrow = 1), widths = c(4, 6))
  allClasses <- sort(unique(obs[[categoriesCol]]))
  PlotMRonMass(obs, 
               categoriesCol = categoriesCol, 
               catColourFn = .colFn,
               ptOutlineCol = "#333333",
               mar = c(5, 5.5, 1, 0) + .1, pch = 21,
               maxXTicks = 10, maxYTicks = 9,
               labelTransformed = FALSE, legend = FALSE)
  .mulabel(20, .06, 4, 1.6, "ant eaters")
  arrows(20, .06, 13, 3, length = arrowLength)
  arrows(20, .06, 30, 8, length = arrowLength)
  .label(.0003, .5, .0015, .5, "hummingbirds")
  .label(.008, 5, .04, 3.6, "woodpeckers")
  .label(.2, 50, 1.6, 20, "petrels, penguins & shags")
  .mulabel(.00006, 40e-8, .000015, 15e-7, "ticks")
  .mulabel(.05, 20e-5, .02, 60e-5, "tarantulas")
  .label(.000001, .00000006, .0000001, .0000001, "mites", adj = c(0, 0.5))
  arrows(.000001, .00000006, .00000003, .00000005, length = arrowLength)
  mtext("a)", line = -1, adj = -0.23, font = 2, cex = 1.5)
  
  legend <- sapply(allClasses, function(group) sprintf("%s (N=%d)", group, sum(obs$Group == group)))
  PlotBrainSizeonMass(obs, 
                      legPos = "right", legXInset = legXInset, legYInset = .2, legCex = 1.1, legCats = legend,
                      categoriesCol = categoriesCol, 
                      catColourFn = .colFn,
                      ptOutlineCol = "#333333",
                      mar = c(5, 5.5, 1, 12) + .1, pch = 21,
                      maxXTicks = 9, maxYTicks = 8,
                      labelTransformed = FALSE)
  .label(5, 1000, 20, 1200, "humans")
  .mulabel(80, 1, 70, 22, "ratites")
  .mulabel(.002, .00002, .002, .00038, "orb-web spiders")
  arrows(.002, .00002, .0004, .00019, length = arrowLength)
  arrows(.002, .00002, .00011, .00012, length = arrowLength)
  mtext("b)", line = -1, adj = -0.22, font = 2, cex = 1.5)
}

CreatePublicationFigure <- function() {
  
  obs <- ReadStandardisedObservations()
  
  JPlotToPNG(file.path(OUTPUT_DIR, "fig1.png"), .goFigure(obs), units = "px", width = 900, aspectRatio = 2.4)
  JPlotToPDF(file.path(OUTPUT_DIR, "fig1.pdf"), .goFigure(obs, legXInset = -.45, arrowLength = .04), aspectRatio = 2.4, pointsize = 5)
}

######################################################################

# Figure for publication
CreatePublicationFigure()

cat("Trait summary:\n")
print(SummariseTraits())

SummariseObservations()
