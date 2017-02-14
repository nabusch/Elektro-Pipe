function [] = ElektroSetup()
%ELEKTROSETUP installs Elektro-Pipe and/or creates a new working directory
%
% Wanja Moessing Feb 2016 moessing@wwu.de

URDIR = pwd;
% Ask user what to do
choice = questdlg('What would you like to do?', ...
    'ElektroSetup', ...
    'Install Elektro-Pipe','Setup a new project','Both','Both');
% Handle response
switch choice
    case 'Install Elektro-Pipe'
        installEP = 1;
        setupProj = 0;
    case 'Setup a new project'
        installEP = 0;
        setupProj = 1;
    case 'Both'
        installEP = 1;
        setupProj = 1;
end

if installEP
    % Ask user what to do
    choice = questdlg(sprintf('Your current directory is %s.\n Shall I create a sub-folder called ''Elektro-Pipe''\n and install Elektro-Pipe there?',...
        pwd), 'ElektroSetup', ...
        'Yes','No, I want to specify another directory','I already downloaded Elektro-Pipe','I already downloaded Elektro-Pipe');
    switch choice
        case 'Yes'
            downloadEP = 1;
            EPdir = pwd;
        case 'No, I want to specify another directory'
            downloadEP = 1;
            EPdir = uigetdir;
        case 'I already downloaded Elektro-Pipe'
            choice2 = questdlg('Please specify where you installed Elektro-Pipe (should end on ../Elektro-Pipe/)', 'ElektroSetup', ...
                pwd,'Select another folder',pwd);
            switch choice2
                case pwd
                    EPdir = pwd;
                case 'Select another folder'
                    EPdir = uigetdir;
            end
            choice2 = questdlg('Do you want to check for updates? (requires git)', 'ElektroSetup', ...
                'yes','no','yes');
            switch choice2
                case 'yes'
                    downloadEP = 1;
                    updateEP = 1;
                case 'no'
                    downloadEP = 0;
            end
    end
    
    if downloadEP
        cd(EPdir);
        %check for git-client
        [status,~] = system('git --version');
        if status
            error('You need to install a git client to proceed!');
        end
        
        if exist('updateEP','var')
            %check status
            [status,command] = system('git fetch');
            if strfind(command,'fatal')
                error('This does not seem to be a git repository.')
            end
            [status,command] = system('git status'); %0 if up-to-data
            if strfind(command,'Your branch is behind')
                [status,command] = system('git pull')
            end
        else
            [status,command] = system('git clone https://github.com/nabusch/Elektro-Pipe.git')
            if status==128
                error('Could not download Elektro-Pipe');
            end
            cd('Elektro-Pipe');
        end
    end
    % add Elektro-Pipe to startup.m
    EPdir = pwd;
    setInitialWorkingFolder;
    fid = fopen('startup.m','a');
    AppendStartup = 1;
    if fid==-1
        choice = questdlg(sprintf(['It seems you don''t have a startup.m yet.\n',...
            'Do you want to create one?\nWithout a startup.m you''',...
            'll always need to add Elektro-Pipe to your path manually.']),...
            'ElektroSetup','yes','no','I do have a startup.m. I''ll show you its location!','yes');
        switch choice
            case 'yes'
                fid = fopen( 'results.txt', 'w' );
            case 'I do have a startup.m. I''ll show you its location!'
                startupDir = uigetdir;
                fid = fopen('startup.m','a');
                if fid==-1
                    error('Nope. No startup.m in this location...')
                end
            case 'no'
                AppendStartup = 0;
        end
    end
    if AppendStartup
        fprintf(fid,'\n%%Add Elektro-Pipe to path\naddpath(genpath(''%s''))',EPdir);
        fclose(fid);
    end
    
    %check if 16-bit triggers are installed.
    setInitialWorkingFolder;
    conts = dir;
    if ~ismember({'WM_utilities'},{conts.name})
        
        choice = questdlg(['If you want to split 16bit triggers from two',...
            ' devices to two separate 8-bit streams of triggers, you need',...
            ' a modified version of the file-io plugin. Do you want to',...
            ' download it now? (This is very specific to our lab. Click ''no''',...
            ' if unsure.)'],'ElektroSetup','yes','no','It''s already installed','yes');
        switch choice
            case 'yes'
                Add2Startup = 1;
                choice2 = questdlg(['Do you want to download the complete WM_utilities',...
                    ' repository (https://github.com/wanjam/WM_utilities) or just the modified file-io?'],...
                    'ElektroSetup',...
                    'Load the complete WM_utilities repository',...
                    'Only load the modified file-io',...
                    'Load the complete WM_utilities repository');
                switch choice2
                    case 'Load the complete WM_utilities repository'
                        [status,command] = system('git clone https://github.com/wanjam/WM_utilities.git')
                    case 'Only load the modified file-io'
                        mkdir('WM_utilities');
                        cd('WM_utilities');
                        [status,command] = system('git init');
                        [status,command] = system('git remote add -f origin https://github.com/wanjam/WM_utilities.git')
                        [status,command] = system('git config core.sparseCheckout true')
                        fid = fopen('.git/info/sparse-checkout','a');
                        fprintf(fid,'16_Bit_triggers/');
                        fclose(fid);
                        [status,command] = system('git pull --depth=1 origin master');
                        cd('../');
                end
                FileIOdir = [pwd,filesep,'WM_Utilities',filesep,'16_Bit_triggers'];
            case 'It''s already installed'
                choice2 = questdlg(['It''s useful to add this modified',...
                    ' file-io to you path at startup. Do you want to add it to startup.m now?'],...
                    'ElektroSetup','yes - let me select the folder to add at startup','no, thanks','yes');
                switch choice2
                    case 'yes'
                        FileIOdir = uigetdir;
                        Add2Startup = 1;
                    otherwise
                        Add2Startup = 0;
                end
            case 'no'
                Add2Startup = 0;
        end
        if Add2Startup
            fid = fopen('startup.m','a');
            AppendStartup = 1;
            if fid==-1
                choice = questdlg(sprintf(['It seems you don''t have a startup.m yet.\n',...
                    'Do you want to create one?\nWithout a startup.m you''',...
                    'll always need to add Elektro-Pipe to your path manually.']),...
                    'ElektroSetup','yes','no','I do have a startup.m. I''ll show you its location!','yes');
                switch choice
                    case 'yes'
                        fid = fopen( 'results.txt', 'w' );
                    case 'I do have a startup.m. I''ll show you its location!'
                        startupDir = uigetdir;
                        fid = fopen('startup.m','a');
                        if fid==-1
                            error('Nope. No startup.m in this location...')
                        end
                    case 'no'
                        AppendStartup = 0;
                end
            end
            if AppendStartup
                fprintf(fid,'\n%%Add modified file-io to path (see https://github.com/wanjam/WM_utilities)\naddpath(genpath(''%s''))',FileIOdir);
                fclose(fid);
            end
        end
    end
    disp('Elektro-Pipe installation complete.')
end
if setupProj
    EPsubdir=which('prep01_preproc');
    EPonPath=isempty(EPsubdir);
    if ~EPonPath && ~exist('EPdir','var')
        msgbox('Please specify where you installed Elektro-Pipe', 'ElektroSetup');
        EPdir = uigetdir;
    elseif EPonPath && ~exist('EPdir','var')
        %best guess...
        EPdir = EPsubdir(1:(strfind(EPsubdir,'prep01_preproc')-1));
    end
        msgbox('Please select a location for your new project', 'ElektroSetup');
        ProjLoc = uigetdir;
        ProjNam = inputdlg('What''s your project''s name?','ElektroSetup');
        choice = questdlg('Do you want to analyze eyetracking data as well?','ElektroSetup','yes','no','yes');
        %create folder-structure
        mkdir([ProjLoc,filesep,ProjNam]);
        mkdir([ProjLoc,filesep,ProjNam,filesep,'BDF']);
        if strcmp(choice,'yes')
        mkdir([ProjLoc,filesep,ProjNam,filesep,'EDF']);
        end
        mkdir([ProjLoc,filesep,ProjNam,filesep,'Logfiles']);
        mkdir([ProjLoc,filesep,ProjNam,filesep,'Analysis']);
        mkdir([ProjLoc,filesep,ProjNam,filesep,'Analysis',filesep,'Behavioral']);
        mkdir([ProjLoc,filesep,ProjNam,filesep,'Analysis',filesep,'EEG']);
        if strcmp(choice,'yes')
        mkdir([ProjLoc,filesep,ProjNam,filesep,'Analysis',filesep,'Eye']);
        end
        %copy sample files files
        sampleFiles = dir([EPdir,filesep,'private',filesep,'Sample files']);
        for file = {sampleFiles.name}
            copyfile([EPdir,filesep,'private',filesep,'Sample files',filesep,file],...
                [ProjLoc,filesep,ProjNam,filesep,'Analysis',filesep,'EEG']);
        end

end
cd(URDIR);
end


