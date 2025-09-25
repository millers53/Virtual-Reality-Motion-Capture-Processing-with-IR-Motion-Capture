%% Combine VR and IR 
function Combine_VRandIR(IR_FolderPath, VR_FolderPath, Phrases)
% Create Combined Folder
[parentPath, ~, ~] = fileparts(IR_FolderPath);
Combined_FolderPath = fullfile(parentPath, 'Combined - Copy');
mkdir(Combined_FolderPath)

% Get all .c3d files from the specified directories
c3dFiles_IR = {dir(fullfile(IR_FolderPath, '*_Synced.c3d')).name};
c3dFiles_VR = {dir(fullfile(VR_FolderPath, '*_Synced.c3d')).name};

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

% Read in, combine and rewrite
for curFile = 1:numel(matches)
    fprintf('Processing phrase %s\n', matches(curFile).Phrase);
    % Get file paths
    File_IR = matches(curFile).c3dIR;
    File_VR = matches(curFile).c3dVR;

    % Read in both files
    Data.(matches(curFile).Phrase).acq_IR = btkReadAcquisition(File_IR);
    Data.(matches(curFile).Phrase).Markers_IR = btkGetMarkers(Data.(matches(curFile).Phrase).acq_IR);
    Data.(matches(curFile).Phrase).acq_VR = btkReadAcquisition(File_VR);
    Data.(matches(curFile).Phrase).Markers_VR = btkGetMarkers(Data.(matches(curFile).Phrase).acq_VR);

    % Combine
    Data.(matches(curFile).Phrase).Markers = Data.(matches(curFile).Phrase).Markers_VR;
    f = fieldnames(Data.(matches(curFile).Phrase).Markers_IR);
    for k = 1:numel(f)
        Data.(matches(curFile).Phrase).Markers.(f{k}) = Data.(matches(curFile).Phrase).Markers_IR.(f{k});
    end

    % Write Combined File
    AllFields = fieldnames(Data.(matches(curFile).Phrase).Markers);
    acq_new = btkNewAcquisition(3, height(Data.(matches(curFile).Phrase).Markers.(AllFields{1})), 1/240);
    for f = 1:numel(AllFields)
        btkAppendPoint(acq_new, 'marker', AllFields{f}, Data.(matches(curFile).Phrase).Markers.(AllFields{f}));
    end
    [~, name, ext] = fileparts(matches(curFile).c3dIR);
    outFileIR = [Combined_FolderPath, '/', erase(name, '_MO_Synced'), ext];
    btkWriteAcquisition(acq_new, outFileIR);

    disp([matches(curFile).Phrase,' synced C3D files written.']);
end % end of curFile
end
