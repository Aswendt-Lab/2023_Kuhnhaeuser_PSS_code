%% EMGtool: code to read all .mat files from the program called LabScribe and to create excel result files.
% Author: Aref Kalantari
% Contact: arefks@gmail.com
% Modified: 09/20/2021
% recoded from:
%%%%%%%%%%%%%%
% Collect EMG data
% Author: Felix Schmitt
% Modified: 03/17/2020
%%%%%%%%%%%%%



clear all
close all force
clc
%% User Input 1
inputEMG.foot = ["RF", "LF"];
inputEMG.days = ["Baseline", "P3", "P14", "P28", "P42","P56"]; %
%inputEMG.Groupe = [""]; % If you have a group structure in the naming of the .mat files you can consider it here, else it needs to be empty: ""
inputEMG.Hz = [0.1,0.5,1,2,5]; % set the measuring frequencies: it is important to set them from low to high
inputEMG.in_path = "Y:\TVA_Pyramidenbahnen\T4\EMG";
inputEMG.out_path = "Y:\TVA_Pyramidenbahnen\T4\EMG";
HRange = [145 200]; % Set the time range in which the program should search for the Hwave! example: [550 800] (microseconds)
MRange = [40 80]; % Set the time range in which the program should search for the Hwave! example: [550 800] (microseconds)
Key = 1; %if key is 1 then the M wave is used as reference, if Key is 0 then the H wave is used as reference
ExperimentType = 'Chemogenteics'; %Only for the Excel file naming
Region = 'IC';
%% User Input 2
inputEMG.fs = 20000; %Sampling frequency
inputEMG.Estimatefs = 1; %Determines if sampling frequency should be estimated or not
inputEMG.preN = 30; %Number of samples before stimulus (calculated by time before stimulus/sampling frequency)
inputEMG.postN = 800; %Number of samples after stimulus
inputEMG.filter = 1; %set 1 if data should be filtered with notch filter 50 Hz
% Data has to be sorted in {path}/{group}/{day} to be processed
%% GET ALL THE DATA
disp("Starting to process the data ...");
O = 1;
foot = inputEMG.foot;
days = inputEMG.days;
%inputGroupe = inputEMG.Groupe;
Hz = inputEMG.Hz;
% Creating the data path
%for g_index = 1:length(inputGroupe)
    for d_index = 1:length(days)

        for limb_index = 1:length(foot)
            tic
            for freq_channel = 1:length(Hz)
                cur_path = fullfile(inputEMG.in_path,days(d_index),"*");
                cur_path = strcat(cur_path,foot(limb_index),"*-",num2str(Hz(freq_channel)),'Hz.mat');
                mat = dir(cur_path);
                for animal_number = 1:length(mat)

                    inputEMG.in_path_re = fullfile(mat(animal_number).folder,mat(animal_number).name);
                    [Data,inputEMG] = EMGread(inputEMG);
                    if ~isempty(Data)

                        M_max = max(Data(MRange(1):MRange(2),:),[],1);
                        m_min = min(Data(MRange(1):MRange(2),:),[],1);
                        M_diff_temp = abs(M_max - m_min);
                        [SortM,Index_M] = sort(M_diff_temp,'descend');

                        H_max = max(Data(HRange(1):HRange(2),:),[],1);
                        H_min = min(Data(HRange(1):HRange(2),:),[],1);
                        H_diff_temp = abs(H_max - H_min);
                        [SortH,Index_H] = sort(H_diff_temp,'descend');
                        a = length(Index_M);
                        if a < 5
                            continue
                        end
                        if Key == 1
                            INDEX = Index_M(1:5);
                        else
                            INDEX = Index_H(1:5);
                        end

                        SortM_5 = M_diff_temp(INDEX);
                        M_diff(animal_number,freq_channel,:,limb_index,d_index) = SortM_5;

                        SortH_5 = H_diff_temp(INDEX);
                        H_diff(animal_number,freq_channel,:,limb_index,d_index) = SortH_5;

                    end
                end

            end
            toc
        end
    end
%end

%% Saving Path Cunstruction
path_main = [ inputEMG.out_path  + '\_Evaluation\Results_Excel'];
if ~exist(path_main, 'dir')
    mkdir(path_main)
end
%% Replacing Zeros with nan values
M_diff_save = M_diff;
H_diff_save = H_diff;

M_diff(M_diff == 0) = nan;
H_diff(H_diff == 0) = nan;
%% Calculating H/M Ratio
HM_Ratio = H_diff./M_diff;
%% Creating Table coloum Information
O = 1;

S = size(M_diff);
%for g_index = 1:length(inputGroupe)
    for d_index = 1:length(days)
        for limb_index = 1:length(foot)

            cur_path = fullfile(inputEMG.in_path,days(d_index),"*");
            cur_path = strcat(cur_path,foot(limb_index),"*-",num2str(Hz(freq_channel)),'Hz.mat');
            mat = dir(cur_path);
            for animal_number = 1:length(mat)
                for reps = 1:S(3)
                    Number{O} = reps;
                    Mmax_f0d1Hz{O} =  M_diff(animal_number,1,reps,limb_index,d_index);
                    Mmax_f0d5Hz{O} =  M_diff(animal_number,2,reps,limb_index,d_index);
                    Mmax_f1Hz{O} =  M_diff(animal_number,3,reps,limb_index,d_index);
                    Mmax_f2Hz{O} =  M_diff(animal_number,4,reps,limb_index,d_index);
                    Mmax_f5Hz{O} =  M_diff(animal_number,5,reps,limb_index,d_index);

                    Hmax_f0d1Hz{O} =  H_diff(animal_number,1,reps,limb_index,d_index);
                    Hmax_f0d5Hz{O} =  H_diff(animal_number,2,reps,limb_index,d_index);
                    Hmax_f1Hz{O} =  H_diff(animal_number,3,reps,limb_index,d_index);
                    Hmax_f2Hz{O} =  H_diff(animal_number,4,reps,limb_index,d_index);
                    Hmax_f5Hz{O} =  H_diff(animal_number,5,reps,limb_index,d_index);

                    HM_Ratio_f0d1Hz{O} =  HM_Ratio(animal_number,1,reps,limb_index,d_index);
                    HM_Ratio_f0d5Hz{O} =  HM_Ratio(animal_number,2,reps,limb_index,d_index);
                    HM_Ratio_f1Hz{O} =  HM_Ratio(animal_number,3,reps,limb_index,d_index);
                    HM_Ratio_f2Hz{O} =  HM_Ratio(animal_number,4,reps,limb_index,d_index);
                    HM_Ratio_f5Hz{O} =  HM_Ratio(animal_number,5,reps,limb_index,d_index);

                    O = O+1;
                end
            end
        end
    end
%end



O = 1;
%for g_index = 1:length(inputGroupe)
    for d_index = 1:length(days)
        for limb_index = 1:length(foot)


            cur_path = fullfile(inputEMG.in_path,days(d_index),"*");
            cur_path = strcat(cur_path,foot(limb_index),"*-",num2str(Hz(freq_channel)),'Hz.mat');
            mat = dir(cur_path);

            for animal_number = 1:length(mat)
                for reps = 1:S(3)
                    if isempty(mat)
                        Names{O} = "Empty Data";
                    else
                        splits=strsplit(mat(animal_number).name,"-");
                        fullfilename=strjoin(splits(1:end-1),"-");
                        Name_temp = fullfilename;
                        Names{O} = [Name_temp];
                        Limb{O} = foot(limb_index);
                        TimePoint{O} = days(d_index);
                        Group{O} = "NoGroup";
                    end
                    O = O+1;
                end
            end
        end
    end
%end


%% Creating Excelsheets

Animal_ID = string(Names);


S = size(M_diff);

filename = strcat(path_main,'\','Results_Mmax&Hmax_',ExperimentType,'_',Region,'.xlsx');
filename2 = strcat(path_main,'\','Results_HMRatio_',ExperimentType,'_',Region,'.xlsx');


T = table(Animal_ID',Number',Limb',TimePoint',Group',Mmax_f0d1Hz',Mmax_f0d5Hz',Mmax_f1Hz',Mmax_f2Hz',Mmax_f5Hz',...
    Hmax_f0d1Hz',Hmax_f0d5Hz',Hmax_f1Hz',Hmax_f2Hz',Hmax_f5Hz');

T2 =    table(Animal_ID',Number',Limb',TimePoint',Group', HM_Ratio_f0d1Hz', HM_Ratio_f0d5Hz',...
    HM_Ratio_f1Hz', HM_Ratio_f2Hz', HM_Ratio_f5Hz');

T.Properties.VariableNames(1,1) = {'Animal_ID'};
T.Properties.VariableNames(1,2) = {'Replications'};
T.Properties.VariableNames(1,3) = {'Limb'};
T.Properties.VariableNames(1,4) = {'TimePoint'};
T.Properties.VariableNames(1,5) = {'Group'};


T.Properties.VariableNames(1,6) = {'Mmax_0.1Hz'};
T.Properties.VariableNames(1,7) = {'Mmax_0.5Hz'};
T.Properties.VariableNames(1,8) = {'Mmax_1Hz'};
T.Properties.VariableNames(1,9) = {'Mmax_2Hz'};
T.Properties.VariableNames(1,10) = {'Mmax_5Hz'};

T.Properties.VariableNames(1,11) = {'Hmax_0.1Hz'};
T.Properties.VariableNames(1,12) = {'Hmax_0.5Hz'};
T.Properties.VariableNames(1,13) = {'Hmax_1Hz'};
T.Properties.VariableNames(1,14) = {'Hmax_2Hz'};
T.Properties.VariableNames(1,15) = {'Hmax_5Hz'};

T2.Properties.VariableNames(1,1) = {'Animal_ID'};
T2.Properties.VariableNames(1,2) = {'Replications'};
T2.Properties.VariableNames(1,3) = {'Limb'};
T2.Properties.VariableNames(1,4) = {'TimePoint'};
T2.Properties.VariableNames(1,5) = {'Group'};

T2.Properties.VariableNames(1,6) = {'HM_Ratio_0.1Hz'};
T2.Properties.VariableNames(1,7) = {'HM_Ratio_0.5Hz'};
T2.Properties.VariableNames(1,8) = {'HM_Ratio_1Hz'};
T2.Properties.VariableNames(1,9) = {'HM_Ratio_2Hz'};
T2.Properties.VariableNames(1,10) = {'HM_Ratio_5Hz'};
disp("%%%%%END OF CALCULATIONS%%%%%");

writetable(T,filename)
writetable(T2,filename2)


%%





