function images = genFontChars(dataList)
    FILE_NAMES = dataList.ALLnames;
    DATA_DIM = [50, 35];

    images = cell(1, length(FILE_NAMES));
    
    % Read all images into memory
    parfor i = 1:size(FILE_NAMES,1)
        %if mod(i,1000) == 0
            fprintf('Processing image %d of %d\n', i, numel(FILE_NAMES));
        %end
        currFile = strcat(FILE_NAMES(i, :), '.png');
        currFilePath = fullfile('EnglishFnt','English', 'Fnt', currFile);
        %currFilePath
        currImg = imread(currFilePath);
        images{i} = cropAndClean(currImg, DATA_DIM);
    end
end