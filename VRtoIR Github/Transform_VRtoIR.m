% Updated 09-22-25 by SB
% Transforms based on static file with "STATICFINAL" in name
%   Based on the 7 matching marker (names listed in TransformVR function)

function Transform_VRtoIR(IR_FolderPath, VR_FolderPath)
c3dFiles = dir(fullfile(VR_FolderPath, '*.c3d')); % Find all c3d files based on IR
[R, t] = TransformVR(VR_FolderPath, IR_FolderPath); % Find Optimized Transformation

% Loop through each VR c3d file
for curFile = 1:length(c3dFiles)
    FULL_FILE = fullfile(VR_FolderPath, c3dFiles(curFile).name);
    FILE = erase(c3dFiles(curFile).name, '.c3d');

    % Read C3D file
    c3dData_BR = btkReadAcquisition(FULL_FILE);

    % Get rid of unamed markers in the files
    [Data.(FILE), ~] = btkGetPoints(c3dData_BR); % Read in marker data
    Marker_Names = fieldnames(Data.(FILE));
    for i = 1:length(Marker_Names)
        if contains(Marker_Names{i}, 'uname_')
            Data.(FILE) = rmfield(Data.(FILE), Marker_Names{i});
        end
    end

    Marker_Names = fieldnames(Data.(FILE)); % Cleaned up marker names

    % Loop through your marker data fields and apply the transforms
    for i = 1:length(Marker_Names)
        markerPos = Data.(FILE).(Marker_Names{i}); % Append ones for homogeneous coordinates

        % Apply transformations
        transformed_data = (R * markerPos' + t)'; % Rotates then transalates?

        % Update the marker data field with the transformed data (exclude the last column of ones)
        Data.(FILE).(Marker_Names{i}) = transformed_data;
    end

    btkClearPoints(c3dData_BR)
    for i = 1:numel(Marker_Names)
        [pointsupdated, pointsInfoupdated] = btkAppendPoint(c3dData_BR, 'marker', Marker_Names{i}, [Data.(FILE).(Marker_Names{i})]);
    end

    % Save the transformed data to the output folder
    outputFilePath = fullfile(VR_FolderPath, [FILE, '_C.c3d']);
    btkWriteAcquisition(c3dData_BR, outputFilePath);
end
end % end of function