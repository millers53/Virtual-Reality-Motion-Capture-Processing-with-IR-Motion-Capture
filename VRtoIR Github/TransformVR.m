function [R, t] = TransformVR(VR_FolderPath, IR_FolderPath)
% Use BTK to pull in average static x,y,z values
files = dir(IR_FolderPath);
cd(IR_FolderPath)
filenames = {files.name};
currentFile = filenames(contains(filenames, 'STATICFINAL'));
IR_c3dData = btkReadAcquisition(char(currentFile));
IR_markers  = btkGetMarkers(IR_c3dData);

files = dir(VR_FolderPath);
filenames = {files.name};
cd(VR_FolderPath)
currentFile = filenames(contains(filenames, 'STATICFINAL_VR.c3d'));
VR_c3dData = btkReadAcquisition(char(currentFile));
VR_markers  = btkGetMarkers(VR_c3dData);

for j = 1:2
    if j == 1
        data = IR_markers;
    else
        data = VR_markers;
    end
    filenames = fieldnames(data);
    for ii = 1:length(filenames)
        if size(data.(filenames{ii}), 1) >1
        data.(filenames{ii}) = mean(data.(filenames{ii}));
        end

    end

    if j == 1
        IR_markers = data;
    else
        VR_markers = data;
    end
end

% Vertcat the IR and VR with the 7 overlapping markers in the same order 
%   (STERN, RUA, RLA, RR, LUA, LLA, LR)
IR_markers = [IR_markers.STERN; IR_markers.RUA1; IR_markers.RLA1; IR_markers.RRT; IR_markers.LUA1; IR_markers.LLA1; IR_markers.LRT];

% Find the correct naming convention used
if isfield(VR_markers, 'V_STERNZ')
    %disp('Regular VR Names')
    VR_markers = [VR_markers.V_STERNZ; VR_markers.V_RUAZ; VR_markers.V_RLAZ; VR_markers.V_RRZ; VR_markers.V_LUAZ; VR_markers.V_LLAZ; VR_markers.V_LRZ];
   
elseif isfield(VR_markers, 'CHESTZ') && isfield(VR_markers, 'V_RUAZ')
    %disp('CHEST, but everything else is regular VR names')
    VR_markers = [VR_markers.CHESTZ; VR_markers.V_RUAZ; VR_markers.V_RLAZ; VR_markers.V_RRZ; VR_markers.V_LUAZ; VR_markers.V_LLAZ; VR_markers.V_LRZ];
else
    %disp('Old VR Names')
    VR_markers = [VR_markers.chest_z; VR_markers.elbow_r_z; VR_markers.wrist_r_z; VR_markers.controller_r_z; VR_markers.elbow_l_z; VR_markers.wrist_l_z; VR_markers.controller_l_z];
    
end

% Step 1: Find the centroids of both systems
centroid_VR = mean(VR_markers, 1);
centroid_IR = mean(IR_markers, 1);

% Step 2: Center the marker coordinates by subtracting centroids
centered_VR = VR_markers - centroid_VR;
centered_IR = IR_markers - centroid_IR;

% Step 3: Compute the covariance matrix
covariance_matrix = centered_IR' * centered_VR;

% Step 4: Perform Singular Value Decomposition (SVD)
[U, ~, V] = svd(covariance_matrix);

% Step 5: Compute the optimal rotation matrix
R = V * U';

% Ensure a proper rotation (det(R) should be +1)
if det(R) < 0
    V(:, 3) = -V(:, 3);
    R = V * U';
end

% Step 6: Compute the translation vector
t = centroid_IR' - R * centroid_VR';
end