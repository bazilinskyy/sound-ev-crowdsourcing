#  Crowdsourced experiment on sounds for electric vehicles
Frontend implementation of the noticeability and annoyance of synthetic sound signals for electric vehicles.

You may find the article with results at https://bazilinskyy.github.io/publications.

This project defines a framework for the analysis of crossing behaviour in the interaction between multiple pedestrians and an automated vehicle, from the perspective of one of the pedestrians using a crowdsourcing approach. The jsPsych framework is used to for the frontend. In the description below, it is assumed that the repo is stored in the folder `sound-ev-crowdsourcing`. Terminal commands lower assume macOS.

## Setup
Code for analysis is written in MATLAB. No configuration is needed. The project is tested with MATLAB 2021b.

### Visualisation
Figures are saved in `sound-ev-crowdsourcing/_output`.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/keypress-online-noise.jpg?raw=true)
Keypresses in crowdsourced experiment.

![keypresses in crowdsourced study with effect of background noise](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/keypress-online-noise.jpg?raw=true)
Keypresses in crowdsourced experiment with effect of background noise.

![scatter plot of annoyance and keypress data](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-annoyance-keypress.jpg?raw=true)
Scatter plot of annoyance and keypress data.

![scatter plot of noteceability and annoyance](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-notice-annoyance.jpg?raw=true)
Scatter plot of annoyance and keypress data.

![scatter plot of noteceability and information](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-notice-information.jpg?raw=true)
Scatter plot of annoyance and showing enough information data.

![scatter plot of volume and annoyance](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-notice-information.jpg?raw=true)
Scatter plot of volume and annoyance.

### Configuration of analysis
Configuration of analysis needs to be defined in `sound-ev-crowdsourcing/config`. Please use the `default.config` file for the required structure of the file. If no custom config file is provided, `default.config` is used. The config file has the following parameters:
* `files_heroku`: files with data from heroku from the crowdsourced experiment.
* `file_appen`: file with data from appen from the crowdsourced experiment.
* `data_file`: mat file with data from the crowdsourced experiment.
* `files_heroku_lab`: files with data from heroku from the controlled experiment.
* `file_appen_lab`: file with data from appen from the controlled experiment.
* `data_file_lab`: mat file with data from the controlled experiment.
* `estimated_annoyance`: mat file data of estimated annoyance.
* `mapping`: csv file with mapping of stimuli.
* `path_output`: path for outputting figures in the EPS format.
* `path_figures`: path for outputting figures in the JPG format.
