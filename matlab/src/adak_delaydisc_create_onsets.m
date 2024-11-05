%% adak_delaydisc_create_onsets.m
% Structure based on new_logreg.mlx by Keith and Kelly 
%
% This script takes as input the manuallly parsed text files output from edat2 files created by Kelly (*parsed.txt).
% For each text file, it extracts the onset times and durations for easy_later, easy_now, hard_later, hard_now conditions.
% These conditions are defined by the columns "diff" and "choice" in the edat text file
% The run onset time is defined by WaitForTrigger.RTTime in the edat text file
% The trial onset times are defined by DelayTrial.OnsetTime in the edat text file
% The trial durations are determined by the participant's RT for each trial, defined by DelayTrial.RT in the edat text file
% The SPM multiple condition onset.mat files are saved as DelayDiscount_sub-<subject id>_ses-<session_id>_Run<run_number>.mat
%       Example output file: DelayDiscount_sub-266_ses-02_Run1.mat

% home='/path/to/parsed DD files'

VariableNames = {'ExperimentName','Subject', 'Session', 'diff', 'choice', 'WaitForTrigger_RTTime', 'DelayTrial_OnsetTime', 'DelayTrial_RESP', 'DelayTrial_RT'};
subjids = {'200.1', '200.2', '200.3', '200.4', '201.1', '201.2', '201.3', '201.4', '202.1', '202.2', '202.3', ... 
'202.4', '203.1', '203.2', '204.1', '204.2', '204.3', '204.4', '205.1', '205.2', '207.1', '207.2', ... 
'207.3', '207.4', '208.1', '208.2', '209.1', '209.2', '209.3', '209.4', '212.1', '212.2', '212.3', ...
'212.4', '213.1', '213.2', '213.3', '213.4', '214.1', '214.2', '215.1', '215.2', '215.3', '215.4', ...
'216.1', '216.2', '216.3', '216.4', '217.1', '217.2', '222.1', '222.2', '223.1', '223.2', '223.3', ... 
'223.4', '225.1', '225.2', '225.3', '225.4', '226.1', '226.2', '226.3', '226.4', '227.1', '227.2', ... 
'227.3', '227.4', '228.1', '228.2', '228.3', '228.4', '229.1', '229.2', '229.3', '229.4', '230.1', ... 
'230.2', '231.1', '231.2', '232.1', '232.2', '232.3', '232.4', '235.1', '235.2', '235.3', '235.4', ... 
'236.1', '236.2', '236.3', '236.4', '237.1', '237.2', '237.3', '237.4', '238.1', '238.2', '238.3', ... 
'238.4', '239.1', '239.2', '239.3', '239.4', '241.1', '241.2', '242.1', '242.2', '242.3', '242.4', ... 
'244.1', '244.2', '244.3', '244.4', '245.1', '245.2', '245.3', '245.4', '246.1', '246.2', '246.3', ... 
'246.4', '247.1', '247.2', '247.3', '247.4', '248.1', '248.2', '248.3', '248.4', '249.1', '249.2', ... 
'249.3', '249.4', '250.1', '250.2', '250.3', '250.4', '252.1', '252.2', '252.3', '252.4', '253.1', ... 
'253.2', '254.1', '254.2', '254.3', '254.4', '255.1', '255.2', '255.3', '255.4', '256.1', '256.2', ... 
'256.3', '256.4', '258.1', '258.2', '258.3', '258.4', '259.1', '259.2', '259.3', '259.4', '260.1', ... 
'260.2', '260.3', '260.4', '261.1', '261.2', '261.3', '261.4', '262.1', '262.2', '262.3', '262.4', ... 
'263.1', '263.2', '263.3', '263.4', '265.1', '265.2', '266.1', '266.2', '266.3', '266.4', '267.1', ... 
'267.2', '267.3', '267.4', '268.1', '268.2', '268.3', '268.4'}; % subject.session


for j = 1:length(subjids)
    cd(home)
    currsubj = subjids{j};
    
    % Get subject and session from folder name
    folder_info = strsplit(currsubj, '.'); 
    folder_subject_id = folder_info{1};
    folder_session_id = folder_info{2};

    % go into subject_session folder that has run files
    cd(currsubj) 

    % grab the two run files
    eprime_run_files = dir('*parsed.txt'); 

    eprime_run_data = {};
        
    for m = 1:length(eprime_run_files)

        % Read in parsed edat output file
        edat_filename = eprime_run_files(m).name;
        curr_fulltable = readtable(edat_filename);

        % Select only columns needed to determine trial conditions, onsets, and RTs
        eprime_run_data = curr_fulltable(:, VariableNames);

        % Check that subject, session, and run info are consistent and generate warning if not
        expt_name = strsplit(string(unique(eprime_run_data.ExperimentName)), '_'); % Split experiment name to get run number
        edat_run_number = expt_name{3};
        [fname_subject_id, fname_run_number] = split_fname(edat_filename); % Get subject ID and run number from parsed edat filename
        check_ids(edat_filename, folder_subject_id, folder_session_id, fname_subject_id, fname_run_number, unique(eprime_run_data.Subject), unique(eprime_run_data.Session), edat_run_number);

        % Set onset output filename
        onset_filename = [expt_name{1} '_sub-' folder_subject_id '_ses-0' folder_session_id '_' fname_run_number '.mat'];

        % Clean up messy rows
        eprime_run_data = clean_edat(eprime_run_data);

        % Set condition names based on participant choice of now or later
        % 1=now, 2=later
        eprime_run_data.DelayTrial_choice = string(categorical(eprime_run_data.DelayTrial_RESP,1:2,{'now','later'}));
        eprime_run_data.Run_number = repmat(fname_run_number, height(eprime_run_data), 1);
        eprime_run_data.names =  strcat(eprime_run_data.diff, '_', eprime_run_data.DelayTrial_choice);

        % Calculate trial onsets in seconds to 3 significant digits 
        % - run onset is based on difference between DelayTrial onset time and when WaitForTrigger detects scanner trigger 
        eprime_run_data.onsets = round((eprime_run_data.DelayTrial_OnsetTime - eprime_run_data.WaitForTrigger_RTTime)/1000,3);

        % Set durations based on participant RT in seconds to 3 significant digits
        eprime_run_data.durations = round(eprime_run_data.DelayTrial_RT/1000,3);

        % Create condition onsets for SPM
        names = {'easy_later', 'easy_now', 'hard_later', 'hard_now'};
        onsets = cell(1,4);
        durations = cell(1,4);
        for c = 1:length(onsets)
            onsets{c} = eprime_run_data{eprime_run_data.names==names{c},"onsets"}; 
            durations{c} = eprime_run_data{eprime_run_data.names==names{c},"durations"}; 
        end

        % Save onsets.mat file
        save(onset_filename, "names", "onsets", "durations", '-mat');

        % Aggregate all eprime data into one table
        if j == 1 & m==1
            eprime_run_data_all= eprime_run_data; % joined table starts with first entry
        else
            eprime_run_data_all = [eprime_run_data_all; eprime_run_data]; % vertically concatenate runs
        end
        writetable(eprime_run_data_all, fullfile(home, 'delaydiscounting_eprime_data_merged.csv')); % save merged data

    end

end

%% Split edat text output filename to get subject and run
% Assumes naming: Run<number>_mod-<subject_id>-1_parsed.txt
function [subject_id, run_number]=split_fname(filename)
    tmp1 = strsplit(filename, '_'); 
    tmp2 = strsplit(tmp1{2}, '-');
    
    run_number = tmp1{1};
    subject_id = tmp2{2};
end

%% Remove rows at beginning and end of table without trial info
function clean_table=clean_edat(edat_table)
    clean_table = standardizeMissing(edat_table, '?');
    clean_table = rmmissing(clean_table);
end

%% Convoluted way to check that subject ID, session ID, and run number are the same in the data, the folder, and the file name
function check_ids(edat_filename, folder_subject_id, folder_session_id, fname_subject_id, fname_run_number, edat_subject_id, edat_session_id, edat_run_number)

    % Check Subject ID first
    if folder_subject_id ~= fname_subject_id | folder_subject_id ~= string(edat_subject_id) 
        warning(['Subject ID is inconsistent across folder, edat filename, and edat data: ' edat_filename]);
    end
    
    % Check Session ID
    if folder_session_id ~= string(edat_session_id) 
        warning(['Session ID is inconsistent across folder and edat contents: ' edat_filename]);
    end
    
    % Check Run number
    if fname_run_number ~= edat_run_number
        warning(['Run number is inconsistent across edat filename and edat contents: ' edat_filename])
    end

end
