library(tidyverse)
library(ggrepel)
library(here)

#### User settings #############################################################
# This section contains settings for the user to edit. 
# File path to the measurments for the effective volume spreadsheet
resp_spreadsheet_fp <- "~/Downloads/Loop_volume_measurments_Utsa_12_01_2025_Picarro Respiration sheet template.xlsx"

# Data about where the effective volume measurments start
start_row <- 1 # row of dataframe where measurements start - does not include header rows (e.g. row 3 in spreadsheet = 1 in dataframe)
end_row <- 20 # row of dataframe where measurements end - does not include header rows (e.g. row 23 in spreadsheet = 20 in dataframe)
exclude_sampletypes <- c("mistake") # the value of "SampleType" column for samples you want to exclude from the analyses

#### Effective Volume Calculation ##############################################
veff_estimation_raw <- readxl::read_excel(resp_spreadsheet_fp, skip = 1)

veff_estimation <- veff_estimation_raw %>%
  # Clean and filter out unnessesary columns and rows
  slice(start_row:end_row) %>%
  filter(!(SampleType %in% exclude_sampletypes)) %>% # remove rows where mistakes were made
  select(`Volume of sample or standard (mL of gas measured)`,
         `Concentration of Standard Curve CO2 Gas (ppm)`,
         Date, `Time of start of measurement (write at least every 5 samples)`,
         `Mean of pre 12CO2_dry concentration (PPM)`,
         `Mean of post 12CO2 concentration (PPM)`,
         `Difference in 12CO2_dry (ppm)`,
         `Effective Volume of Loop (mL)`) %>%
  filter(!is.na(`Time of start of measurement (write at least every 5 samples)`)) %>%
  # Calculate the volume of the loop: Veff = Vstandard*(ConcentrationOfStandard - PostInjectionCO2Concentration) / PrePostCO2Difference
  mutate(Veff_numerator = `Volume of sample or standard (mL of gas measured)` *(`Concentration of Standard Curve CO2 Gas (ppm)` - `Mean of post 12CO2 concentration (PPM)`),
         Veff_denominator = `Difference in 12CO2_dry (ppm)`,
         Veff = Veff_numerator/Veff_denominator,
         Vcal = `Volume of sample or standard (mL of gas measured)`) %>%
  mutate(SampleNumber = row_number())

#### Quality Control of Volume Calculation #####################################
# Use the plots in this section to perform quality control on your data.
# Are there any patterns in estimates related to injection time, or sample volume?
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
  ylab("Effective Volume of Loop (mL)") + xlab("Sample volume (mL)") +
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
