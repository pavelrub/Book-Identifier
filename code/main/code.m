close all

spines_image = [];

% Load and display bookshelf image
books_color = imread('3.jpg','jpg'); 
figure, imshow(books_color), title('Original shelf image');  

% Convert to grayscale and equalize histogram to improve contrast
books_gray = rgb2gray(books_color); 
books_gray = adapthisteq(books_gray);
figure, imshow(books_gray), title('Grayscale shelf image');

% Find and display edges using Canny 
books_edges = edge(books_gray, 'Canny');
figure, imshow(books_edges), title('Shelf image edges');


% Find and display vertical lines with Hough transform
[H,theta,rho] =  hough(books_edges,'RhoResolution',1,'Theta',-20:0.2:20); %angle is limited to detect only vertical images
NHoodSize = [51 51]; %TODO Change this to something that makes actual sense, like a certain number of degrees and distance
P = houghpeaks(H,50,'threshold',ceil(0.5*max(H(:))),'NHoodSize', NHoodSize);
spine_lines = houghlines(books_gray,theta,rho,P,'FillGap',size(books_gray,2)/40,'MinLength',size(books_gray,1)/1.5); 
drawHoughLines(books_gray,spine_lines);

% Find and display horizontal lines
[H,theta,rho] =  hough(books_edges,'RhoResolution',1,'Theta',-90:0.2:-87);
NHoodSize = [51 13];
P = houghpeaks(H,1,'threshold',ceil(0.5*max(H(:))),'NHoodSize', NHoodSize);
lines2 = houghlines(books_gray,theta,rho,P);
drawHoughLines(books_gray,lines2);

% Calculate and display gradient
[Gx, Gy] = imgradientxy(books_gray);
[Gmag, Gdir] = imgradient(books_gray);
figure; imshowpair(Gy, Gx, 'montage'); axis off;

% Sort vertical lines by horizontal location
spine_lines_arr = ({spine_lines.point1});
spine_lines_arr = [spine_lines_arr{:}];
spine_lines_arr = spine_lines_arr(1:2:end);
[tmp, ind]=sort(spine_lines_arr);
spine_lines = spine_lines(ind);

% Extract spines
sz = size(books_gray);
start_line = [1,sz(1);1,1]; % left spine border
spines = {};
for k = 1:length(spine_lines)
    end_line = [spine_lines(k).point1;spine_lines(k).point2]; %right spine border
    strip_coords = [start_line; end_line]; %spine corners coordinates
    
    %create a mask around the spine
    mask = roipoly(books_gray, strip_coords(:,1), strip_coords(:,2)); 
    mask_three_chan = repmat(mask,[1,1,3]);
    
    % define bounding box
    x1 = min(strip_coords(:,1));
    y1 = min(strip_coords(:,2));
    x2 = max(strip_coords(:,1));
    y2 = max(strip_coords(:,2));
    bounding_box = [x1,y1,x2-x1,y2-y1];
    
    % crop the spine and warp it to fit the bounding box
    spine_img = imcrop(books_color.*uint8(mask_three_chan), bounding_box); % crop
    fixedPoints = [1 y2; 1 y1; x2-x1 y1; x2-x1 y2];
    movingPoints = [strip_coords(:,1) - min(strip_coords(:,1)),strip_coords(:,2)];
    tform = fitgeotrans(movingPoints,fixedPoints,'affine');
    R=imref2d(size(spine_img));
    spine_img = imwarp(spine_img,tform,'OutputView',R); % warp
    
    % cut small strips from the sides (the usually don't belng to the book
    % itself)
    spine_size = size(spine_img);
    crop_margin_w = spine_size(2)/15;
    spine_img = imcrop(spine_img, [crop_margin_w, 1, spine_size(2)-2*crop_margin_w, spine_size(1)]);
    
    % append to an array of spines
    spines = [spines, {spine_img}];
    subplot(1,length(spine_lines),k), imshow(spine_img);
    % move the left border to next book
    start_line = flipud(end_line);
end


tightfig;
%% Text segmentation
spine_num = size(spines,2);
fig_windows = figure;
fig_compare = figure;
%for m=1:spine_num;    
    % load and display the spine
    spine = spines{8};
    %spine = imresize(spine,3);
    %spine = imsharpen(spine,'Radius',2,'Amount',3);
    str = sprintf('spine number %d', 5);
    figure, imshow(spine), title(str);
    
    % convert spine to grayscale and equalize histogram
    spine_sz = size(spine);
    %spine_hsv=rgb2hsv(spine);
    spine_gray = rgb2gray(spine);
    %spine_gray=imadjust(spine_gray);
    spine_gray = adapthisteq(spine_gray);
    spine_gray_sz = size(spine_gray);
    figure, imshow(spine_gray);
    
    % initialize binary spine image with zeros
    spine_th = false(spine_gray_sz);
    
    % set window size for thresholding along the spine
    window_incr = 80;
    window_h = spine_sz(1)/window_incr;
    window_w = spine_sz(2);
    
    % crap that doesn't work
%     [x, y] = size(spine_gray);
%     binImg = adaptivethreshold(spine_gray, round(0.01 * x * y), graythresh(spine_gray) / 1.75);
%     figure, imshow(binImg);
    
    % move window along the spine and threhold each window
    ind = 0; %this is for displaying some figures in the loop
    for k=1:window_incr
        % crop current window, sharpen and conver to grayscale
        cut_from_r = window_h*(k-1)+1;
        cut_to_r = window_h*k+1;
        window_img = imcrop(spine, [1, cut_from_r, window_w, cut_to_r-cut_from_r ]);
        
        window_img_g = rgb2gray(window_img);
        window_img_g = imsharpen(window_img_g);
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
        window_img_th2 = seg_window == 1; %this is just because I want to display it in a figure later on
       
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
            avg_lett = sum(col1)/size(col1,1);
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
    
    %show spine before further filtering
    figure, h=imshow(spine_th);
    
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


    figure, h=imshow(spine_th); hold on
    set(h,'Clipping','off');
    
    % some possible printing for debugging
    for k = 1:length(stats)
        aspect_ratio = stats(k).BoundingBox(3)/stats(k).BoundingBox(4);
        %rectangle('Position',stats(k).BoundingBox,'EdgeColor','g');
        %text(stats(k).BoundingBox(1), stats(k).BoundingBox(2), num2str(stats(k).Area), 'Color', 'g');
    end
    
    
    % Eliminate regions that do not follow common text measurements
    %spine_th(vertcat(connComp.PixelIdxList{[stats.BoundingBox] > .5})) = 0;
    %spine_th(vertcat(connComp.PixelIdxList{[stats.Eccentricity] > .995})) = 0;
    %spine_th(vertcat(connComp.PixelIdxList{[stats.Extent] < 0.2 | [stats.Extent] > 0.5})) = 0;
    
    %spine_th(vertcat(connComp.PixelIdxList{[stats.Solidity] < .4})) = 0;
    
    %subplot(1,spine_num,m,m), imshow(spinthmg);%

%end

% calculate distance matrix between connected components

spine_th = imrotate(spine_th,90);
%%figure, imshow(spine_th);
figure, imshow(spine_th), hold on;

% spine_th=im2uint8(spine_th);
% ocrResults   = ocr(spine_th)
% recognizedText = ocrResults.Text;
% text(1,1, recognizedText, 'BackgroundColor', [1 1 1]);


%figure, imshow(bwperim(spine_th));
CCs = bwconncomp(spine_th)
cc_stats = regionprops(CCs, 'Centroid', 'BoundingBox', 'PixelList', 'Image');
cc_centers = regionprops(CCs,'Centroid');                             % calculate centers 

 
cc_centers_mat = struct2cell(cc_centers);
cc_centers_mat = cc_centers_mat';
cc_centers_mat = cell2mat(cc_centers_mat);
centers_dist = pdist2(cc_centers_mat,cc_centers_mat);
centers_dist(logical(eye(size(centers_dist))))=NaN;                          % set diagonal to NaN
cc_size = size(cc_centers_mat,1);
cc_status = zeros(cc_size,3);

cc_bboxes = regionprops(CCs,'BoundingBox');
cc_bboxes_mat = struct2cell(cc_bboxes);
cc_bboxes_mat = cc_bboxes_mat';
cc_bboxes_mat = cell2mat(cc_bboxes_mat);
test = box_dist_along_line(cc_centers_mat(1,:),cc_bboxes_mat(1,:),cc_centers_mat(2,:),cc_bboxes_mat(2,:));
%cc_poly = zeros(size(cc_size));
for k=1:cc_size
    %P = struct('X', [1,2],'Y', [3,4]);
    x1 = cc_bboxes_mat(k,1);
    x2 = x1 + cc_bboxes_mat(k,3);
    y1 = cc_bboxes_mat(k,2);
    y2 = y1 + cc_bboxes_mat(k,4);
    cc_poly(k).x = [x1,x2];
    cc_poly(k).y = [y1,y2];
end

% Create a matrix of CC distances based on distance between boxes along
% the line connecting the centroids
cc_poly_dist = zeros(cc_size,cc_size);
for k=1:cc_size-1
    for l=k+1:cc_size
        cc_poly_dist(k,l) = box_dist_along_line(cc_centers_mat(k,:),cc_bboxes_mat(k,:),...
            cc_centers_mat(l,:),cc_bboxes_mat(l,:));
    end
end

cc_poly_dist_temp = cc_poly_dist;

% Create a matix of CC distances based on pixel distances
%spine_perim = bwperim(spine_th);
cc_pixels = regionprops(CCs,'PixelList');

cc_px_dist = zeros(cc_size, cc_size);
for k=1:cc_size-1
    for l=k+1:cc_size
        px_l = cell2mat(struct2cell(cc_pixels(l)));
        px_k = cell2mat(struct2cell(cc_pixels(k)));
        cc_px_dist(k,l) = min_px_dist(px_k,px_l);
    end
end

cc_poly_dist = cc_px_dist;




cc_poly_dist = cc_poly_dist + cc_poly_dist';
cc_poly_dist(logical(eye(size(cc_poly_dist))))=NaN;                          % set diagonal to NaN
temp = cc_poly_dist;
%cc_poly_dist2 = cc_poly_dist;



for k=1:cc_size
    col1 = find(cc_poly_dist(k,:) == min(cc_poly_dist(k,:)), 1);
    cc_top2(k,1) = cc_poly_dist(k,col1);
    cc_poly_dist(k,col1)= NaN;
    col2 = find(cc_poly_dist(k,:) == min(cc_poly_dist(k,:)), 1);
    cc_top2(k,2) = cc_poly_dist(k,col2);
    cc_poly_dist(k,col2)= NaN;
    if cc_top2(k,2)>1.5*cc_top2(k,1) || cc_top2(k,1)>1.5*cc_top2(k,2)
        rectangle('Position',cc_bboxes(k).BoundingBox,'EdgeColor','g');
        
    end
    text(cc_centers(k).Centroid(1), cc_centers(k).Centroid(2), num2str(k), 'Color', 'r');
    
    
end
word_set = [];


cc_poly_dist = temp;
    
i = 1;
k = 1;
col = 0;


% create path of nearest CCs
curr_cc = 1;
cc_path = zeros(1,cc_size);
while i < cc_size
    next_cc = find(cc_poly_dist(curr_cc,:) == min(cc_poly_dist(curr_cc,:)),1);
    cc_poly_dist(curr_cc,:) = NaN;
    cc_poly_dist(:,curr_cc) = NaN;
    p1 = cc_centers_mat(curr_cc,:);
    p2 = cc_centers_mat(next_cc,:);
    plot([p1(1),p2(1)],[p1(2),p2(2)],'Color' , 'g', 'LineWidth',2); %plot line
    cc_path(i) = curr_cc;
    curr_cc = next_cc;
    i = i+1;
end
cc_path(i) = curr_cc;
cc_poly_dist = temp;


% split into words
word_end_rat = 1.6; % distance ratio for word edges between previous and next letters
words3 = {};
word_start = 1;
for k=2:cc_size-1
    curr_cc = cc_path(k);
    prev_cc = cc_path(k-1); % TODO: deal with k=0
    next_cc = cc_path(k+1); % TODO: deal with k = end
    dist_to_prev = cc_poly_dist(curr_cc, prev_cc);
    dist_to_next = cc_poly_dist(curr_cc, next_cc);
    vec_from_prev = cc_centers(curr_cc).Centroid-cc_centers(prev_cc).Centroid;
    x1 = vec_from_prev(1);
    y1 = vec_from_prev(2);
    vec_from_next = cc_centers(next_cc).Centroid-cc_centers(prev_cc).Centroid;
    x2 = vec_from_next(1);
    y2 = vec_from_next(2);
    angle = atan2(abs(x1*y2-y1*x2),x1*x2+y1*y2)*(180/pi);
    if dist_to_prev > dist_to_next*word_end_rat %|| (angle < 140 && angle > 40)
        if k-1>=word_start  % ignore empty words (happens only when the word was already found in the previos iteration)
            new_word = cc_path(word_start:k-1);
            word_start = k;
            words3 = [words3; {new_word}];  
            curr_center = cc_centers(curr_cc).Centroid;
            prev_center = cc_centers(prev_cc).Centroid;
            mx = (curr_center(1)+prev_center(1))/2;
            my = (curr_center(2)+prev_center(2))/2;
            plot(mx,my,'+','LineWidth',2,'Color','yellow');
        end
    end
    if dist_to_next > dist_to_prev*word_end_rat% || (angle < 140 && angle > 40)
        new_word = cc_path(word_start:k);
        word_start = k+1;
        words3 = [words3; {new_word}];  
        curr_center = cc_centers(curr_cc).Centroid;
        next_center = cc_centers(next_cc).Centroid;
        mx = (curr_center(1)+next_center(1))/2;
        my = (curr_center(2)+next_center(2))/2;
        plot(mx,my,'x','LineWidth',2,'Color','red');
    end   
end
words3 = [words3; {cc_path(word_start:end)}]; %add the last word

% assign different colors to different words and display the result
words_label = labelmatrix(CCs);

for k=1:size(words3,1)
    curr_word = words3{k};
    for l=1:size(curr_word,2)
        curr_sym = curr_word(l);
        words_label(CCs.PixelIdxList{curr_sym})=k;
    end
end

words_rgb = label2rgb(words_label,'hsv','k','shuffle');
figure, imshow(words_rgb);

%%

% merge words
% create words struct
word_stat = struct('word', words3, 'length', [], 'dist_arr', [], 'dist_mean', [], 'dist_std', [], 'ang_arr', [], 'ang_mean', []);
cc_dist = temp;
centers = {cc_centers.Centroid}';
cc_angles = cc_ang_mat(centers);

for i=1:size(word_stat,1)
    word_stat(i) = getWordStats(word_stat(i).word, cc_dist, cc_angles);
%     curr_dist_arr = get_dist_arr(word_stat(i).word, cc_dist);
%     curr_ang_arr = get_angle_arr(word_stat(i).word, cc_angles);
%     word_stat(i).index = i;
%     word_stat(i).dist_arr = curr_dist_arr;
%     word_stat(i).dist_mean = mean(curr_dist_arr);
%     word_stat(i).dist_std = std(curr_dist_arr);
%     word_stat(i).ang_arr = curr_ang_arr;
%     word_stat(i).ang_mean = mean(curr_ang_arr);
%     word_stat(i).length = size(word_stat(i).word,2);
end

words_merged = mergeWords(word_stat, cc_dist, cc_angles);

% assign different colors to different words and display the result
words = struct2cell(words_merged)';
words = words(:,1);
w_dist_mat = word_dist_mat(words, cc_dist);
w_ang_mat = word_ang_mat(words, cc_dist, cc_angles);
words_label = labelmatrix(CCs);
for k=1:size(words,1)
    curr_word = words{k};
    for l=1:size(curr_word,2)
        curr_sym = curr_word(l);
        words_label(CCs.PixelIdxList{curr_sym})=k;
    end
end

words_rgb = label2rgb(words_label,'prism','k','shuffle');
figure, imshow(words_rgb);
hold on;
%%
% Remove single-character words
words = words_merged;
words2 = words;
words2(:) = [];
i = 1;
for k=1:size(words,1)
    if words(k).length > 1
        words2(i) = words(k);
        i = i+1;
    end
end

%% Specify words orientation (hor/ver), and flip words if needed
for k=1:size(words2,1)
    curr_word = words2(k).word
    first_char = curr_word(1);
    last_char = curr_word(end);
    p1 = cc_centers(first_char).Centroid
    p2 = cc_centers(last_char).Centroid
    xdiff = abs(p1(1)-p2(1));
    ydiff = abs(p1(2)-p2(2));
    if xdiff>ydiff
        words2(k).orientation = 1;
        if p1(1) > p2(1)
            words2(k).word = fliplr(words2(k).word);
        end
    else 
        words2(k).orientation = 0;
        if p1(2) > p2(2)
            words2(k).word = fliplr(words2(k).word);
        end
    end
end

% assign different colors to different words and display the result
words_label = labelmatrix(CCs);
pad_size = 30;
words_rgb = padarray(words_rgb, [30 30], 'both');
figure, imshow(words_rgb);
for k=1:numel(words2)
    curr_word = words2(k).word;
    words_label(:) = 0;
    for l=1:numel(curr_word);
        curr_sym = curr_word(l);
        char_im = padarray(cc_stats(curr_sym).Image, [30 30], 'both');
        %figure, imshow(char_im);
        %ocrResults = ocr(char_im)
        words_label(CCs.PixelIdxList{curr_sym})=1;
    end
    st = regionprops( uint8(words_label), 'BoundingBox'); %// cast to uint8
    rect = st.BoundingBox; %// the bounding box of all white pixels
    words_rgb = label2rgb(words_label,'hsv','k','shuffle');
    figure;
    imshow( words_rgb, 'border', 'tight' ); 
    %hold on;
    roi = rect + [pad_size - 2, pad_size - 2, 4,4];
    %rectangle('Position', rect, 'EdgeColor', 'r', 'LineWidth', 1.5 );
    %roi = [rect(2) rect(1) rect(2)+rect(3) rect(1)+rect(4)]
    %size(words_rgb)
     %roi = round(getPosition(imrect))
   
    
    ocrResults = ocr(words_rgb, roi);
    %if ocrResults.WordConfidences > 0.7
        %ocrResults.Text
    %end
end

% display word in seperate figures (just for testing)
% word = words2(3).word;
% img_cell=cell(1,numel(word));
% for k=1:numel(word);
%     curr_char = word(k);
%     word_image = cc_stats(curr_char).Image;
%     img_cell{k} = word_image;
%     %txt = ocr(word_image)
%     %figure, imshow(word_image);
% end
% word_image = cell2mat(img_cell);
% figure, imshow(word_image);





% w_dist_mat = word_dist_mat(words3, cc_dist);
% w_ang_mat = word_ang_mat(words3,cc_dist, cc_angles);


% sort by size
% word_stat = nestedSortStruct(word_stat, 'length');
% longest = size(word_stat,1);
% mergeStatus = 0;
% for k=1:size(word_stat,1)-1
%     curr = k;
%     mergeStatus = checkMerge(word_stat(longest), word_stat(curr), word_dist);
%     if mergeStatus == 1
%         word_stat(longest).word = merge_words(word_stat(longest).word, word_stat(curr).word);
%         word_stat(k) = []; %delete the word we just merged with the longest word
%         word_stat = update_stats(word_stat); %update word stats
%         mergeStatus = 0;
%     end
% end

% create mergers table
% i=1;    % merge table index
% for k=1:size(word_stat,1)-1
%     for l=k+1:size(word_stat,1)
%        w1 = word_stat(k); % first word
%        w2 = word_stat(l); % second word
%        if (w2.length == 1 && w1.length == 1)
%            continue;
%        end
%        mergeStatus = checkMerge(w1, w2, w_dist_mat, w_ang_mat);
%        if mergeStatus == 1
%            mergeTable(i,1) = k;
%            mergeTable(i,2) = l;
%            i=i+1;
%            mergeStatus = 0;
%        end
%     end
% end

% perform actual merges according to merge table






    

% while i <= cc_size
%    while col == 0 
%         col = find(cc_poly_dist(k,:) == min(cc_poly_dist(k,:)));  %find the index of the nearest component
%         if cc_status(col,3) == 1
%             cc_poly_dist(k, col) = NaN;
%             col = 0;
%         end
%    end
%    if isempty(col)
%       break;
%    end
%    word_set(1,end+1) = k;
%    cc_status(k,3) = 1;
%    cc_status(k,2) = col;
%    cc_status(col,1) = k;
%    p1 = cc_centers_mat(k,:);
%    p2 = cc_centers_mat(col,:);
%    cc_poly_dist(col, k) = NaN;
%    %figure, imshow(spine_th), hold on
%   
%    plot([p1(1),p2(1)],[p1(2),p2(2)],'Color' , 'g', 'LineWidth',2); %plot line
%    k = col;
%    i = i+1; 
%    col = 0;
% end 

i = 0;
words = [];
centers_dist = pdist2(cc_centers_mat,cc_centers_mat);
curr_word = 1;
curr_letter = 2;

for k=2:cc_size-1
    curr_cc = word_set(curr_word,curr_letter);
    conn_to = cc_status(curr_cc,2);
    conn_from =  cc_status(curr_cc,1);
    if conn_from ~= 0 && conn_to ~= 0
        dist1 = cc_poly_dist2(curr_cc,conn_to);
        dist2 = cc_poly_dist2(curr_cc,conn_from);
        
        
        p1 = cc_centers_mat(curr_cc,:);
        if dist1 > dist2*1.7 && dist2 ~= 0
            
           
            p2 = cc_centers_mat(conn_to,:);
            mx = (p1(1)+p2(1))/2;
            my = (p1(2)+p2(2))/2;
            plot(mx,my,'x','LineWidth',2,'Color','red');
            %plot([p1(1),p2(1)],[p1(2),p2(2)],'Color' , 'red', 'LineWidth',2); %plot line
            new_word = word_set(curr_word,1:curr_letter);
            remaining_word = word_set(curr_word,curr_letter+1:end);
            %new_word
            word_set = remaining_word;
            words = [words, {new_word}];
            curr_letter = 0;
%             cut_line = [word_set(curr_word,1:curr_letter),word_set(curr_word,curr_letter+1:end)-word_set(curr_word,curr_letter+1:end)];
%             new_line = [word_set(curr_word,curr_letter+1:end),word_set(curr_word,1:curr_letter)-word_set(curr_word,1:curr_letter)];
%             word_set = [word_set(1:curr_word-1,:);...
%                  cut_line;new_line;...
%                  word_set(curr_word+1:end,:)];
%             curr_word = curr_word + 1;
         
            
        else
            if dist2 > dist1*1.7 && dist1 ~= 0 && curr_letter~=1
                
                
                p2 = cc_centers_mat(conn_from,:);
                mx = (p1(1)+p2(1))/2;
                my = (p1(2)+p2(2))/2;
                plot(mx,my,'x','LineWidth',2,'Color','red');
               % plot([p1(1),p2(1)],[p1(2),p2(2)],'Color' , 'red', 'LineWidth',2); %plot line
                new_word = word_set(curr_word,1:curr_letter-1);
                curr_word;
                curr_letter;
                new_word;
                words = [words, {new_word}];
                remaining_word =word_set(curr_word,curr_letter:end);
                word_set = remaining_word;
                curr_letter = 1;
%                 cut_line = [word_set(curr_word,1:curr_letter-1),word_set(curr_word,curr_letter:end)-word_set(curr_word,curr_letter:end)];
%                 new_line = [word_set(curr_word,curr_letter:end),word_set(curr_word,1:curr_letter-1)-word_set(curr_word,1:curr_letter-1)];
%                 word_set = [word_set(1:curr_word-1,:);...
%                             cut_line;new_line;...
%                             word_set(curr_word+1:end,:)];

%                 word_set = [word_set(1:word-1,:);...
%                 word_set(word,1:letter-1);word_set(word,letter:length(word_set(word,:)));...
%                 word_set(word+1:size(word_set,1))]
                
                
            end          
        end  
    end
     curr_letter = curr_letter + 1;
     if k==cc_size-1
         words = [words,{word_set}];
     end
end
words = words.';


for k=1:size(words,1)
    curr_word = words{k,1};
    % calculate average inner-distance
    dist_arr = [];
    for l=2:length(curr_word)
        cc_1 = curr_word(l-1);
        cc_2 = curr_word(l);
        dist_arr(end+1) = cc_poly_dist2(cc_1,cc_2);
    end
    words{k,2} = mean(dist_arr);
    words{k,3} = std(dist_arr); 
end
for k=1:size(words,1)
    curr_word = words{k,1};
    curr_mean = words{k,2};
    curr_std = words{k,3};
    a1 = curr_word(1);
    a2 = curr_word(end);
    word_dist = zeros(2);
    for l=k:size(words,1)
        % compare distances between l's and k's edge letters
        comp_word = words {l,1};
        curr_mean = words{l,2};
        curr_std = words{l,3};
        b1 = comp_word(1);
        b2 = comp_word(end);
        
        word_dist(1,1) = cc_poly_dist2(a1, b1);
        word_dist(1,2) = cc_poly_dist2(a1, b2);
        word_dist(2,1) = cc_poly_dist2(a2, b1);
        word_dist(2,2) = cc_poly_dist2(a2, b2);
        
        word_dist(isnan(word_dist))=9999;
        [min_dist, ind] = min(word_dist(:));
        [row,col] = ind2sub(size(word_dist),ind);
        if length(curr_word) > length(comp_word) ...
                && min_dist < curr_mean + 2*curr_std
            new_word = join_words(curr_word, comp_word, row, col);
            
            
        end
    end
end
se = strel('square',12);
%spine_dilated = imdilate(spine_th,se);
%figure; imshow(spine_dilated), hold on;
    
    
           
    
   

