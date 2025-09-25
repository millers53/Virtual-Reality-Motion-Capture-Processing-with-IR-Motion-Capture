% Updated 09-22-25 by SB
function CSVtoC3D(VR_FolderPath)
Files_csv = dir(fullfile(VR_FolderPath, '*.csv')); % Only pull paths for csv files

for curFile = 1:length(Files_csv)
    % Read in and prep file
    FILE_Raw = fullfile(VR_FolderPath, Files_csv(curFile).name); % Original filename
    FILE_New = strrep(FILE_Raw, '.csv', '.c3d'); % Name of exported c3d file
    FILE = erase(Files_csv(curFile).name, '.csv'); % Create FILE to be used in structure
    Data.(FILE) = readtable(FILE_Raw);
    Data.(FILE){:, :} = Data.(FILE){:, :}*1000; % Convert units
    Data.(FILE) = Data.(FILE)(3:end, :); % Trim first 2 rows or zeros

    % Find marker list
    Marker_Count = width(Data)/3; % X, Y, and Z component
    Marker_List = []; % Initialize
    x = 1;
    for curMarker = 1:3:width(Data.(FILE))
        Marker_List{x} = Data.(FILE).Properties.VariableNames{curMarker};
        x = x + 1;
    end % end of curMarker

    % Use BTK Toolbox to create and export c3d
    h = btkNewAcquisition(Marker_Count,height(Data.(FILE)),1,1);
    btkSetFrequency(h,240); % Change to your collected frequency
    a = 1; b = 3; % Starting columns from csv
    for jj = 1:length(Marker_List)
        Subset.(Marker_List{jj}) = Data.(FILE){:,a:b};
        a = a+3; b = b+3; % New columns for next marker
        MarkerVal = Subset.(Marker_List{jj});
        btkAppendPoint(h, 'marker', Marker_List{jj}, MarkerVal);
    end
    btkWriteAcquisition(h, FILE_New)

end % end of curFile
end % end of function