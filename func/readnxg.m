function [data, metaInfo] = readnxg(filename, showExtraData)
% READNXG  the NXG format reader.
%   data = READNXG(filename) reads the valid data from 'filename'.
%
%   [data, meta] = READNXG(filename, true) reads all data from 'filename'
%                                          and returns the meta data.
%
%   Note that 'filename' must an absolute path, unless it is in pwd.
%   See also PWD.
%
%   Version : 1.0
%   Author  : Zhengyi Zhan
%   Email   : zhanzy@zju.edu.cn
%   Release : June 2, 2023

if ~exist('showExtraData', 'var')
    showExtraData = false;
end

file = split(filename, filesep);
file = file{end};

% process header infomation
fid = fopen( filename );
headerLines = 1;
try
    while ~contains( fgetl(fid), '[NXGData]', 'IgnoreCase', true )
        headerLines = headerLines + 1;
    end
catch
    error(['Start-of-header identifier not found in ' file]);
end

tLine = fgetl(fid);
headerLines = headerLines + 1;
while ~strcmp( tLine, '# END_HEADER' )
    try
        idx = strfind( tLine, ' = ');
        metaInfo.( strrep(tLine(1:idx-1), ' ', '') ) = tLine(idx+3:end);
        tLine = fgetl(fid);
        headerLines = headerLines + 1;
    catch
        error(['End-of-header identifier not found in ' file]);
    end
end

fclose( fid );

try 
    version = str2double( metaInfo.Version );
    type = metaInfo.DataType;
catch
    error(['Meta information for version or datatype not found in ' file]);
end

rawData = readmatrix( filename, 'FileType', 'text', 'NumHeaderLines',...
    headerLines, 'OutputType', 'uint16' );

if version == 1
    data = reorganizeNXG1( rawData, metaInfo, file, type, showExtraData );
else
    error( ['The NXG data version of ' file ' is %.1f,' ...
        ' newer than the current NXG reader version (1.0)'], version );
end

end

function [data, format] = reorganizeNXG1( rawData, metaInfo, file, type, showExtraData )

if contains( type, 'Confocal' )

    % read the nessary variables from meta
    try
        y = str2double( metaInfo.yPoints );
        frames = str2double( metaInfo.Frames );
        deteDevNum = str2double( metaInfo.DeteDeviceNum );
        wsa = str2double( metaInfo.WaitSlowAxis );
        biDir = contains( metaInfo.ScanMethod, 'Bi-direction' );
        if ~showExtraData
            x = str2double( metaInfo.xPoints );
            dpb = str2double( metaInfo.DiscardedPixelsB );
        end
    catch
        error(['The header information is incomplete in ' file]);
    end

    % check integrity
    frameY = round( y + wsa );
    if frameY * frames * deteDevNum ~= size(rawData,1)
        frameExist = size(rawData, 1) / frameY / deteDevNum;
        if fix( frameExist ) == 0
            error([file ' does not contain a complete frame.']);
        else
            warning([file ' is incomplete: %.1f frames.'], frameExist );
            frames = fix( frameExist );
        end
    end

    % reorganize array
    if showExtraData
        data = uint16( zeros(frameY, size(rawData, 2), frames, deteDevNum) );
        for i = 1:frames
            for j = 1:deteDevNum
                staIdx = (i-1)*frameY*deteDevNum + j;
                endIdx = i*frameY*deteDevNum;
                data(:,:,i,j) = rawData( staIdx : deteDevNum : endIdx, :);
            end
        end
    else
        data = uint16( zeros(y, x, frames, deteDevNum) );
        for i = 1:frames
            for j = 1:deteDevNum
                staIdx = (i-1)*y*deteDevNum + i*wsa*deteDevNum + j;
                endIdx = i*(y+wsa)*deteDevNum;
                data(:,:,i,j) = rawData( staIdx : deteDevNum : endIdx, ...
                    dpb+1 : dpb+x);
            end
        end
    end

    if deteDevNum > 1
        format = sprintf(['Y: %d pixels, X: %d pixels, %d frames,' ...
            ' %d detectors'], size(data, 1), size(data, 2), frames, deteDevNum);
    else
        format = sprintf('Y: %d pixels, X: %d pixels, %d frames', ...
            size(data, 1), size(data, 2), frames);
    end

    % flip even rows, if bi-directional
    if biDir
        flipRows = 2 : 2 : size(data, 1);
        data(flipRows, :, :, :) = flip( data(flipRows, :, :, :), 2 );
    end

elseif contains( type, 'LPM' )

    % read the nessary variables from meta
    try
        x = str2double( metaInfo.xPoints );
        y = str2double( metaInfo.yPoints );
        frames = str2double( metaInfo.Frames );
        deteDevNum = str2double( metaInfo.DeteDeviceNum );
        EBPNum = str2double( metaInfo.EBPNum);
    catch
        error(['The header information is incomplete in ' file]);
    end

    % check integrity
    if y * frames * deteDevNum ~= size(rawData, 1)
        frameExist = size(rawData, 1) / y / deteDevNum;
        if fix( frameExist ) == 0
            error([file ' does not contain a complete frame.']);
        else
            warning([file ' is incomplete: %.1f frames.'], frameExist );
            frames = fix( frameExist );
        end
    end

    % extract array
    waitTmp = rawData(:, 1:2:end);
    deteTmp = rawData(:, 2:2:end);

    % reorganize array
    if showExtraData
        data = uint16( zeros(y, 2*x, frames, EBPNum, deteDevNum) );
        for i = 1:frames
            for j = 1:EBPNum
                for k = 1:deteDevNum
                    data(:, :, i, j, k) = [deteTmp( (i-1)*deteDevNum*y+k : ...
                        deteDevNum : i*deteDevNum*y, j:EBPNum:end ) ...
                        waitTmp( (i-1)*deteDevNum*y+k : ...
                        deteDevNum : i*deteDevNum*y, j:EBPNum:end )];
                end
            end
        end
    else
        data = uint16( zeros(y, x, frames, EBPNum, deteDevNum) );
        for i = 1:frames
            for j = 1:EBPNum
                for k = 1:deteDevNum
                    data(:, :, i, j, k) = deteTmp( (i-1)*deteDevNum*y+k : ...
                        deteDevNum : i*deteDevNum*y, j:EBPNum:end );
                end
            end
        end
    end

    if EBPNum > 1 && deteDevNum > 1
        format = sprintf( ['Y: %d pixels, X: %d pixels, %d frames, ' ...
            'EBP-%d, %d detectors'], size(data, 1), size(data, 2), ...
            frames, EBPNum, deteDevNum );
    elseif deteDevNum > 1
        data = squeeze(data);
        format = sprintf( ['Y: %d pixels, X: %d pixels, %d frames, ' ...
            '%d detectors'], size(data, 1), size(data, 2), frames, deteDevNum );
    elseif EBPNum > 1
        format = sprintf( ['Y: %d pixels, X: %d pixels, %d frames, ' ...
            'EBP-%d'], size(data, 1), size(data, 2), frames, EBPNum );
    else
        format = sprintf( 'Y: %d pixels, X: %d pixels, %d frames', ...
            size(data, 1), size(data, 2), frames );
    end

else
    error(join(["The type '" type "' in " file " is not supported currently."],''));
end

end
