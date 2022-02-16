# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

#install.packages("devtools")
#devtools::install_github("JimMcL/JUtils")
library(JUtils) # Simplifies plotting to files
source("AT-functions.R")
source("constants.R")


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
  
  cat(sprintf("Total of %d observations from %d sources.\n", nrow(obs), length(unique(obs$fullReference))))
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
  hasMass <- !is.na(obs$`body mass`)
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
  .dbgPlot("MR-mass dbg.png", "body mass", "metabolic rate")
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
  .dbgPlot("Brain-mass dbg.png", "body mass", "brain size")
  
  JPlotToPNG(file.path(OUTPUT_DIR, "MSMR-mass.png"), 
             PlotSpecificMRonMass(obs, legXInset = -.265, main = "Mass-specific Metabolic Rate on Mass", categoriesCol = "class"))
  .dbgPlot("MSMR-mass dbg.png", "body mass", "mass-specific metabolic rate")
}


######################################################################
# Publication figure

# Draw tick marks and labels for a logarithmic axis.
# 
# @param axis 1=below, 2=left, 3=above and 4=right.
drawLogTicks <- function(side, ticks, ...) {

  labels <- sapply(ticks, function(i) as.expression(bquote(10 ^ .(i))))
  axis(side, at = 10 ^ ticks, labels = labels, ...)
}

transparentColour <- function(colour, alpha) {
  c <- col2rgb(colour)
  rgb(c[1,], c[2,], c[3,], alpha, maxColorValue = 255)
}

.colourForCat <- function(categories, transparency = NA) {
  col <- CLASS_COLOURS[match(sub(" .*", "", categories), names(CLASS_COLOURS))]
  if (!is.na(transparency))
    col <- transparentColour(col, transparency)
  col
}

.plotObservations <- function(obs, xCol, yCol, categoriesCol = "Group", 
                              transparency = NA,
                              xTicks, yTicks, 
                              ...) {
  
  
  unitsColName <- function(col) paste(col, "- units")
  
  colToLab <- function(col) {
    units <- FirstNonBlank(obs[[unitsColName(col)]])
    sprintf("%s (%s)", JCapitalise(col), FirstNonBlank(obs[[unitsColName(col)]]))
  }
  
  # Get data to be plotted
  data <- obs[!is.na(obs[[xCol]]) & !is.na(obs[[yCol]]) & !is.na(obs[[categoriesCol]]), c(xCol, yCol, categoriesCol, "species")]
  
  categories <- as.factor(data[[categoriesCol]])
  # Colours
  col <- .colourForCat(categories)
  pt.col <- "#333333"
  
  plot(as.formula(paste0("`", yCol, "` ~ `", xCol, "`")), data = data,
       log = "xy", xlab = colToLab(xCol), ylab = colToLab(yCol),
       cex = 1.1, pch = 21, col = pt.col, bg = col,  
       axes = FALSE, ...)
  drawLogTicks(1, xTicks, lwd = 1)
  drawLogTicks(2, yTicks, lwd = 1)
}

# Draw the figure
.goFigure <- function(obs, arrowLength = 0.06) {
  
  
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

  layout(matrix(1:3, nrow = 1), widths = c(5, 5, 3))
  ### Metabolic rate to mass
  par(mar = c(5, 5.5, 1, 0) + .1, xpd = TRUE)
  .plotObservations(obs, "body mass", "metabolic rate", xTicks = seq(-8, 2, 2), yTicks = seq(-7, 3, 2),
                    ylim = c(10e-9, 10e2))
  
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
  mtext("a)", line = -1, adj = -0.23, font = 2, cex = 1)
  
  ### Brain size to mass
  .plotObservations(obs, "body mass", "brain size", xTicks = seq(-7, 3, 2), yTicks = seq(-8, 0, 2))
  .label(5, 1, 20, 1.2, "humans")
  .mulabel(80, .001, 70, .022, "ratites")
  .mulabel(.002, .00000002, .002, .00000038, "orb-web spiders")
  arrows(.002, .00000002, .0004, .00000019, length = arrowLength)
  arrows(.002, .00000002, .00011, .00000012, length = arrowLength)
  mtext("b)", line = -1, adj = -0.22, font = 2, cex = 1)

  plot.new()
  allClasses <- sort(unique(obs[[categoriesCol]]))
  legend <- sapply(allClasses, function(group) sprintf("%s (N=%d)", group, sum(obs$Group == group)))
  par(mar = c(4, 4, 2, 0))
  legend("left", legend,
         title = JCapitalise(categoriesCol), 
         pch = 21, col = "#333333", pt.bg = .colourForCat(legend), 
         inset = c(-0.3, 0),
         y.intersp = 1.2,
         xpd = TRUE)
}

CreatePublicationFigure <- function() {
  
  obs <- ReadStandardisedObservations()
  
  JPlotToPNG(file.path(OUTPUT_DIR, "fig1.png"), .goFigure(obs), units = "px", width = 1000, aspectRatio = 2.4, res = 130)
  JPlotToPDF(file.path(OUTPUT_DIR, "fig1.pdf"), .goFigure(obs, arrowLength = .04), width = 180, aspectRatio = 2.4, pointsize = 10)
}

######################################################################

# Figure for publication
CreatePublicationFigure()

cat("Trait summary:\n")
print(SummariseTraits())

#SummariseObservations() Not used?
