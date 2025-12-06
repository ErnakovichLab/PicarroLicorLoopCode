library(tidyverse)
library(ggrepel)
library(here)

#### User settings #############################################################
# This section contains settings for the user to edit. 
# File path to the measurments for the effective volume spreadsheet
resp_spreadsheet_fp <- "~/Downloads/Respiration Spreadsheet Template.xlsx"

# Data about where the effective volume measurments start
start_row <- 1 # row of dataframe where measurements start - does not include header rows (e.g. row 3 in spreadsheet = 2 in dataframe)
end_row <- 22 # row of dataframe where measurements end - does not include header rows (e.g. row 22 in spreadsheet = 20 in dataframe)
exclude_sampletypes <- c("mistake") # the value of "SampleType" column for samples you want to exclude from the analyses; 
# Note, any row without a value for "SampleType" will be removed

# Column types - probably don't need to edit these; ensures data is read in correctly
col_type_list = c(rep("text", 2), # SampleType:JarNumber
              rep("numeric", 5), # Room temperature : Concentration of standard gas (ppm)
              "text", # Time last zeroed
              rep("text", 3), # ID:Sl.No
              "text", # Timestamp
              rep("numeric", 4), # Mean-pre:`Est:Conc:`
              "text", # Remarks
              rep("numeric", 10), # Effective volume of loop:True amount of CO2(uMol)
              # note: depending whether you use google sheets or excel, or other editor, 
              # read_excel may interpret the number of columns as 29 or 30. 
              # if an error is thrown, simply remove one "guess" column to fix.
              "guess","guess", "guess") # regression calculation columns 

na_values_excel = c("nan", "#VALUE!", "#DIV/0!")

#### Effective Volume Calculation ##############################################
veff_estimation_raw <- readxl::read_excel(resp_spreadsheet_fp, 
                                          col_types = col_type_list, 
                                          na = na_values_excel
                                          )

veff_estimation <- veff_estimation_raw %>%
  # Clean and filter out unnessesary columns and rows
  slice(start_row:end_row) %>%
  filter(!(SampleType %in% exclude_sampletypes)) %>% # remove rows where mistakes were made
  select(`Volume of sample or standard (mL of gas measured)`,
         `Room Temperature (degC)`, `RoomPressure (hPa)`,
         `Concentration of Standard Curve Gas (ppm)`,
         Timestamp,
         `Mean-pre`, # CO2 concentration prior to injection, ppm
         `Mean-post`, # CO2 concentration after injection, ppm
         `Delta`, # difference between Mean-pre and Mean-post, ppm
         `Effective Volume of Loop (mL)`) %>%
  filter(!is.na(`Timestamp`)) %>%
  mutate(Timestamp = as.POSIXct(Timestamp)) %>%
  # Calculate the volume of the loop: Veff = Vstandard*(ConcentrationOfStandard - PostInjectionCO2Concentration) / PrePostCO2Difference
  mutate(Veff_numerator = `Volume of sample or standard (mL of gas measured)` *(`Concentration of Standard Curve Gas (ppm)` - `Mean-post`),
         Veff_denominator = `Delta`,
         Veff = Veff_numerator/Veff_denominator,
         Vcal = `Volume of sample or standard (mL of gas measured)`) %>%
  mutate(SampleNumber = row_number())

#### Quality Control of Volume Calculation #####################################
# Use the plots in this section to perform quality control on your data.
# Are there any patterns in estimates related to injection time, sample volume, 
# room pressure, or room temperature?
# 
jitter_settings <- position_jitter(width = 0.4, height = 0, seed = 123)
ggplot(veff_estimation, 
       aes(y = Veff, x = SampleNumber)) +
  geom_point(position = jitter_settings) +
  geom_text_repel(aes(label = SampleNumber), position = jitter_settings) +
  ylab("Effective Volume of Loop (mL)") + xlab("Sample Injection Order") +
  theme_bw()
 
ggplot(veff_estimation, 
       aes(y = Veff, x = Vcal)) +
  geom_point() +
  geom_text_repel(aes(label = SampleNumber)) +
  ylab("Effective Volume of Loop (mL)") + xlab("Sample volume (mL)") +
  theme_bw()


ggplot(veff_estimation, 
       aes(y = Veff, x = `RoomPressure (hPa)`)) +
  geom_point() +
  geom_text_repel(aes(label = SampleNumber)) +
  ylab("Effective Volume of Loop (mL)") + xlab("Room Pressure (hPa)") +
  theme_bw()

ggplot(veff_estimation, 
       aes(y = Veff, x = `Room Temperature (degC)`)) +
  geom_point() +
  geom_text_repel(aes(label = SampleNumber)) +
  ylab("Effective Volume of Loop (mL)") + xlab("Room Temperature (degC)") +
  theme_bw()

# Any outliers?
# We will use Z-score detection to identify them; see https://statsandr.com/blog/outliers-detection-in-r/ for 
# good summary of why/how this is done
veff_estimation$z_Veff <-scale(veff_estimation$Veff)
outlier_sample_numbers <- which(!dplyr::between(veff_estimation$z_Veff, left = -3.29, right = 3.29))

#### Choose samples to drop, if any #####################################
# On the basis of your exploration above, are there any samples you'd like to drop
# from the analysis?

samples_to_drop <- c(outlier_sample_numbers) # We choose which samples we want to drop, if any

veff_estimation_filt <- veff_estimation %>%
  filter(!(SampleNumber %in% samples_to_drop))



### Veff range and statistics
veff_stats <- veff_estimation_filt %>% 
  #filter(SampleNumber != 9) %>%
  summarise(mean = mean(Veff),
            sd = sd(Veff), 
            se = sd(Veff)/sqrt(n()))
print(veff_stats)

#### Final Checks #####################################
# Look at the following plots, they should look roughly normally distributed,
# without any patterns in the colors or distribution of the points
# Once you are satisfied with your effective volume estimate, edit the template 
# spreadsheet with veff_stats$mean as the loop volume

# Boxplot
jitter_settings <- position_jitter(width = 0.4, height = 0, seed = 123)
ggplot(veff_estimation_filt, 
       aes(y = Veff, x = "")) +
  geom_violin() +
  geom_hline(yintercept = veff_stats$mean) +
  geom_errorbar(ymin = veff_stats$mean - veff_stats$se,
                ymax = veff_stats$mean + veff_stats$se, width = 0.1) +
  geom_point(aes(color = SampleNumber), position = jitter_settings) +
  geom_text_repel(aes(label = SampleNumber), position = jitter_settings, hjust = 1.3) +
  ylab("Effective Volume of Loop (mL)") +
  theme_bw()

# Histogram Density plot
ggplot(veff_estimation_filt, 
       aes(x = Veff)) +
  geom_density() +
  geom_segment(x = veff_stats$mean - veff_stats$se,
                xend = veff_stats$mean + veff_stats$se,
               y = 0.001, yend = 0.001) +
  geom_vline(xintercept = veff_stats$mean) +
  xlab("Effective Volume of Loop (mL)") +
  theme_bw()
