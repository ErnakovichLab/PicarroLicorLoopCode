# read in and clean sample metadata sheet for Soil ecology incubation

library(tidyverse)
library(readxl)
library(here)


# Incubation jar file path and columns:
inc_jar_fp <- "~/Downloads/26SEI_JarLabelingandLoadingSpreadsheet.xlsx"

inc_start_times <- "~/Downloads/GasMeasurementTracking_SEI26.xlsx"

# Read in Healy and ice cut data:
healy_jars_raw <- readxl::read_excel(path = inc_jar_fp, 
                                     sheet = "Healy Jar IDs", 
                                     range = cell_limits(c(3,1), c(NA,40)),
                                     na = c("", "NA"))
healy_jars <- healy_jars_raw %>%
  rename(SampleID = `Jar ID`,
         JarNumber = `Jar #`,
         RepNumber = `Rep #`) %>%
  mutate(across(JarNumber:`Specimen Cup Number`, ~ as.factor(.x)))


ice_cut_jars_raw <- readxl::read_excel(path = inc_jar_fp, 
                                     sheet = "Ice Cut Jar IDs",
                                     range = cell_limits(c(3,1), c(NA,40)), 
                                     na = c("", "NA"))
ice_cut_jars <- ice_cut_jars_raw %>%
  rename(SampleID = `Jar ID`,
         JarNumber = `Jar #`,
         RepNumber = `Rep #`
         ) %>%
  mutate(across(JarNumber:`Specimen Cup Number`, 
                ~ as.factor(.x)),
         `Mass of Soil and Specimen Cup(g Lab Scale)` = as.numeric(`Mass of Soil and Specimen Cup(g Lab Scale)`))

# read in flush times for pre-incubation start
preinc_start_IC_raw <- readxl::read_excel(path = inc_start_times, 
                                       sheet = c(1), skip =1, na = c("", "NA"))

preinc_start_H_raw <- readxl::read_excel(path = inc_start_times, 
                                          sheet = c(2), skip =1, na = c("", "NA"))

preinc_start_raw <- bind_rows(preinc_start_H_raw, preinc_start_IC_raw)

preinc_start <- preinc_start_raw %>% 
  mutate(`Gas Flush Time Ended` = as_datetime(as.POSIXct(`PreIncubation Started (Time after 1st N2 flush)` ,
                                                         format = "%m/%d/%Y %H:%M",
                                                         tz = "America/New_York"))) %>%
  # mutate(`Gas Flush Time Ended` = as_datetime(as.POSIXct(`Gas Flush Time Ended`, 
  #                                                        format = "%m/%d/%Y %H:%M",
  #                                                        tz = "America/New_York"))) %>%
  # filter(`Which Flush is this?` == "Pre-Inc Start") %>%
  # # Filter spilled jars where incubation start is different than flush
  # filter_out(`Jar ID` == 286 & !is.na(Notes)) %>% # Filter spilled jar; incubation start is different than flush
  # filter_out(`Jar ID` == 305 & !is.na(Notes)) %>% # Filter spilled jar; incubation start is different than flush
  # filter_out(`Jar ID` == 325 & !is.na(Notes)) %>% # Filter spilled jar; incubation start is different than flush
  # filter_out(`Jar ID` == 285 & !is.na(Notes)) %>% # Filter spilled jar; incubation start is different than flush
  select(`Jar ID`, `Gas Flush Time Ended`)

# Combine jar data into one dataframe 

all_jars <- bind_rows(healy_jars, ice_cut_jars) %>%
  # Remove any columns that are unnamed
  select(!matches("\\.\\.\\..{1,3}")) %>%
  # add in volume of jar depending on manufacturer
  # From "10DEC2025_Incubation_Jar_Volume_Calculation.xlsx"
  #ball <- 249.253
  #uline <- 250.29
  # Add in preincubation start times
  left_join(preinc_start, by = c("SampleID" = "Jar ID")) %>%
  rename(PreIncubationStart = `Gas Flush Time Ended`) %>%
  mutate(PreIncubationStart = as.character(PreIncubationStart)) %>%
  separate(SampleID, into = c("SiteAbbr", "GroupAbbr", "JarIDNum"), sep = "-", remove = F) %>%
  # Taken from the SoilEcologySampleWeights spreadsheet
  mutate(GSC_Perc = case_when(SiteAbbr == "H" & `Permafrost or Coalescence?` == "Coal" ~ (23.77 + 35.33)/2,
                              SiteAbbr == "H" & `Permafrost or Coalescence?` == "PF" ~ 35.33,
                              SiteAbbr == "IC" & `Permafrost or Coalescence?` == "Coal" ~ (33.53 + 50.72)/2,
                              SiteAbbr == "IC" & `Permafrost or Coalescence?` == "PF" ~ 33.53)) %>%
  mutate(MasonJarVolume = case_when(grepl("Ball", `Jar Manufacturer`) ~ 249.253,
                                    grepl("Uline", `Jar Manufacturer`) ~ 250.29)) %>%
  mutate(HeadspaceVolume = MasonJarVolume - `Mass of Buffer:`) # headspace volume = volume of jar - (mass of buffer / density of water); assumes buffer/soil mix is density = 1*
# What to do about spilled jars?? - assume mixture was well mixed according to maggie
# what to do about differences in specimen cup volumes? - maggie


# write out combinedd and qc'd metadata sheet. 

write_tsv(all_jars, file = "~/Downloads/26SEI_JarLabelingandLoadingSpreadsheet_all_jars.tsv")

# Iron-testing jars
iron_soil_weights <- all_jars %>% filter(JarNumber %in% c(1, 2, 89, 90, 177, 178, 281, 282)) %>%
  select(SampleID:JarNumber,  `Mass of Soil(g Lab Scale)`,  `Mass of Soil and Buffer (g Lab Scale)`, GSC_Perc) %>%
  mutate(g_dry_soil_per_g_wet_soil = GSC_Perc/100,
         soil_weight_dry_g_in_jar = `Mass of Soil(g Lab Scale)` * g_dry_soil_per_g_wet_soil,
         mass_of_buffer_and_soil_ice = `Mass of Soil and Buffer (g Lab Scale)` - soil_weight_dry_g_in_jar,
         soil_dry_weight_in_slurry_g_per_ml_slurry = soil_weight_dry_g_in_jar/mass_of_buffer_and_soil_ice, # assuming density of buffer and soil water is ~ 1g/ml
         soil_dry_weight_in_slurry_g_per_ul_slurry = soil_dry_weight_in_slurry_g_per_ml_slurry / 1000 # For convenience, convert also into dry weight per ul of slurry
         ) 

write_tsv(iron_soil_weights, file = "~/Downloads/iron_assay_jar_soil_weights.tsv")

