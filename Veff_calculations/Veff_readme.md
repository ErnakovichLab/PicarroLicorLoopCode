## Estimation of $V_{eff}$

The goal of `licor_veff_calcs.R` and `picarro_veff_calc.R` is to figure out effective volume ("Veff", $V_{eff}$) of the closed loop. We do this by repeatedly passing samples of a known concentration through the loop (\~20 times at minimum).

As each sample is placed in the loop, it will change the concentration by a consistent amount. Allowing you to estimate the volume of the loop.

It is important that as you measure the samples, your ***measurement techniques are*** ***consistent from sample to sample***. For example:

-   Use the same standard gas, and same volume of gas

-   Open the valve between samples to ensure the pressure does not increase as samples are added.

-   Your syringe technique is as identical as possible

These practices ensure that the only thing causing variation in the value of $V_{eff}$ is small errors in your measurements and/or atmospheric pressure/temperature variation.

## 

## How the math works

#### Background

The effective volume of the closed loop is necessary for the calculation of concentration within the loop. We define $V_{eff}$ (in ml) as the total volume of air in the closed loop prior to injection at a certain pressure and temperature. By injecting a specific volume ($V_{cal}$, ml) of a known calibration gas ($CO_{2\_cal}$, ppm) many times, you can observe a concentration increase (or decrease) from baseline ($CO_{2\_base}$, ppm) to a new concentration ($CO_{2\_post}$, ppm) and use that change to estimate the volume of the loop.

##### Equation 1:

$$
V_{eff} = \frac{V_{cal} \times (CO_{2\_cal} - CO_{2\_post})} {\Delta {CO_2}}
$$

##### Equation 2:

$$
CO_{2\_post} = \frac{V_{cal}CO_{2\_cal}  + V_{eff} CO_{2\_pre}}{(V_{eff} + V_{cal}) }
$$

Where,

$V_{cal}$ is the volume of calibration gas that was added to the loop (ml)

$CO_{2\_cal}$ is the concentration of the calibration gas (ppm)

$CO_{2\_post}$ is the steady concentration of the gas in the loop after a adding the calibration gas (ppm)

$CO_{2\_pre}$ is the steady concentration of the gas in the loop before adding the calibration gas (ppm)

$\Delta {CO_2}$ is the difference between $CO_{2\_pre}$ and $CO_{2\_post}$

[Equation 1](#equation-1) and [Equation 2](#equation-2) are equivalent. If you don't believe it, check out [Appendix 1](#Appendix-1-Relating-equation-1-to-equation-2).

Putting [equation 1](#equation-1) another way:

$$
V_{eff} = \frac{V_{cal} \times (CO_{2\_cal} - CO_{2\_post})} { (CO_{2\_post} - CO_{2\_pre})}
$$

Essentially this is an $M_1V_1 = M_2V_2$ situation. If the instrument and loop were full of $CO_2$-free air, then the $CO_{2\_pre}$ value would be 0 and $CO_{2\_post}$ would equal the concentration of the calibration gas, diluted by the volume of the loop.

## Protocol

#### Materials:

-   a CO~2~-containing standard gas of known concentration
-   Gas analyzer with recirculating pump and attached loop, installed and leak tested
-   25-21-gauge needle with luer lock attachment (Ex: BD Medical BD-305165)
-   5 or 10 mL plastic syringe
-   1-way luer stop-cock
-   Temperature, humidity, and air pressure gauge
-   data sheet (paper or electronic) for recording data
-   optional: CO~2~-free air for flushing loop

#### Part 1: Determining the effective volume

1.  Start the gas analyzer at least 1 hour before determining the volume of the loop.

2.  Record the room temperature, pressure, humidity, date, and start time. If the time on the instrument is not the same as the actual time, record the instrument time, this will make it easier for you to parse the raw data from the instrument in the future.

3.  In a spreadsheet or your lab notebook, create a table as below to record your data. Record 10-20 observations to be confident in your results.

| Observation | TimeStamp | Volume of Calibration gas injected (mL) | Concentration of calibration gas injected (ppm) | CO~2~ concentration of loop pre-injection (ppm) | CO~2~ concentration post-injection (ppm) |
|------------|------------|------------|------------|------------|------------|
| 1 |  |  |  |  |  |
| 2 |  |  |  |  |  |
| ... |  |  |  |  |  |
| 9 |  |  |  |  |  |
| 10 |  |  |  |  |  |

: An example datasheet for collecting closed-loop readings from the picarro {#tbl-data-sheet}

4.  For each observation:

    -   Record the room temperature, pressure, and humidity

    -   Ensure that the loop is closed and that the reported CO~2~ concentration has stabilized

    -   Draw standards from your tank or gas reservoir bag (detailed instruction on how to do this can be found in protocols folder)

    -   Insert syringe needle into septa of the needle port, open luer lock stopcock and push plunger firmly all the way down, wait a second or two, then remove needle from the septa.

    -   Record the time of injection in your data table, if it is not being recorded by the gas analyzer (for example, the Li-Integrator program will automatically record the timestamp).

    -   Record the average pre-injection stable section and the average post-injection stable section.

    -   Open the brass valve of the loop briefly to equilibrate with atmospheric pressure.

5.  Try not to change anything from reading to reading, but if you have to switch anything during the process (septa, needles, syringe), make a note of it in your lab notebook for later inspection

6.  In addition to saving the data you record, save the raw data from the session on a different computer. (NEVER rely on laboratory instruments to store raw data longer than a week)

### Appendix 1: Relating equation 1 to equation 2

$$
CO_{2_{post}} = \frac{V_{cal} \times CO_{2_{cal}} + V_{eff} \times CO_{2_{pre}}} { V_{eff} + V_{cal}}
$$


Multiply both sides by $(V_{eff} + V_{cal})$


$$
CO_{2_{post}}( V_{eff} + V_{cal}) = V_{cal} \times CO_{2_{cal}} + V_{eff} \times CO_{2_{pre}}
$$ Distribute out CO\_{2\_{post}} on the left side of the equation:


$$
CO_{2_{post}} \times V_{eff} + CO_{2_{post}} \times V_{cal} = V_{cal} \times CO_{2_{cal}} + V_{eff} \times CO_{2_{pre}}
$$ Subtract $(V_{eff} \times CO_{2_{pre}})$ from both sides of the equation:


$$
CO_{2_{post}} \times V_{eff} + CO_{2_{post}} \times V_{cal} - V_{eff} \times CO_{2_{pre}} = V_{cal} \times CO_{2_{cal}} 
$$ Consolidate all the $V_{eff}$ terms on the left side of the equation


$$
V_{eff}(CO_{2_{post}} - CO_{2_{pre}})  + (CO_{2_{post}} \times V_{cal})  = V_{cal} \times CO_{2_{cal}} 
$$ Divide both sides by $V_{cal}$ and rearrange the equation:


$$
CO_{2_{cal}} = \frac{(V_{cal} \times CO_{2_{post}}) + (V_{eff} \times \Delta {CO_{2}})} { V_{cal}}
$$
