# Choices for the mechanics of EP design #

Computing a grand average with a factorial design requires three levels of code.

1. The "Master file". The purpose of this file is to collect all necessary inputs and then start the averaging procedures. 
2. The "design_erp_grandaverage": collects and interprets the user input and calls the subfunction for loading, processing, and saving data.
3. Slave functions: carry out a single (more or less) task such as loading EEG files or averaging across subjects.

## Implementation choices: ##

- The Master file is the only file the user actually interacts with. The toolbox should be designed such the user never needs to modify the functions of the 2nd and 3rd level. This way, the user can maintain a single copy of the Electropipe toolbox and use it for mutiple different experiments.
- The Master file is a collection of user choices, definitions, information, e.g. string variables defining "where stuff is located" or specs for which set of subjects to use. However, we do NOT want to actually compute or load anything inside the Master file. Thus, the user can define that we want to use subjects 1:10 or only subjects with 'include==1'. BUT the subjects are loaded only inside the design_erp_average function. This serves to keep the Master file as clean and accessible as possible. Simple idea: the Master file only tells us the IDEA. We interpret and implement the idea later. No implementation of the idea inside the Master file. Only exception: we do load the cfg file and the design file in the Master function and pass it to design_erp_grandaverage. This is because these files are experiment-specific. I hope this design choice makes sense in the long run.
- Keeping the design_erp_grandaverage and slave functions separate serves mostly one purpose: break down the procedure into small bits to keep the code elements small. Ideally, each subfunction should cover only a single screen page.

## Required user input ##
- project name: this is not necessarily the name for a design, neither for an experiment; one experiment can have many projects and a project can have many designs. Rather, the project analyses a given set of data that were processed in a specific way. Concrete examples for projects could be: "response locked data" and "stimulus locked data", or "long epochs" and "short epochs", or "original data" and "10Hz bandpass filtered data".

## What the design functions should produce
- For a m * n factorial design, we want a ALLEEG structure of size m * n, where each cell contains an EEG set for a given condition. Each "trial" in EEG.data contains the averaged erp of a single subject.
- Each EEG set should include:
   - Information about the design: factor and values
   - vector with subject indices
   - vector with number of trials for each subject in this condition
- Grand average data are written into a new folder called GRAND_nameoftheproject. Inside this folder, there are different set files named Grand_nameoftheproject_D(X), one for each design in the design file.


##  To Do List  ##
- [ ] Compute grand average not only of EEG data. Offer feature for computing similar averages for behavior data from EEG.event structure.
- [ ] Arrange the factor names, value, labels, etc. in a multidemensional array like the ALLEEG array.
- [ ] 

