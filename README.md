# Elektro-Pipe

A collection of code for a processing pipeline for elektroenkephalography (EEG) data. These tools do not actually contain any new signal processing tools. They are simply intended to make your life easier when working with a lot of datasets.

Installation:
- download and run ElektroSetup.m OR clone this repository and then run ElektroSetup.m

What you need:
- EEGLAB
- plugins: Cleanline, SASICA
- SubjectsTable.xlsx (a sample is included in this repository): An Excel spreadsheet containing a list of your subjects and information about these datasets. Matlab claims to be able read also .odt files, but at least on our machine this does not work. 
Important columns in this table are:

    Name: several funcions expect this column, which contains a name, code or pseudonym for each dataset.

    replace_chans: sometimes electrodes are broken and are replaced during recording with an external electrode. Suppose electrodes 31 and 45 are broken and are to be replaced with external electrodes 71 and 72, respectively. The information in this column should read: 31,71;45,72

    interp_chans: sometimes you discover that an electrode was dysfunction, but you did not record an external electrode to replace it with. You can still interpolate this electrode entirely.

    ica_ncomps: by default, ICA calculates automatically the number of independent components to estimate, or you can set a fixed number in the cfg file. But sometimes a dataset will not compute with either procedure. In such cases, it sometimes helps to have ICA estimate a much smaller number of ICs. This number can be set here.

- configuration (cfg) file: this file specifies all variable aspects of your analysis (paths to data files, sampling rate, filter setting, etc.).    
    
The code comes with a "samples" folder, which contains a sample SubjectsTable.xlsx, a sample cfg file (getcfg.m), and a script that illustrates how to run all these analyses


