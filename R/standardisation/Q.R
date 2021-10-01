traits <- read.csv("traits.csv")
l <- lm(brain.size ~ class * mass + sociality, data = traits)
summary(l)
# ?
anova(l)

PlotSocialityForGroup <- function(group, main) {
  l <- lm(log(brain.size) ~ log(mass), data = traits)
  slope <- coef(l)["log(mass)"]
  x <- traits$brain.size * traits$mass ^ -slope
  y <- traits$sociality
  plot(y ~ x, pch = 16, main = main, ylab = "Sociality")
}

PlotSocialityForGroup(traits[traits$phylum != "Chordata", ], "Invertebrates")
PlotSocialityForGroup(traits[traits$class == "Mammalia", ], "Mammals")
