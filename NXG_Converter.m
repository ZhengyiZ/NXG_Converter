addpath( genpath('func') );

userPathSplit = split(userpath, filesep);
newPath = [userPathSplit{1} filesep userPathSplit{2} filesep userPathSplit{3} filesep 'pictures'];
selPath = uigetdir( newPath, 'Please select a folder to convert NXG files...' );

if selPath == 0
    return;
end

allFile = dir( fullfile( selPath, '*.nxg' ) );
if isempty( allFile )
    error('There are no convertible files under the selected folder');
end

% group = 'readnxg';
% pref =  'ExtraData';
% title = 'Show Extra Data';
% quest = {'Do you want to keep the extra data?'};
% pbtns = {'Yes', 'No'};
% 
% [pval, tf] = uigetpref(group, pref, title, quest, pbtns,...
%     'DefaultButton', 'nobtn');
% showExtraData = strcmp(pval, 'yes');

outPath = fullfile(selPath, 'Converted');
mkdir( outPath );

% Extra
outPathExtra = fullfile(selPath, 'ConvertedExtra');
mkdir( outPathExtra );
% Extra

fileNum = length(allFile);
TWB = Timerwaitbar(fileNum, 'Converting NXG to TIF...');
failureCount = 0;
failureFile = cell(0);
for i = 1:fileNum

    try
        [data, metaInfo] = readnxg( fullfile(selPath, allFile(i).name) );
        % Extra
        dataExtra = readnxg( fullfile(selPath, allFile(i).name), true );
        % Extra
        if contains( metaInfo.DataType, 'Confocal' )
            if size(data, 4) > 1
                outFileName = [fullfile(outPath, allFile(i).name(1:end-4)) '_Hex.tiff'];
                writeHexImage( data, outFileName );
                % Extra
                outFileExtraName = [fullfile(outPathExtra, allFile(i).name(1:end-4)) '_Hex.tiff'];
                writeHexImage( dataExtra, outFileExtraName );
                % Extra
            end
            outFileName = [fullfile(outPath, allFile(i).name(1:end-4)) '.tiff'];
            writeMultiPage( sum(data, 4), outFileName );
            % Extra
            outFileExtraName = [fullfile(outPathExtra, allFile(i).name(1:end-4)) '.tiff'];
            writeMultiPage( sum(dataExtra, 4), outFileExtraName );
            % Extra
        elseif contains( metaInfo.DataType, 'LPM' )
            if size(data, 5) > 1 % Multiple Detectors
                outFilePrefix = [fullfile(outPath, allFile(i).name(1:end-4) ) '_Hex'];
                writeHexLPM( data, outFilePrefix );
                % Extra
                outFileExtraPrefix = [fullfile(outPathExtra, allFile(i).name(1:end-4) ) '_Hex'];
                writeHexLPM( dataExtra, outFileExtraPrefix );
                % Extra
            end
            outFilePrefix = fullfile(outPath, allFile(i).name(1:end-4) );
            writeLPM( sum(data, 5), outFilePrefix );
            % Extra
            outFileExtraPrefix = [fullfile(outPathExtra, allFile(i).name(1:end-4) )];
            writeLPM( sum(dataExtra, 5), outFileExtraPrefix );
            % Extra
        end
    catch
        warning(['An error occurred while reading ' allFile(i).name]);
        failureCount = failureCount + 1;
        failureFile{failureCount} = allFile(i).name;
    end
    
    TWB.update();

end

TWB.delete();

system(['explorer.exe ' selPath]);

% if isempty(failureFile)
%     resStr = sprintf('Found %d NXG files, all converted successfully', fileNum);
%     if showExtraData
%         resStr = [resStr ' (with extra data)'];
%     end
% else
%     if showExtraData
%         resStr = sprintf(['Found %d NXG files (converted with extra data),' ...
%             ' %d of which failed:\n'], fileNum, failureCount);
%     else
%         resStr = sprintf(['Found %d NXG files,' ...
%             ' %d of which failed:\n'], fileNum, failureCount);
%     end
%     for i = 1:failureCount-1
%         resStr = sprintf([resStr '- ' failureFile{i} '\n']);
%     end
%     resStr = [resStr '- ' failureFile{end}];
% end
if isempty(failureFile)
    resStr = sprintf('Found %d NXG files, all converted successfully', fileNum);
else
    resStr = sprintf(['Found %d NXG files,' ...
        ' %d of which failed:\n'], fileNum, failureCount);
    for i = 1:failureCount-1
        resStr = sprintf([resStr '- ' failureFile{i} '\n']);
    end
    resStr = [resStr '- ' failureFile{end}];
end

msgbox(resStr, 'Result');

function writeHexLPM( image5D, filePrefix )
if size(image5D, 4) > 1
    for i = 1:size(image5D, 4)
        fileName = [ filePrefix, '_EBP', num2str(i), '.tiff' ];
        writeHexImage( squeeze(image5D(:,:,:,i,:)), fileName );
    end
else
    fileName = [ filePrefix, '.tiff' ];
    writeHexImage( squeeze(sum(image5D, 4)), fileName );
end
end

function writeLPM( image4D, filePrefix )

if size(image4D, 4) > 1
    for i = 1:size(image4D, 4)
        fileName = [ filePrefix, '_EBP', num2str(i), '.tiff' ];
        writeMultiPage( image4D(:,:,:,i), fileName );
    end
else
    fileName = [ filePrefix, '.tiff' ];
    writeMultiPage( sum(image4D, 4), fileName );
end

end

function writeHexImage( image4D, fileName )

concatenatedImage = [];
for i = 1:size(image4D, 4)
    images = squeeze(image4D(:, :, :, i));
    concatenatedImage = cat(2, concatenatedImage, images);
end
writeMultiPage( concatenatedImage, fileName );

end

function writeMultiPage( image3D, fileName )

imwrite( uint16(image3D(:,:,1)), fileName, "tif", "WriteMode", "overwrite", "Compression", "lzw" );
if size(image3D, 3) > 1
    for j = 2:size(image3D, 3)
        imwrite(uint16(image3D(:,:,j)), fileName, "tif", "WriteMode", "append", "Compression", "lzw" );
    end
end

end