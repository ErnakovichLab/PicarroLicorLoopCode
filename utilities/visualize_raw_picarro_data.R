# The purpose of this script is to facilitate reading in and visualizing the raw picarro data.

library(tidyverse)
library(here)
library(lubridate)
library(zoo)
library(cowplot)

################################################################################
### Picarro raw data utility functions
################################################################################
# Function - read in picarro .dat files

read_picarro_dat <- function(filepath, 
                             timestamp_start = NULL,
                             timestamp_end = NULL,
                             name_pattern = "^CFIDS2227-2026.{1,}dat$") {
  file_list <- list.files(filepath,
                          pattern = name_pattern, 
                          full.names = T)
  d <- map_dfr(file_list,
              ~read_table(file = .) %>%
                mutate(timestamp = as.POSIXct(paste(DATE, TIME)))
                )
  
  if(!is.null(timestamp_start)){
    d <- d %>% filter(timestamp > timestamp_start)
  }
  
  if(!is.null(timestamp_end)){
    d <- d %>% filter(timestamp < timestamp_end)
  }
  return(d)
}

# Function to plot initial plots
plot_picarro_data <- function(input_data, 
                              columns = c("12CO2_dry", "HP_12CH4"),
                              rollingAvg = T, lag_length = 40,
                              SlopeChange = T) {
  plot_data <- input_data %>% 
    select(timestamp, all_of(columns)) %>%
    pivot_longer(-timestamp, 
                 names_to = "coln",
                 values_to = "value") %>%
    group_by(coln) %>%
    arrange(coln, timestamp) %>%
    mutate(rollavg = NA,
           rollingslope = NA,
           abs_slope = NA,
           slopescaled = NA,
           slope_beyond_limit = NA)

  # compute rolling average
  if(rollingAvg) {
    plot_data <- plot_data %>% 
      mutate(rollavg = zoo::rollmean(x = value, lag_length, align = "right", fill = NA))
    
    
    if(SlopeChange){

      plot_data <- plot_data %>%
        mutate(lag_rollavg = lag(rollavg, n = floor(lag_length/4)),
               rollingslope = (rollavg - lag_rollavg)/lag_length,
               abs_slope = abs(rollingslope),
               slopescaled = (abs_slope-min(abs_slope, na.rm = T))/(max(abs_slope, na.rm = T) - min(abs_slope, na.rm = T)),
               slope_beyond_limit = if_else(slopescaled > 0.05, T, F))
    }
  }  
  
  
  plotting_layers <- list(
    #geom_point(),
    geom_point(aes(fill = slope_beyond_limit), shape = 21),
    annotate("text", label = paste0("Rolling Avg Lag = ", lag_length, "\n",
                                    "Slope Lag = ", floor(lag_length/4)),
             x = -Inf, y = Inf, hjust = -0.1, vjust = 1.1),
    theme_bw()
  )
  plots <- plot_data %>% 
    nest() %>%
    mutate(plot = purrr::map2(data, coln, 
                              ~ggplot(.x, 
                                   aes(x = timestamp, 
                                       y = value)) +
                             plotting_layers +
                             geom_line(aes(y = rollavg), color = "blue") +
                             ylab(coln)
                           )) %>%
    select(coln, plot)

  return(list(plot_data = plot_data, 
              plots = plots))
}

# Reduce the plot data down to averages
calc_flat_segments <- function(input_data = picarro_plots$plot_data,
                               min_change_length = 100) {
  segments_reduced <- input_data %>%
    filter(!is.na(rollingslope)) %>%
    mutate(RegionID = as.factor(consecutive_id(slope_beyond_limit))) %>%
    group_by(coln, RegionID, slope_beyond_limit) %>% 
    summarize(min_time = min(timestamp), max_time = max(timestamp), tally = n(),
              RollAvg = mean(rollavg),
              RollAvgMin = min(rollavg),
              RollAvgMax = max(rollavg)) %>%
    # Remove small strings of slope beyond the limit, as determined by "min_change_length"
    mutate(AvgingGroup =case_when( slope_beyond_limit & tally > min_change_length ~ "Not Flat",
                                   slope_beyond_limit & tally <= min_change_length ~ "Flat",
                                   !slope_beyond_limit ~ "Flat"),
           RollAvg = ifelse(AvgingGroup == "Not Flat", NA, RollAvg)) %>%
    ungroup() %>% group_by(coln) %>%
    mutate(AvgingGroupID = consecutive_id(AvgingGroup)) %>% #names()
    select(coln, slope_beyond_limit, contains("time"), AvgingGroupID, AvgingGroup, contains("RollAvg")) %>%
    # Re-summarize new groups
    group_by(coln, AvgingGroupID, AvgingGroup) %>%
    summarize(min_time = min(min_time), max_time = max(max_time),
              RollAvg = mean(RollAvg, na.rm = T),
              RollAvgMin = min(RollAvgMin), RollAvgMax = max(RollAvgMax)) %>% 
    ungroup() %>% group_by(coln)
    
  return(segments_reduced)
}

# Extracting averages from regions
extract_flat_regions <- function(input_data = dat, 
                              columns = c("12CO2_dry", "HP_12CH4"),
                              time_segments = time_segments_df) {
  raw_data <- input_data %>% 
    select(timestamp, all_of(columns))
  
  # Define a join_by function
  time_overlap <- join_by(between(timestamp, min_time, max_time))
  
  joined_averages <- full_join(raw_data, time_segments, time_overlap) %>%
    filter(!is.na(min_time)) %>%
    group_by(min_time, max_time) %>%
    summarize(across(all_of(columns), ~mean(., na.rm = T))) %>%
    ungroup() %>%
    mutate(MeasureID = consecutive_id(min_time)) %>%
    select(MeasureID, everything())
  
  return(joined_averages)

}

###############################################################################
# Applying functions
###############################################################################
# Read in data
dat <- read_picarro_dat(filepath = "~/Downloads/",
                        timestamp_start = "2026-02-24 11:00:00",
                        timestamp_end = "2026-02-24 15:00:00"
                        )

# Plot data
columns_of_interest <- c("12CO2_dry", "HP_12CH4", "HP_13CH4", "H2O")
picarro_plots <- plot_picarro_data(input_data = dat, 
                                   columns = columns_of_interest,
                                   lag_length = 100)

cowplot::plot_grid(plotlist = picarro_plots$plots$plot)

# Get regions of flatness
flat_segments <- calc_flat_segments(picarro_plots$plot_data)

flat_segments_only <- flat_segments %>% 
  filter(AvgingGroup == "Flat") %>%
  nest(.key = "flat_data")

# Add flattened regions to plots
averaging_region_plots <- picarro_plots$plots %>% 
  left_join(flat_segments_only, by = "coln") %>%
  mutate(plot_with_flats = purrr::map2(plot, flat_data, 
                                       ~ .x + 
                                         geom_rect(data = .y %>% mutate(value = min(RollAvg), 
                                                                        timestamp = min_time), 
                                                   aes(xmin = min_time, xmax = max_time,
                                                       ymin = RollAvgMin, ymax = RollAvgMax),
                                                   color = "black", fill = "grey50", alpha = 0.8) +
                                         geom_segment(data = .y %>% mutate(value = min(RollAvg), 
                                                                           timestamp = min_time), 
                                                      aes(x = min_time, xend = max_time,
                                                          y = RollAvg, yend = RollAvg),
                                                      color = "black")))

cowplot::plot_grid(plotlist = averaging_region_plots$plot_with_flats)

# Get a list of the average start and end times of the flat segments across 
# all the variables; Make sure to only average across variables that show consistent
# times. 
time_segments_df <- flat_segments_only %>% unnest(flat_data) %>%
  ungroup() %>%
  filter(coln == "HP_13CH4") %>%
  select(AvgingGroupID, min_time, max_time) %>%
  group_by(AvgingGroupID) %>%
  summarize(min_time = mean(min_time), max_time = mean(max_time))

flat_data <- extract_flat_regions(input_data = dat, columns = columns_of_interest,
                                  time_segments = time_segments_df)

# Save output 
write_tsv(flat_data, file = "~/Downloads/picarro_summaries_out.tsv")
