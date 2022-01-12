#  Crowdsourced experiment on sounds for electric vehicles
Frontend implementation of the noticeability and annoyance of synthetic sound signals for electric vehicles.

You may find the article with results at https://bazilinskyy.github.io/publications.

This project defines a framework for the analysis of crossing behaviour in the interaction between multiple pedestrians and an automated vehicle, from the perspective of one of the pedestrians using a crowdsourcing approach. The jsPsych framework is used to for the frontend. In the description below, it is assumed that the repo is stored in the folder `sound-ev-crowdsourcing`. Terminal commands lower assume macOS.

## Setup
Code for analysis is written in MATLAB. No configuration is needed. The project is tested with MATLAB 2021b.

### Visualisation
Figures are saved in `sound-ev-crowdsourcing/_output`.

<!-- ![median willingness to cross](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/median-cross.jpg?raw=true)
Mediam willingness to cross.

![sd willingness to cross](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/sd-cross.jpg?raw=true)
Mediam willingness to cross.

![median willingness to cross for usa and ven](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/median-cross-usa-ven.jpg?raw=true)
Median willingness to cross for participants from USA and Venezuela.

![response willingness to cross for usa and ven](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/response-time-usa-ven.jpg?raw=true)
Response time for participants from USA and Venezuela. -->

### Configuration of analysis
Configuration of analysis needs to be defined in `sound-ev-crowdsourcing/config`. Please use the `default.config` file for the required structure of the file. If no custom config file is provided, `default.config` is used. The config file has the following parameters:
* `file_heroku`: files with data from heroku.
* `file_appen`: file with data from appen.
* `appen_range`: range of data in `file_appen`.
* `path_stimuli`: path with stimuli.
* `mapping`: csv file with mapping of stimuli.
* `path_figures`: path for outputting figures in the EPS format.
* `path_figures_readme`: path for outputting figures in the JPG format.