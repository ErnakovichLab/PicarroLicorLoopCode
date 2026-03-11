# View SEI flush times
library(tidyverse)
library(readxl)
library(lubridate)
library(here)

################################################################################
################################################################################

read_in_gas_flushes <- function(filepath = "~/Downloads/GasMeasurementTracking_SEI26.xlsx"){
  
  sheet_list <- excel_sheets(path = filepath)
  sheet_list <- sheet_list[grepl("Flush", sheet_list)] # only select flush data sheets
  
  excel_sheet_readin <- function(z){
    sheet_name <- z
    df <- readxl::read_excel(filepath, sheet = sheet_name,
                             col_types = c("text", "date", "text", 
                                           "text", "text", "text"),
                             range = cell_limits(c(1,1), c(NA,6)))
    df <- df %>% mutate(FlushSheetLabel = as.character(sheet_name))
    return(df)
  }
  d <- map_dfr(sheet_list,
               ~excel_sheet_readin(.)) %>%
    mutate(`Gas Flush Time Ended` = force_tz(`Gas Flush Time Ended`, tzone = "America/New_York"))
  
  return(d)
}


reformat_gas_flush_data <- function(raw_gas_flush_data = d) {
  # Fix gas jar ids
  gas_flus_data_long <- raw_gas_flush_data %>%
    mutate(NewJarID = case_when(grepl("^[0-9]{1,3}$", `Jar ID`) ~ `Jar ID`, 
                                grepl("^C[1-9]", `Jar ID`) ~ gsub("(C[1-9])(.{1,})", 
                                                                  "\\1", `Jar ID`),
                                grepl("^[HI]", `Jar ID`) ~ gsub("(.{1,})-(.{1,})-(.{1,})", 
                                                                "\\3", `Jar ID`),
                                grepl("spilled", `Jar ID`) ~ gsub("(.{1,3}) (.{1,})", 
                                                                  "\\1-spilled", `Jar ID`),
                                grepl("x", `Jar ID`) ~ gsub("(.{1,3})(.{1,})", 
                                                                  "\\1-spilled", `Jar ID`),
                                .default ="NeedsFixing"))
  gas_flush_data_wide <- gas_flus_data_long %>%
    pivot_wider(id_cols = c(NewJarID),
                names_from = "FlushSheetLabel", 
                values_from = "Gas Flush Time Ended")
    
  gas_flush_data_wide <- left_join(gas_flush_data_wide,
                                   gas_flus_data_long %>% 
                                     select(`Jar ID`, NewJarID) %>%
                                     distinct(),
                                   by = "NewJarID")
  return(list(gas_flus_data_long, gas_flush_data_wide))
}


################################################################################
################################################################################

gas_flush_data <- read_in_gas_flushes()


reformatted_gas_flush_data <- reformat_gas_flush_data(raw_gas_flush_data = gas_flush_data)
