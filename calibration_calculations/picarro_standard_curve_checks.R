library(tidyverse)
library(ggrepel)
library(here)

#### User settings #############################################################
# This section contains settings for the user to edit. 
# File path to the measurments for the effective volume spreadsheet
resp_spreadsheet_fp <- "~/Downloads/Utsa_loop_volume_calculation_2025-12-04-Picarro Respiration.xlsx"

# Data about where the effective volume measurments start
start_row <- 23 # row of dataframe where measurements start - does not include header rows (e.g. row 3 in spreadsheet = 1 in dataframe)
end_row <- 66 # row of dataframe where measurements end - does not include header rows (e.g. row 23 in spreadsheet = 20 in dataframe)
exclude_sampletypes <- c("mistake") # the value of "SampleType" column for samples you want to exclude from the analyses

#### Effective Volume Calculation ##############################################
col_types_picarro <- c(rep("text", 2), #sampletype:jar number
                       rep("numeric", 14), #RoomTemperature:EffectiveIsotopicRatio
                       "date", #time last zeroed
                       rep("text", 1), # comments
                       "date", # Date
                       "text", # time of start of measurements
                       rep("numeric", 8), #Mean of pre-12CO2:MeanH2O%post 
                       "text", # Remarks 
                       rep("numeric", 27), # effective volume of loop:TrueDelta permil
                       rep("guess", 11)) # regression calculations

# Read in data
std_curve_raw <- readxl::read_excel(resp_spreadsheet_fp, skip = 1,
                                    col_types = col_types_picarro,
                                    na = c("nan", "#VALUE!", "#DIV/0!", "#REF!"))

std_curve_estimation <- std_curve_raw %>%
  # Clean and filter out unnessesary columns and rows
  slice(start_row:end_row) %>%
  filter(!(SampleType %in% exclude_sampletypes)) %>% # remove rows where mistakes were made
  select(`Jar Number`,
         `Volume of sample or standard (mL of gas measured)`,
         `Room Temperature (degC)`, `RoomPressure (hPa)`,
         `Concentration of Standard Curve CO2 Gas (ppm)`,
         `Atom% of Standard Curve 13CO2`,
         `Atom% of standard curve 12CO2`,
         `12CO2-PPM`,                                                     
         `13CO2-PPM`,                                                     
         `Isotope ratio of CO2 gas`,                                      
         `Delta value of the gas`,                                        
         `Rvpdb`,                                                         
         `Effective isotopic ratio given delta`,                          
         `Time Last Zeroed`,                                             
         `Comments`,                             
         Date, `Time of start of measurement (write at least every 5 samples)`,
         `Mean of pre 12CO2_dry concentration (PPM)`,
         `Mean of pre-13CO2 concentration (PPM)`,
         `Mean of pre delta iCO2 Raw (permil)`,
         `Mean H2O % pre`, 
         `Mean of post 12CO2 concentration (PPM)`,
         `Mean of post-13CO2 concentration (PPM)`,
         `Mean of post delta iCO2 Raw (permil)`,
         `Difference in 12CO2_dry (ppm)`,
         `Effective Volume of Loop (mL)`,
         `Fractional contribution of Sample to loop 'pool' (f_a)`,
         contains("Uncalibrated"),
         contains("True")) %>%
  filter(!is.na(`Time of start of measurement (write at least every 5 samples)`)) %>%
  mutate(SampleNumber = row_number(),
         ppm_co2_total = `Uncalibrated apparent total CO2 in sample (umol)`/`Volume of sample or standard (mL of gas measured)`,
         true_post_concentration12co2 = `Mean of pre 12CO2_dry concentration (PPM)` + ((`12CO2-PPM`*`Volume of sample or standard (mL of gas measured)`)/(`Effective Volume of Loop (mL)` + `Volume of sample or standard (mL of gas measured)`)),
         true_post_concentration13co2 = `Mean of pre-13CO2 concentration (PPM)` + ((`13CO2-PPM`*`Volume of sample or standard (mL of gas measured)`)/(`Effective Volume of Loop (mL)` + `Volume of sample or standard (mL of gas measured)`)),
         true_post_delta_value = (`Fractional contribution of Sample to loop 'pool' (f_a)`*`Delta value of the gas`)+(`Mean of pre delta iCO2 Raw (permil)`*(1-`Fractional contribution of Sample to loop 'pool' (f_a)`))) %>%
  group_by(`Jar Number`) %>%
  mutate(scaled_uncal_13co2_ppm = scale(`Uncalibrated apparent 13CO2 concentration (ppm)`),
          scaled_uncal_12co2_ppm = scale(`Uncalibrated apparent 12CO2 concentration (ppm)`),
          scaled_uncal_delta = scale(`Uncalibrated apparent delta value of sample (permil)`),
          outlier_13co2 = !dplyr::between(scaled_uncal_13co2_ppm, left = -2, right = 2),
          outlier_12co2 = !dplyr::between(scaled_uncal_12co2_ppm, left = -2, right = 2),
          outlier_delta = !dplyr::between(scaled_uncal_delta, left = -2, right = 2)) %>%
  ungroup()

#### Quality Control of Samples #####################################
# Use the plots in this section to perform quality control on your data.
# Are there any patterns in estimates related to injection time, sample volume, 
std_curve_outlier_removal <- std_curve_estimation %>%
  filter(!(SampleNumber %in% c(32,11,6, 19))) #%>%
  #filter(`Volume of sample or standard (mL of gas measured)` > 1)

ggplot(std_curve_outlier_removal, 
       aes(y = `True amount of 13CO2 in calibration standard (uMol)`, 
           x = `Uncalibrated apparent amount of 13CO2 in sample (uMol)`)) +
  geom_point(aes(color = outlier_13co2)) +
  geom_text_repel(aes(label = SampleNumber)) +
  ylab("True amount of 13CO2 in calibration standard (uMol)") + xlab("Uncalibrated apparent amount of 13CO2 in sample (uMol)") +
  theme_bw()

ggplot(std_curve_outlier_removal,
       aes(y = `13CO2-PPM`, 
           x = `Uncalibrated apparent 13CO2 concentration (ppm)`)) +
  geom_smooth(method = "lm") +
  geom_point(aes(color = as.factor(`Volume of sample or standard (mL of gas measured)`)), alpha = 0.5) +
  geom_text_repel(aes(label = SampleNumber)) +
  geom_abline(slope = 1, intercept = 0, 
              color = "firebrick", linetype = "dashed") +
  ylab("True amount of 13CO2 in calibration standard (ppm)") + xlab("Uncalibrated apparent amount of 13CO2 in sample (ppm)") +
  theme_bw()

CO2_13_ppm_std_curve <- std_curve_estimation %>%
  filter(!(SampleNumber %in% c(32,11,6, 19))) %>%
  filter(`Volume of sample or standard (mL of gas measured)` > 1) %>%
  lm(data = ., `13CO2-PPM`~`Uncalibrated apparent 13CO2 concentration (ppm)`)

summary(CO2_13_ppm_std_curve)

CO2_13_umol_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `True amount of 13CO2 in calibration standard (uMol)`~`Uncalibrated apparent amount of 13CO2 in sample (uMol)`)

summary(CO2_13_umol_std_curve)


ggplot(std_curve_outlier_removal,
       aes(y = `true_post_concentration13co2`, 
           x = `Mean of post-13CO2 concentration (PPM)`)) +
  #geom_smooth(method = "lm") +
  geom_point(aes(color = as.factor(`Volume of sample or standard (mL of gas measured)`)), alpha = 0.5) +
  geom_text_repel(aes(label = SampleNumber)) +
  geom_abline(slope = 1, intercept = 0, 
              color = "firebrick", linetype = "dashed") +
  ylab("True amount of 12CO2 in loop after sample addition (ppm)") + xlab("Uncalibrated apparent amount of 12CO2 in loop after sample addition (ppm)") +
  theme_bw()

CO2_13_ppmpost_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `true_post_concentration13co2`~`Mean of post-13CO2 concentration (PPM)`)
summary(CO2_13_ppmpost_std_curve)
# 12co2



ggplot(std_curve_outlier_removal, 
       aes(y = `True amount of 12CO2 in calibration standard (uMol)`, 
           x = `Uncalibrated apparent amount of 12CO2 in sample (uMol)`)) +
  geom_point(aes(color = outlier_12co2)) +
  geom_text_repel(aes(label = SampleNumber)) +
  ylab("True amount of 12CO2 in calibration standard (uMol)") + xlab("Uncalibrated apparent amount of 12CO2 in sample (uMol)") +
  theme_bw()

ggplot(std_curve_outlier_removal,
       aes(y = `12CO2-PPM`, 
           x = `Uncalibrated apparent 12CO2 concentration (ppm)`)) +
  #geom_smooth(method = "lm") +
  geom_point(aes(color = as.factor(`Volume of sample or standard (mL of gas measured)`)), alpha = 0.5) +
  geom_text_repel(aes(label = SampleNumber)) +
  geom_abline(slope = 1, intercept = 0, 
              color = "firebrick", linetype = "dashed") +
  ylab("True amount of 12CO2 in calibration standard (ppm)") + xlab("Uncalibrated apparent amount of 12CO2 in sample (ppm)") +
  theme_bw()

CO2_12_ppm_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `12CO2-PPM`~`Uncalibrated apparent 12CO2 concentration (ppm)`)

summary(CO2_12_ppm_std_curve)

CO2_12_umol_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `True amount of 12CO2 in calibration standard (uMol)`~`Uncalibrated apparent amount of 12CO2 in sample (uMol)`)
summary(CO2_12_umol_std_curve)


ggplot(std_curve_outlier_removal,
       aes(y = `true_post_concentration12co2`, 
           x = `Mean of post 12CO2 concentration (PPM)`)) +
  #geom_smooth(method = "lm") +
  geom_point(aes(color = as.factor(`Volume of sample or standard (mL of gas measured)`)), alpha = 0.5) +
  geom_text_repel(aes(label = SampleNumber)) +
  geom_abline(slope = 1, intercept = 0, 
              color = "firebrick", linetype = "dashed") +
  ylab("True amount of 12CO2 in loop after sample addition (ppm)") + xlab("Uncalibrated apparent amount of 12CO2 in loop after sample addition (ppm)") +
  theme_bw()

CO2_12_ppmpost_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `true_post_concentration12co2`~`Mean of post 12CO2 concentration (PPM)`)
summary(CO2_12_ppmpost_std_curve)




ggplot(std_curve_outlier_removal, 
       aes(y = `True delta value in calibration standard`, 
           x = `Uncalibrated apparent delta value of sample (permil)`)) +
  geom_point(aes(color = outlier_delta)) +
  geom_text_repel(aes(label = SampleNumber)) +
  ylab("True delta of calibration standard (permil)") + 
  xlab("Uncalibrated apparent delta of sample (permil)") +
  theme_bw()

ggplot(std_curve_outlier_removal,
       aes(y = `Isotope ratio of CO2 gas`, 
           x = `Uncalibrated apparent isotope ratio of sample`)) +
  #geom_smooth(method = "lm") +
  geom_point(aes(color = as.factor(`Volume of sample or standard (mL of gas measured)`)), alpha = 0.5) +
  geom_text_repel(aes(label = SampleNumber)) +
  geom_abline(slope = 1, intercept = 0, 
              color = "firebrick", linetype = "dashed") +
  ylab("True isotope ratio of calibration standard (ppm)") + xlab("Uncalibrated apparent isotope ratio of sample") +
  theme_bw()

CO2_delta_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `True delta value in calibration standard`~`Uncalibrated apparent delta value of sample (permil)`)

summary(CO2_delta_std_curve)

CO2_isorat_std_curve <- std_curve_outlier_removal %>%
  lm(data = ., `Isotope ratio of CO2 gas`~`Uncalibrated apparent isotope ratio of sample`)

summary(CO2_isorat_std_curve)

# Isotope ratio by concentration


ggplot(data = std_curve_outlier_removal,
       aes(x = `Isotope ratio of CO2 gas`,
           y = `Concentration of Standard Curve CO2 Gas (ppm)`)) +
  geom_point() +
  geom_point(data = std_curve_outlier_removal,
             aes(x = `Uncalibrated apparent isotope ratio of sample`,
                 y = `Uncalibrated apparent total CO2 in sample (umol)`)) +
  theme_bw()

  
  
ggplot(std_curve_outlier_removal,
         aes(y = `true_post_delta_value`, 
             x = `Mean of post delta iCO2 Raw (permil)`)) +
    geom_point(aes(color = as.factor(`Volume of sample or standard (mL of gas measured)`)), alpha = 0.5) +
    geom_text_repel(aes(label = SampleNumber)) +
    geom_abline(slope = 1, intercept = 0, 
                color = "firebrick", linetype = "dashed") +
    ylab("True delta in loop after sample addition (permil)") + xlab("Uncalibrated apparent delta in loop after sample addition (permil)") +
    theme_bw()
  
CO2_deltapost_std_curve <- std_curve_outlier_removal %>%
    lm(data = ., `true_post_delta_value`~`Mean of post delta iCO2 Raw (permil)`)
summary(CO2_deltapost_std_curve)
  
  
#### Final Checks #####################################
# For the picarro calibration, extract a smaller dataframe of 19 points
set.seed(12345)
calibration_dat <- std_curve_outlier_removal %>%
    select(SampleNumber, `Jar Number`,
           `Volume of sample or standard (mL of gas measured)`,
           true_post_concentration12co2,
           `Mean of post 12CO2 concentration (PPM)`,
           true_post_concentration13co2, 
           `Mean of post-13CO2 concentration (PPM)`,
           `True delta value in calibration standard`,
           `Uncalibrated apparent delta value of sample (permil)`) %>%
    group_by(`Jar Number`, `Volume of sample or standard (mL of gas measured)`) %>%
    slice_sample(n = 1)
  
write_tsv(calibration_dat, "~/Downloads/picarro_calibration_file.tsv")

coefficients(CO2_12_ppmpost_std_curve)
coefficients(CO2_13_ppmpost_std_curve)
coefficients(CO2_deltapost_std_curve)
