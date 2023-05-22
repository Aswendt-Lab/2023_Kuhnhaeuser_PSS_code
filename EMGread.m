%% EMGread: function to read a single .mat file that is the output from the program called LabScribe
% Author: Aref Kalantari
% Contact: arefks@gmail.com
%Modified: 09/20/2021
function [DataFinal,inputEMG] = EMGread(inputEMG)
%%  Settings
TH = 1; %TH to detect stimulus

Debug = 0; %controls if individual plot should be generated
UseBP = 1; %controls if bandpass should be used
UseNotch = 1; %controls if notch filter should be used
IdentifyIds = 1; %controls if structure of data should be identified
%                or manual set below


% Ids of Data - has to be set, if IdentifyIds=0
timeID = 1;
DataID = 3;
StimulusID = 5;


% Filter Design -> moved to program code due to fs estimation option
LastFs = 0; %Used in Filter design to determine if fs has changed and filter has to be redisigned


% Specify number of samples discarded at end and beginning
DiscardN = 15000;
inputEMG.fs = 20000; %Sampling frequency
inputEMG.Estimatefs = 1; %Determines if sampling frequency should be estimated or not
inputEMG.preN = 30; %Number of samples before stimulus (calculated by time before stimulus/sampling frequency)
inputEMG.postN = 800; %Number of samples after stimulus
inputEMG.filter = 1; %set 1 if data should be filtered with notch filter 50 Hz


%% Filtering with Stimulus
           Path = inputEMG.in_path_re;
           load(Path)
           Data = double(b1);
            %%% Identification of Stimulus and Data Term
            % Works if time is included in array and stimulus has only a few disrete
            % values otherwise IDs have to be defined manually
            if IdentifyIds
                UniqueValues = [];
                for jj = 1:size(Data, 2)
                    UniqueValues = [UniqueValues, length(unique(Data(:, jj)))];
                end
                [~, idx] = sort(UniqueValues);

                timeID = idx(end);
                DataID = idx(end-1);
                StimulusID = idx(1);
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if inputEMG.Estimatefs
                inputEMG.fs = floor(length(Data)/Data(end, timeID));
            end


            if inputEMG.filter
                if inputEMG.fs ~= LastFs
                    if UseBP %Bandpass filter design
                        dFiltBP = designfilt('bandpassfir', 'FilterOrder', 30, ...
                            'CutoffFrequency1', 3, 'CutoffFrequency2', min([10000, floor(0.5*inputEMG.fs-1)]), ...
                            'SampleRate', inputEMG.fs);
                    end
                    if UseNotch
                        dFiltNotch = designfilt('bandstopiir', 'FilterOrder', 80, ...
                            'HalfPowerFrequency1', 43, 'HalfPowerFrequency2', 57, ...
                            'SampleRate', inputEMG.fs);
                    end
                    LastFs = inputEMG.fs;
                end

                if Debug
                    figure()
                    plot(Data(:, DataID), 'DisplayName', 'org');
                    hold on;
                    legend;
                end
                if UseBP %Bandpass filter design
                    sig = (Data(:, DataID)');
                    Data(:, DataID) = filtfilt(dFiltBP, sig)';
                    if Debug
                        plot(Data(:, DataID), 'DisplayName', '+BP');
                    end
                end
                if UseNotch
                    sig = (Data(:, DataID)');
                    Data(:, DataID) = filtfilt(dFiltNotch, sig)';
                    if Debug
                        plot(Data(:, DataID), 'DisplayName', '+Notch');
                    end
                end


            end
            IDX = find(Data(:, StimulusID) > TH); %Discard first 5000 samples
            IDX = IDX(IDX > DiscardN & IDX < (length(Data) - inputEMG.postN - DiscardN));

            IDX2 = [];
            while length(IDX) > 2
                IDX2 = [IDX2, IDX(1)];
                IDX = IDX - IDX(1);
                IDX = IDX(IDX > 10001); % Minimum difference between stimulus
                IDX = IDX + IDX2(end);
            end

            if ~isempty(IDX2)
                
            for ii = 1:length(IDX2)
               % Recordings = [Recordings, Data((IDX2(ii) - inputEMG.preN):(IDX2(ii) + inputEMG.postN), DataID)];
                Recordings(:,ii) =  Data((IDX2(ii) - inputEMG.preN):(IDX2(ii) + inputEMG.postN), DataID);
               
            end
            
            else 
            Recordings = {};
            end
            DataFinal = Recordings;
end
           