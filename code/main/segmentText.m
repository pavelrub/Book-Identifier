function [seg_spine] = segmentText( spine, noiseRemoval )
h = waitbar(0,'Please wait...');
% Text segmentation

%spine = imresize(spine,3);
%spine = imsharpen(spine,'Radius',2,'Amount',3);

% convert spine to grayscale and equalize histogram
spine_sz = size(spine);
%spine_hsv=rgb2hsv(spine);
spine_gray = rgb2gray(spine);
%spine_gray=imadjust(spine_gray);
spine_gray = adapthisteq(spine_gray);
spine_gray_sz = size(spine_gray);

% initialize binary spine image with zeros
spine_th = false(spine_gray_sz);

% set window size for thresholding along the spine
window_incr = 40;
window_h = spine_sz(1)/window_incr;
window_w = spine_sz(2);

% crap that doesn't work
%     [x, y] = size(spine_gray);
%     binImg = adaptivethreshold(spine_gray, round(0.01 * x * y), graythresh(spine_gray) / 1.75);
%     figure, imshow(binImg);

% move window along the spine and threhold each window
for k=1:window_incr
    % crop current window, sharpen and conver to grayscale
    cut_from_r = window_h*(k-1)+1;
    cut_to_r = window_h*k+1;
    window_img = imcrop(spine, [1, cut_from_r, window_w, cut_to_r-cut_from_r ]);

    window_img_g = rgb2gray(window_img);
    window_img_g = imsharpen(window_img_g);%,'Radius',0.5,'Amount',1);
    %window_img_g = imadjust(window_img_g);


    % if the intensity variation within the window is small - do
    % nothing. Otherwise, threshold using Otsu's method.
    color_diff = max(window_img_g(:))-min(window_img_g(:));
    if color_diff>50
        thresh = multithresh(window_img_g,1);
    else
        thresh=0;
    end
    seg_window = imquantize(window_img_g,thresh);

    % create binary mask based on thresholding results
    window_img_th = seg_window == 1;

    % check which color extends further horizontaly, and flip colors if
    % necessary (we want the 1s to be text, so we expect them not to
    % extend all the way to the edges)

    % find horizontal positions of 5 rightmost and leftmost "zero" 
    % pixels, calculate the average of each side, then substract
    [row1,col1] = find(window_img_th==0,5,'first');
    [row2,col2] = find(window_img_th==0,5,'last');
    if isempty(col1) || isempty(col2)
        max_zero_distance = 0;
    else
        avg_right = sum(col2)/size(col2,1);
        avg_left = sum(col1)/size(col1,1);
        max_zero_distance = avg_right-avg_left;
    end

    % find horizontal positions of the 5 rightmost and leftmost 
    % "one" pixels, calculate the average of each side, then substract
    [row1,col1] = find(window_img_th==1,5,'first');
    [row2,col2] = find(window_img_th==1,5,'last');
    if isempty(col1) || isempty(col2)
        max_one_distance = 0;
    else
        avg_right = sum(col2)/size(col2,1);
        avg_left = sum(col1)/size(col1,1);
        max_one_distance = avg_right-avg_left;
    end

    % calculate number of pixels for each color
    zero_count = sum(window_img_th(:)==0);
    one_count = sum(window_img_th(:)==1);


    % calculate difference between 1 pixels' extent and 0 pixels's
    % extent
    one_zero_diff = max_one_distance - max_zero_distance;
    dist_lim = 5;

    % if the difference is higher than "dist-lim" - the 1 pixels are
    % surrouding the 0 pixels, so swap colors
    if one_zero_diff > dist_lim
        window_img_th = ~window_img_th;
    else 
        if one_zero_diff>-dist_lim && one_count > zero_count 
            window_img_th = ~window_img_th;
        end          
    end

    % paste the processed window back to the whole spine image
    spine_th(cut_from_r:cut_from_r+size(window_img_th,1)-1,:)=window_img_th(:,:);

end
%spine_th = bwmorph(spine_th,'diag');

if (noiseRemoval == 1)
    % apply further filtering based on region properties
    connComp = bwconncomp(spine_th); % Find connected components

    % extract region properties for each connected component
    stats = regionprops(connComp,'Area','Eccentricity','Solidity', 'Extent', 'BoundingBox','PixelIdxList');

    % calculate some more bounding box properties
    bboxes = vertcat(stats.BoundingBox);
    bboxes_width = bboxes(:,3)'; % matrix of bounding box widths
    bboxes_height = bboxes(:,4)'; % matrix of bounding box heights
    bboxes_aspect = (bboxes(:,3)./bboxes(:,4))'; % matrix of bounding box aspect ratios
    bboxes_area = (bboxes(:,3).*bboxes(:,4))'; % matrix of bounding box areas

    % remove areas with too wide bounding box
    spine_th(vertcat(connComp.PixelIdxList{[bboxes_width] > spine_sz(2)/1.001 })) = 0;
    spine_th(vertcat(connComp.PixelIdxList{[bboxes_width] > spine_sz(2)/1.4 ...
        & [bboxes_aspect] > 5 })) = 0;

    % remove areas with too high bounding boxes
    spine_th(vertcat(connComp.PixelIdxList{[bboxes_height] > spine_sz(2)/1.1})) = 0;
    %spine_th(vertcat(connComp.PixelIdxList{[stats.Extent] ==1})) = 0;
    %spine_th(vertcat(connComp.PixelIdxList{[bboxes_area] < (spine_sz(2)/10)^2})) = 0;

    % remove areas with too few pixels
    spine_th(vertcat(connComp.PixelIdxList{[stats.Area] < (spine_sz(2)/30)^2})) = 0;
    %spine_th(vertcat(connComp.PixelIdxList{[stats.Solidity] < .3})) = 0;

    % remove area which are not narrow (i.e. not the letter i), but at the same time have high
    % solidity
    spine_th(vertcat(connComp.PixelIdxList{[bboxes_aspect] > 0.5 & [bboxes_aspect] <1.7 & [stats.Solidity] > .9})) = 0;
   % se = strel('square',4);        
    %spine_th = imdilate(spine_th,se);
end
seg_spine = spine_th;
%seg_spine = bwmorph(spine_th,'spur');

% Eliminate regions that do not follow common text measurements
%spine_th(vertcat(connComp.PixelIdxList{[stats.BoundingBox] > .5})) = 0;
%spine_th(vertcat(connComp.PixelIdxList{[stats.Eccentricity] > .995})) = 0;
%spine_th(vertcat(connComp.PixelIdxList{[stats.Extent] < 0.2 | [stats.Extent] > 0.5})) = 0;

%spine_th(vertcat(connComp.PixelIdxList{[stats.Solidity] < .4})) = 0;

%subplot(1,spine_num,m,m), imshow(spinthmg);%

waitbar(1);
close(h);
end

