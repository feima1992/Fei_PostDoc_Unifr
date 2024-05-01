
source("F:\\users\\Fei\\Code\\WFanalysis\\R\\FuncCollection.R")

# file path
filePath1 = "F:/users/Fei/DataAnalysis/Figures/ReachingGrasping/Rg_LimbMvt_ActProps_0.5.csv"
filePath2 = "F:/users/Fei/DataAnalysis/Figures/ReachingGrasping/Rg_LimbVib_ActProps_0.5.csv"

filePath3 = "F:/users/Fei/DataAnalysis/Figures/EnrichedCage/Enrich_LimbMvt_ActProps_0.5.csv"
filePath4 = "F:/users/Fei/DataAnalysis/Figures/EnrichedCage/Enrich_LimbVib_ActProps_0.5.csv"

# plot figs
FigureActPropsRgDevelop(filePath1,'Rg_limbMvt_Develop')
FigureActPropsRgDevelop(filePath2,'Rg_limbVib_Develop')

FigureActPropsRg(filePath1,'Rg_limbMvt')
FigureActPropsRg(filePath2,'Rg_limbVib')

FigureActPropsEnrich(filePath3,'Enrich_limbMvt')
FigureActPropsEnrich(filePath4,'Enrich_limbVib')