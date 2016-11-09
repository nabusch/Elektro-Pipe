function [ EEG ] = func_importEye(EEG, cfg)
%FUNC_IMPORTEYE coregisters Eyelink & EEG
%
%   FUNC_IMPORTEYE assumes that SR-Research's edf2asc tool exists in the
%   system path. The easiest way to assure that is to install the Eyelink
%   Developer's kit. On OS X it also checks for edf2asc in the standard
%   installation path.
%   FUNC_IMPORTEYE uses edf2asc to convert an Eyelink EDF file and
%   subsequently passes it to the functions of the Eye-EEG toolbox to
%   coregister it with the EEG data.
%
%   Usage: [ EEG ] = func_importEye(EEG, cfg)
%   Input:
%           EEG: EEGlab struct with continuous EEG data recorded
%                simultaneously with the Eyetracking data.
%                Eyelink and EEG struct must contain the same event markers
%                for coregistration.
%
%           cfg.dir_raweye: where are the EDF-files located?
%
%           cfg.dir_eye   : where to store EEG data relative to current
%                           folder?
%
%           cfg.subject_name: should match the filename of the edf file
%                             (without '.edf')
%
%           cfg.eye_startEnd: Vector with two values. The function looks
%                             for the first occurence of the first value
%                             and the last occurence of the second value in
%                             ET & EEG. In then coregisters the data
%                             between these two points.
%
%           cfg.eye_keepfiles: Boolean vector with two values. If [1 1],
%                              Eyetracking data are stored as a seperate
%                              ASCII and as a .mat file. [1 0] deletes the
%                              .mat, [0 1] the ASCII and [0 0] both files.
%                              If these files are present in the dir, they
%                              will not be created again.
%
% written by Wanja Mössing - WWU Münster (moessing@wwu.de)

%----------------------------------------------
% Preparations
%----------------------------------------------
curEDF = [cfg.dir_raweye cfg.subject_name '.edf'];
[~,~,~] = mkdir(cfg.dir_eye);
existing_files = dir(cfg.dir_eye);
existing_files = {existing_files.name};

%----------------------------------------------
% Assure that the EDF2ASC API is installed
%----------------------------------------------
edf2ascLoc = ''; %On OSX edf2asc is not on the path...
[status,~] = system('edf2asc');
if (isunix && status ~= 255) || (ispc && status ~= -1)
    error('edf2asc command not found.\n Consider installing the SR-Research developers-kit.\n')
elseif ismac && status ~=255
    %the eyelink dev kit doesn't add edf2asc to the path by default. So
    %check if it's at the default installation location
    [status,~] = system('/Applications/Eyelink/EDF_Access_API/Example/edf2asc');
    if status ~=255
        error('edf2asc command not found.\n Consider installing the SR-Research developers-kit.\n');
    else
        edf2ascLoc = '/Applications/Eyelink/EDF_Access_API/Example/';
    end
end

%----------------------------------------------
% Convert from .edf to .asc
%----------------------------------------------
fprintf('Now converting eyetracking file "%s" to ASCII...\n',curEDF);

%only convert if .asc file doesn't exist yet
if sum(ismember(existing_files,strcat(cfg.subject_name,'.asc')))==0
    % the -y parameter assures that the file is being overwritten each time.
    [~,~] = eval(['system(''',edf2ascLoc,'edf2asc -y -input -p ',cfg.dir_eye,' ',curEDF,''')']);
else
    warning(['Found file ''',cfg.subject_name,'.asc''. Using this file instead',...
        ' of converting again.'])
end

%----------------------------------------------
% Convert ASCII to .mat
%----------------------------------------------
fprintf('Now parsing ASCII eyetracking file...\n');

if sum(ismember(existing_files,strcat(cfg.subject_name,'.mat')))==0
    [~] = parseeyelink([cfg.dir_eye cfg.subject_name '.asc'],...
        [cfg.dir_eye cfg.subject_name '.mat']);
else
    warning(['Found file ''',cfg.subject_name,'.mat''. Using this file instead',...
        ' of parsing again.'])
end

%----------------------------------------------
% Coregister EEG & ET
%----------------------------------------------
fprintf('Now coregistrating EEG & Eyetracking...\n');
EEG = pop_importeyetracker(EEG, [cfg.dir_eye cfg.subject_name '.mat'],...
    cfg.eye_startEnd, 2:4, {'Eyegaze_X' 'Eyegaze_Y' 'Pupil_Dilation'}, 1,1,1,1);

%----------------------------------------------
% Delete ASCII & .mat files
%----------------------------------------------
if any(~cfg.eye_keepfiles)
    fprintf('Deleting temporary eyetracking files...\n');
end
if all(~cfg.eye_keepfiles)
    rmdir(cfg.dir_eye,'s');
else
    if ~cfg.eye_keepfiles(1)
        delete([cfg.dir_eye cfg.subject_name '.asc']);
    end
    if ~cfg.eye_keepfiles(2)
        delete([cfg.dir_eye cfg.subject_name '.mat']);
    end
end

end

