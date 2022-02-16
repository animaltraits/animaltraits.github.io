# AnimalTraits
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Functions for plotting observations 


COLOURS <- c("#e6194B", "#3cb44b", "#ffe119", "#4363d8", "#f58231", "#911eb4", "#42d4f4", "#f032e6", "#bfef45", "#fabebe", "#469990", "#e6beff", "#9A6324", "#fffac8", "#800000", "#aaffc3", "#808000", "#ffd8b1", "#000075", "#a9a9a9")

# Draw tick marks and labels for a logarithmic axis.
# 
# Prevent axes being drawn normally when plotting with `plot(... axes = FALSE)`.`
#
# @param axis 1=below, 2=left, 3=above and 4=right.
drawLogAxis <- function(side, axisData, labelTransformed = FALSE, maxTicks = 10000, ...) {
  rng <- log10(range(axisData))
  by <- 1
  ticks <- NULL
  # Make the axis slightly shorter than the data range so it all fits in
  start <- ceiling(rng[1])
  end <- floor(rng[2])
  while (is.null(ticks) || (end > start + 1 && length(ticks) > maxTicks)) {
    ticks <- seq(start, end, by = by)
    by <- by + 1
  }
  
  labels <- if (labelTransformed)
    as.character(ticks)
  else
    sapply(ticks, function(i) as.expression(bquote(10 ^ .(i))))
  axis(side, at = 10 ^ ticks, labels = labels, ...)
}

# Draw tick marks and labels for a logarithmic or normal axis.
# 
# Prevent axes being drawn normally when plotting with `code(... axes = FALSE)`.`
#
# @param axis 1=below, 2=left, 3=above and 4=right.
drawAxis <- function(side, axisData, logScale, labelTransformed = FALSE, maxTicks = 10000, ...) {
  if (logScale)
    drawLogAxis(side, axisData, labelTransformed = labelTransformed, maxTicks = maxTicks, ...)
  else
    axis(side = side)
}


PlotObservations <- function(obs, xCol, yCol, categoriesCol = "order", 
                             catColourFn = NULL,
                             ptOutlineCol = NULL,
                             speciesText = FALSE, adjustedColNames = FALSE, 
                             pch = NULL,
                             mar = c(5, 4, 2, 14) + .1, cex = 1.5, 
                             legend = TRUE, legPos = "topleft", legCex,
                             legXInset = -0.18, legYInset = 0,
                             legCats = NULL,
                             labelTransformed = TRUE, transparency = NA,
                             maxXTicks = 100, maxYTicks = 100, 
                             ...) {
  colourForCat <- function(categories) {
    if (!is.null(catColourFn))
      col <- catColourFn(categories)
    else {
      if (nlevels(categories) <= length(COLOURS))
        palette <- COLOURS
      else
        palette <- rainbow(nlevels(categories))
      col <- palette[as.numeric(categories)]
    }
    if (!is.na(transparency))
      col <- transparentColour(col, transparency)
    col
  }
  
  transparentColour <- function(colour, alpha) {
    c <- col2rgb(colour)
    rgb(c[1,], c[2,], c[3,], alpha, maxColorValue = 255)
  }
  unitsColName <- function(col) ifelse(adjustedColNames, paste0(col, "...units"), paste(col, "- units"))
  colToLab <- function(col, logAxis) {
    units <- FirstNonBlank(obs[[unitsColName(col)]])
    if (labelTransformed && logAxis) {
      bquote('log'[10] * '(' * .(JCapitalise(col)) ~ "in" ~ .(FirstNonBlank(obs[[unitsColName(col)]])) * ')')
    } else {
      if (length(units) > 0)
        sprintf("%s (%s)", JCapitalise(col), FirstNonBlank(obs[[unitsColName(col)]]))
      else
        JCapitalise(col)
    }
  }
  
  data <- obs[!is.na(obs[[xCol]]) & !is.na(obs[[yCol]]) & !is.na(obs[[categoriesCol]]), c(xCol, yCol, categoriesCol, "species")]
  
  categories <- as.factor(data[[categoriesCol]])
  # Colours
  col <- colourForCat(categories)
  pt.col <- if (is.null(ptOutlineCol)) col else ptOutlineCol
  # PCH
  plotPch <- if (is.null(pch)) {
      as.numeric(categories) %% 25
    } else {
      pch
    }
  # Log scale?
  NON_LOG_COLS <- "sociality"
  logx <- !xCol %in% NON_LOG_COLS
  logy <- !yCol %in% NON_LOG_COLS
  log <- paste0(ifelse(logx, "x", ""), ifelse(logy, "y", ""))
  # Labels
  xlab <- colToLab(xCol, logx)
  ylab <- colToLab(yCol, logy)

  par(mar = mar)
  plot(as.formula(paste0("`", yCol, "` ~ `", xCol, "`")), data = data,
       log = log, xlab = xlab, ylab = ylab, pch = plotPch, col = pt.col, bg = col, cex = cex, 
       cex.lab = cex, axes = FALSE, ...)
  drawAxis(1, data[[xCol]], logx, lwd = 2, cex.axis = cex, maxTicks = maxXTicks)
  drawAxis(2, data[[yCol]], logy, lwd = 2, cex.axis = cex, maxTicks = maxYTicks)
  
  if (speciesText) {
    tdata <- na.omit(data[, c(xCol, yCol, "species")])
    cat(sprintf(""))
    text(x = tdata[[xCol]], y = tdata[[yCol]], tdata$species, adj = 1.05, cex = .8)
  }
  if (legend) {
    if (is.null(legCats))
      legCats <- sort(unique(categories))
    if (is.null(pch)) {
      legPch <- as.numeric(legCats) %% 25
    } else {
      legPch <- pch
    }
    legCol <- colourForCat(legCats)
    leg.pt.col <- if (is.null(ptOutlineCol)) legCol else ptOutlineCol
    legend(legPos, legend = legCats, inset = c(legXInset, legYInset), 
           title = JCapitalise(categoriesCol), 
           pch = legPch, col = leg.pt.col, pt.bg = legCol,
           cex = if (missing(legCex)) cex else legCex, xpd = TRUE)
  }
}

DebuggingPlot <- function(obs, xCol, yCol, ...) {
  data <- na.omit(obs[, c(xCol, yCol, "species", "observationID")])
  # Extend x lower limit to make space for labels
  xlim <- range(data[[xCol]])
  xlim[1] <- xlim[1] / 10
  # as.name(xCol) causes an error in reformulate
  plot(reformulate(paste0("`", xCol, "`"), as.name(yCol)), data = data, log = "xy", pch = 16, xlim = xlim, ...)
  text(x = data[[xCol]], y = data[[yCol]], sprintf("%s (%s)", data$species, data$observationID), adj = 1.05, cex = .8)
}


PlotMRonMass <- function(obs, categoriesCol = "order", legend = TRUE, ...) {
  PlotObservations(obs, "body mass", "metabolic rate", categoriesCol = categoriesCol, legend = legend, ...)  
}

PlotSpecificMRonMass <- function(obs, categoriesCol = "order", legend = TRUE, ...) {
  PlotObservations(obs, "body mass", "mass-specific metabolic rate", categoriesCol = categoriesCol, legend = legend, ...)
}

PlotBrainSizeonMass <- function(obs, categoriesCol = "order", legend = TRUE, ...) {
  PlotObservations(obs, "body mass", "brain size", categoriesCol = categoriesCol, legend = legend, ...)  
}

PlotBrainSizeonMR <- function(obs, categoriesCol = "order", legend = TRUE, ...) {
  PlotObservations(obs, "metabolic rate", "brain size", categoriesCol = categoriesCol, legend = legend, ...)  
}
