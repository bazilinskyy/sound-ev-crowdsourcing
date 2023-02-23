#  Crowdsourced experiment on sounds for electric vehicles
Crowdsourced exploration of the noticeability and annoyance of synthetic sound signals for electric vehicles. You may find the article with results at https://bazilinskyy.github.io/publications. The jsPsych framework is used to for the frontend. In the description below, it is assumed that the repo is stored in the folder `sound-ev-crowdsourcing`. Terminal commands lower assume macOS.

## Setup
Code for analysis is written in MATLAB. No configuration is needed. The project is tested with MATLAB 2022b.

### Visualisation
Figures are saved in `sound-ev-crowdsourcing/_output`.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/sound-elapsed-time.jpg?raw=true)
Sound signal as a function of the elapsed time for two example stimuli without background noise (top) and the same stimuli with background noise (bgn) (bottom).

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/spectogram.jpg?raw=true)
Spectrogram of stimuli Cont2000 (top) and Cont2000bgn (bottom).

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/keypress-time.jpg?raw=true)
Key press percentage as a function of elapsed time for two selected samples. The legend shows the mean and SD of the performance score. The gray background indicates the time interval across which the performance score was computed.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-annoyance-loudness.jpg?raw=true)
Scatter plot of perceived annoyance and computed loudness score of the 30 stimuli.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-annoyance-noticeability.jpg?raw=true)
Scatter plot of perceived annoyance and perceived ‘easy to notice’ of the 30 stimuli.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/scatter-performance-annoyance.jpg?raw=true)
Scatter plot of performance (based on key-press inputs) and perceived annoyance of the 30 stimuli.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/keypress-time.jpg?raw=true)
Key press percentage as a function of elapsed time for two selected samples.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/keypress-online.jpg?raw=true)
Keypresses in crowdsourced experiment.

![keypresses in crowdsourced study](https://github.com/bazilinskyy/sound-ev-crowdsourcing/blob/main/figures/keypress-online.jpg?raw=true)
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
* `path_stimuli`: path for stimuli.
