%% Github general
clear, clc, close all
warning ('off','all');

% Define folder paths
VR_FolderPath = 'G:\Shared drives\VR Rehab for SCI\Subject CMZs and Collection Files\TBI01\20240716\Raw Files\VR - Copy';
IR_FolderPath = 'G:\Shared drives\VR Rehab for SCI\Subject CMZs and Collection Files\TBI01\20240716\Raw Files\MO - Copy';
% List any phrase included in the title of motion files that need synced
Phrases = {'MIR1', 'MIR2', 'MIR3', 'OPP1', 'OPP2', 'OPP3', 'UNI1', 'UNI2', 'UNI3',...
    'CON1','CON2','CON3','BIL1','BIL2','BIL3',...
    'KBLOCK', 'FAST','PAIRED',...
    'PBLOCK1','PBLOCK2','RAND1','RAND2'};

%%
CSVtoC3D(VR_FolderPath); % Convert csv from Brekel to C3D (DONE HERE IF NO IR SYNC)
Transform_VRtoIR(IR_FolderPath, VR_FolderPath) % Transform the VR to match the IR
Sync_VRandIR(IR_FolderPath, VR_FolderPath, Phrases) % Temporally sync VR and IR, rewrite c3d files
Combine_VRandIR(IR_FolderPath, VR_FolderPath, Phrases)