%% Sync_VRandIR
function Sync_VRandIR(IR_FolderPath, VR_FolderPath, Phrases)
% Get all .c3d files from the specified directories
c3dFiles_IR = {dir(fullfile(IR_FolderPath, '*.c3d')).name};
c3dFiles_VR = {dir(fullfile(VR_FolderPath, '*_C.c3d')).name};

matches = struct('c3dIR', {}, 'c3dVR', {}, 'Phrase', {}); % Initialize

% Loop over each phrase to find IR and VR matches
for curPhrase = 1:numel(Phrases)
    PHRASE = Phrases{curPhrase};

    % Find MO and BR files that contain this phrase
    Matches_IR = c3dFiles_IR(contains(c3dFiles_IR, PHRASE));
    Matches_VR = c3dFiles_VR(contains(c3dFiles_VR, PHRASE));

    % Pair up all combinations of matches
    for i = 1:numel(Matches_IR)
        for j = 1:numel(Matches_VR)
            matches(end+1) = struct( ...
                'c3dIR', fullfile(IR_FolderPath, Matches_IR{i}), ...
                'c3dVR', fullfile(VR_FolderPath, Matches_VR{j}), ...
                'Phrase', PHRASE);
        end
    end
end

% Read in c3d files and sync
Sync_VR = {'V_STERNZ', 'V_LLAZ', 'V_RLAZ', 'V_LUAZ', 'V_RUAZ', 'V_LRZ', 'V_RRZ'};
Sync_IR = {'STERN', 'LLA1', 'RLA1', 'LUA1', 'RUA1', 'LRT', 'RRT'};
for k = 1:numel(matches)
    fprintf('Processing phrase %s\n', matches(k).Phrase);
    % Get file paths
    File_IR = matches(k).c3dIR;
    File_VR = matches(k).c3dVR;

    % Read in both files
    Data.(matches(k).Phrase).acq_IR = btkReadAcquisition(File_IR);
    Data.(matches(k).Phrase).Markers_IR = btkGetMarkers(Data.(matches(k).Phrase).acq_IR);
    Data.(matches(k).Phrase).acq_VR = btkReadAcquisition(File_VR);
    Data.(matches(k).Phrase).Markers_VR = btkGetMarkers(Data.(matches(k).Phrase).acq_VR);

    % Sync based on matching markers
    %% XCORR: Find mode sync from all markers and x, y, z
    for curSync = 1:length(Sync_VR)
        SYNC_VR = Sync_VR{curSync};
        SYNC_IR = Sync_IR{curSync};

        for curAxis = 1:3 %['X', 'Y', 'Z']
            if curAxis == 1
                AXIS = 'X';
            elseif curAxis == 2
                AXIS = 'Y';
            else
                AXIS = 'Z';
            end

            SYNC_VR_Data = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR)(:, curAxis);
            SYNC_IR_Data = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR)(:, curAxis);


            [~, ~, Data.(matches(k).Phrase).SyncValue.([SYNC_IR, '_', AXIS])] = ...
                alignsignals(SYNC_VR_Data, SYNC_IR_Data, Method = 'xcorr');

        end % end of curAxis
    end % end of curSync

    SyncValues = cell2mat(struct2cell(Data.(matches(k).Phrase).SyncValue));
    SyncMode = mode(SyncValues);

    % Plot to test current sync
    close all
    figure;
    tiledlayout;
    s = sgtitle(['Method: xcorr, File: ', matches(k).Phrase]); s.Interpreter = 'none'; % Keeps the underscore from being interpreted as a subscript
    for curSync = 1:length(Sync_VR)
        SYNC_VR = Sync_VR{curSync};
        SYNC_IR = Sync_IR{curSync};

        if SyncMode > 0 % Crop IR
            Data.(matches(k).Phrase).Synced_IR.(SYNC_IR) = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR)(SyncMode:end, :);
            Data.(matches(k).Phrase).Synced_VR.(SYNC_VR) = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR);
        elseif SyncMode < 0 % Crop VR
            Data.(matches(k).Phrase).Synced_VR.(SYNC_VR) = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR)(-SyncMode:end, :);
            Data.(matches(k).Phrase).Synced_IR.(SYNC_IR) = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR);
        else % No cropping required
            Data.(matches(k).Phrase).Synced_IR.(SYNC_IR) = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR);
            Data.(matches(k).Phrase).Synced_VR.(SYNC_VR) = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR);
        end % end of if SyncMode

        % Plot X
        nexttile;
        plot(Data.(matches(k).Phrase).Synced_VR.(SYNC_VR)(:, 1))
        hold on
        plot(Data.(matches(k).Phrase).Synced_IR.(SYNC_IR)(:, 1))
        t = title([SYNC_IR, '_X']); t.Interpreter = 'none';

        % Plot Y
        nexttile;
        plot(Data.(matches(k).Phrase).Synced_VR.(SYNC_VR)(:, 2))
        hold on
        plot(Data.(matches(k).Phrase).Synced_IR.(SYNC_IR)(:, 2))
        t = title([SYNC_IR, '_Y']); t.Interpreter = 'none';

        % Plot Z
        nexttile;
        plot(Data.(matches(k).Phrase).Synced_VR.(SYNC_VR)(:, 3))
        hold on
        plot(Data.(matches(k).Phrase).Synced_IR.(SYNC_IR)(:, 3))
        t = title([SYNC_IR, '_Z']); t.Interpreter = 'none';
    end % end of curSync

    Input = input('Do the signals look aligned? \n1: Looks good\n2: Try a second method');

    %% maxpeak: Find mode sync from all markers and x, y, z
    if Input == 2 % Try the maxpeaks method

        for curSync = 1:length(Sync_VR)
            SYNC_VR = Sync_VR{curSync};
            SYNC_IR = Sync_IR{curSync};

            for curAxis = 1:3 %['X', 'Y', 'Z']
                if curAxis == 1
                    AXIS = 'X';
                elseif curAxis == 2
                    AXIS = 'Y';
                else
                    AXIS = 'Z';
                end

                SYNC_VR_Data = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR)(:, curAxis);
                SYNC_IR_Data = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR)(:, curAxis);


                [~, ~, Data.(matches(k).Phrase).SyncValue.([SYNC_IR, '_', AXIS])] = ...
                    alignsignals(SYNC_VR_Data, SYNC_IR_Data, Method = 'maxpeak');

            end % end of curAxis
        end % end of curSync

        SyncValues = cell2mat(struct2cell(Data.(matches(k).Phrase).SyncValue));
        SyncMode = mode(SyncValues);

        % Plot to test current sync
        close all
        figure;
        tiledlayout;
        s = sgtitle(['Method: maxpeak, File: ', matches(k).Phrase]); s.Interpreter = 'none'; % Keeps the underscore from being interpreted as a subscript
        for curSync = 1:length(Sync_VR)
            SYNC_VR = Sync_VR{curSync};
            SYNC_IR = Sync_IR{curSync};

            if SyncMode > 0 % Crop IR
                Data.(matches(k).Phrase).Synced_IR.(SYNC_IR) = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR)(SyncMode:end, :);
                Data.(matches(k).Phrase).Synced_VR.(SYNC_VR) = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR);
            elseif SyncMode < 0 % Crop VR
                Data.(matches(k).Phrase).Synced_VR.(SYNC_VR) = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR)(-SyncMode:end, :);
                Data.(matches(k).Phrase).Synced_IR.(SYNC_IR) = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR);
            else % No cropping required
                Data.(matches(k).Phrase).Synced_IR.(SYNC_IR) = Data.(matches(k).Phrase).Markers_IR.(SYNC_IR);
                Data.(matches(k).Phrase).Synced_VR.(SYNC_VR) = Data.(matches(k).Phrase).Markers_VR.(SYNC_VR);
            end % end of if SyncMode

            % Plot X
            nexttile;
            plot(Data.(matches(k).Phrase).Synced_VR.(SYNC_VR)(:, 1))
            hold on
            plot(Data.(matches(k).Phrase).Synced_IR.(SYNC_IR)(:, 1))
            t = title([SYNC_IR, '_X']); t.Interpreter = 'none';

            % Plot Y
            nexttile;
            plot(Data.(matches(k).Phrase).Synced_VR.(SYNC_VR)(:, 2))
            hold on
            plot(Data.(matches(k).Phrase).Synced_IR.(SYNC_IR)(:, 2))
            t = title([SYNC_IR, '_Y']); t.Interpreter = 'none';

            % Plot Z
            nexttile;
            plot(Data.(matches(k).Phrase).Synced_VR.(SYNC_VR)(:, 3))
            hold on
            plot(Data.(matches(k).Phrase).Synced_IR.(SYNC_IR)(:, 3))
            t = title([SYNC_IR, '_Z']); t.Interpreter = 'none';
        end % end of curSync
        Input = input('Do the signals look aligned? \n1: Looks good\n2: Try a manual method');

    end % end of Input == 2 % Try the maxpeaks method


    %% manual: Find mode sync from all markers and z
    if Input == 2 % Try the manual method
        disp('Add additional method')
    end % end of Input == 2 % Try the maxpeaks method

    %% Trim all markers
    Markers = fieldnames(Data.(matches(k).Phrase).Markers_IR);
    for curMarker = 1:length(Markers)
            Marker = Markers{curMarker};
            %SYNC_IR = Sync_IR{curSync};

            if SyncMode > 0 % Crop IR
                Data.(matches(k).Phrase).Synced_IR.(Marker) = Data.(matches(k).Phrase).Markers_IR.(Marker)(SyncMode:end, :);
            elseif SyncMode < 0 % Crop VR
                Data.(matches(k).Phrase).Synced_IR.(Marker) = Data.(matches(k).Phrase).Markers_IR.(Marker);
            else % No cropping required
                Data.(matches(k).Phrase).Synced_IR.(Marker) = Data.(matches(k).Phrase).Markers_IR.(Marker);
            end % end of if SyncMode
    end

    Markers = fieldnames(Data.(matches(k).Phrase).Markers_VR);
    for curMarker = 1:length(Markers)
        Marker = Markers{curMarker};
        %SYNC_IR = Sync_IR{curSync};

        if SyncMode > 0 % Crop IR
            Data.(matches(k).Phrase).Synced_VR.(Marker) = Data.(matches(k).Phrase).Markers_VR.(Marker);
        elseif SyncMode < 0 % Crop VR
            Data.(matches(k).Phrase).Synced_VR.(Marker) = Data.(matches(k).Phrase).Markers_VR.(Marker)(-SyncMode:end, :);
        else % No cropping required
            Data.(matches(k).Phrase).Synced_VR.(Marker) = Data.(matches(k).Phrase).Markers_VR.(Marker);
        end % end of if SyncMode
    end
    %% Rewrite c3d files

    % Make sure all markers are the same length
    % Collect fieldnames
    vrFields = fieldnames(Data.(matches(k).Phrase).Synced_VR);
    irFields = fieldnames(Data.(matches(k).Phrase).Synced_IR);

    % Find the minimum height across all doubles
    minLen = inf;
    for f = 1:numel(vrFields)
        minLen = min(minLen, size(Data.(matches(k).Phrase).Synced_VR.(vrFields{f}), 1));
    end
    for f = 1:numel(irFields)
        minLen = min(minLen, size(Data.(matches(k).Phrase).Synced_IR.(irFields{f}), 1));
    end
    % Truncate all VR fields
    for f = 1:numel(vrFields)
        Data.(matches(k).Phrase).Synced_VR.(vrFields{f}) = Data.(matches(k).Phrase).Synced_VR.(vrFields{f})(1:minLen, :);
    end
    % Truncate all IR fields
    for f = 1:numel(irFields)
        Data.(matches(k).Phrase).Synced_IR.(irFields{f}) = Data.(matches(k).Phrase).Synced_IR.(irFields{f})(1:minLen, :);
    end

    %btkWriteAcquisition(Data.(matches(k).Phrase).acq_IR,Mocap_file);
    %% Write VR C3D
    acqVR_new = btkNewAcquisition(3, minLen, 1/240);
    for f = 1:numel(vrFields)
        btkAppendPoint(acqVR_new, 'marker', vrFields{f}, Data.(matches(k).Phrase).Synced_VR.(vrFields{f}));
    end
    outFileVR = strrep(matches(k).c3dVR, '.c3d', '_Synced.c3d');
    btkWriteAcquisition(acqVR_new, outFileVR);

    %% Write IR C3D
    acqIR_new = btkNewAcquisition(3, minLen, 1/240);
    for f = 1:numel(irFields)
        btkAppendPoint(acqIR_new, 'marker', irFields{f}, Data.(matches(k).Phrase).Synced_IR.(irFields{f}));
    end
    outFileIR = strrep(matches(k).c3dIR, '.c3d', '_Synced.c3d');
    btkWriteAcquisition(acqIR_new, outFileIR);

    disp([matches(k).Phrase,' synced C3D files written.']);
end
end % end of function Sync_VRandIR(IR_FolderPath, VR_FolderPath)