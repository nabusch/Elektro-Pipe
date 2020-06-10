# Elektro-Pipe

A collection of code for a processing pipeline for elektroenkephalography (EEG) data. These tools do not actually contain any new signal processing tools. They are simply intended to make your life easier when working with a lot of datasets.

Though this pipe includes tools for computing grandaverage ERPs, wavelet decomposition, and FFTs, its main purpose is preprocessing via the `prep_master.m` script and the functions called by it.

## Installation:
- download the latest release from https://github.com/nabusch/Elektro-Pipe/releases , extract it and run ElektroSetup.m from within Matlab.

## What you need:
- Recent Matlab (tested on R2019b)
- EEGLAB (2019.1)
- plugins: Cleanline, SASICA, eye-eeg (*recent github version!*), PREP, etc.. You will be warned about unmatched dependencies (see `elektro_dependencies.m`)
- SubjectsTable.xlsx (a sample is included in this repository): An Excel spreadsheet containing a list of your subjects and information about these datasets. Matlab claims to be able read also .odt files, but at least on our machine this does not work. 

### Important columns in this table are:

- Name: several funcions expect this column, which contains a name, code or pseudonym for each dataset.
- replace_chans: sometimes electrodes are broken and are replaced during recording with an external electrode. Suppose electrodes 31 and 45 are broken and are to be replaced with external electrodes 71 and 72, respectively. The information in this column should read: 31,71;45,72
- interp_chans: sometimes you discover that an electrode was dysfunction, but you did not record an external electrode to replace it with. You can still interpolate this electrode entirely.
- ica_ncomps: by default, ICA calculates automatically the number of independent components to estimate, or you can set a fixed number in the cfg file. But sometimes a dataset will not compute with either procedure. In such cases, it sometimes helps to have ICA estimate a much smaller number of ICs. This number can be set here.

### configuration
You'll need a custom configuration file for each project. This file specifies all variable aspects of your analysis (paths to data files, sampling rate, filter setting, etc.). You can run `elektro_prepconfigure()` to  be guided through the creation of a custom configuration.

The code comes with a "samples" folder, which contains a sample SubjectsTable.xlsx, a sample cfg file (getcfg.m), and a script that illustrates how to run all these analyses. We recommend creating a new project via `ElektroSetup`, which will copy the sample files to the appropriate locations in your new project directory.
