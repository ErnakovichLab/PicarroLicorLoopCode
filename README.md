# Picarro and Licor Loop Code

Utility R functions for processing Picarro and Licor Data collected from a loop setup

## Description

This repository contains scripts meant for processing data on the picarro or Licor loop setup. 

tbd: image of loop
![Licor Loop setup](./misc/img/licor_loop_setup.jpg)
tbd: instrument information (include li-integrator info for licor)
tbd: link to protocols and list

## Getting Started

### Dependencies

-   R version >=4.0
-   R libraries: tidyverse, ggrepel (optional), here

### Installing

-   <to add, yml installation instructions>

```R
install.packages("tidyverse")
install.packages("here")
install.packages("ggrepel")
```

## Repository guide
```
.
├── README.md
├── Veff_calculations    <- scripts for calculation of the effective volume of the loop
├── calibration          <- tbd: scripts related to calibration of the instruments
├── SpreadsheetTemplates <- tbd: Templates for respiration measurments; Expected as input for most code 
├── protocols            <- tbd: protocols for gas sampling, instrument maintenance, etc.
└── misc                 <- tbd: miscellaneous files that don't fit elsewhere
    └── img              <- images
```
## Script overviews

### licor_veff_calcs.R or picarro_veff_calcs.R
-   Takes respiration spreadsheet as input

```         
code blocks for commands
```
## tbd: scripts for calculating and plotting gas flux for picarro and licor

## Protocol overviews
tbd list of protocols to add:
- how to collect data for veff
- how to take a standard curve
- how to calibrate instrument (different for licor and picarro)

## Help

tbd:Any advise for common problems or issues.

```         
tbd
```

## Authors

Hannah Holland-Moritz [\@hhollandmoritz](https://github.com/hhollandmoritz)

## Version History

-   0.1
    -   Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details

## Acknowledgments
<insert funding information>
<insert contribution information>
