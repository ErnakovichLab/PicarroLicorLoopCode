

# Utilities that are common across all R scripts
# Column types in respiration spreadsheets

col_types_licor <- c(rep("text", 2), #SampleType:JarNumber
                    rep("numeric", 5), #RoomTemperature:ConcentrationOfStandard
                    "date", # Time last zeroed
                    rep("text", 3), # Comments, id, si.no
                    "date", # timestamp
                    rep("numeric", 4), # mean-pre:Est Conc
                    "text", # Remarks
                    rep("numeric", 10), #:effective volume of loop:True amount of CO2
                    "guess","guess", "guess")


col_types_picarro_ico2 <- c(rep("text", 2), #sampletype:jar number
                       rep("numeric", 14), #RoomTemperature:EffectiveIsotopicRatio
                       "date", #time last zeroed
                       rep("text", 1), # comments
                       "date", # Date
                       "text", # time of start of measurments
                       rep("numeric", 8), #Mean of pre-12CO2:MeanH2O%post 
                       "text", # Remarks 
                       rep("numeric", 23), # effective volume of loop:TrueDelta permil
                       rep("guess", 9)) # regression calculations


# To add: 
# col_types_picarro_ico2_ich4

# NA values for spreadsheets
na_vals = c("nan", "#VALUE!", "#DIV/0!")