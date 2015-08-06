function [ spines_image, spines_struct ] = separateSpines( books_color )
h = waitbar(0,'Please wait...');

% Convert to grayscale and equalize histogram to improve contrast
books_gray = rgb2gray(books_color); 
books_gray = adapthisteq(books_gray);
%figure, imshow(books_gray), title('Grayscale shelf image');

% Find and display edges using Canny 
books_edges = edge(books_gray, 'Canny');
%figure, imshow(books_edges), title('Shelf image edges');


% Find and display vertical lines with Hough transform
[H,theta,rho] =  hough(books_edges,'RhoResolution',1,'Theta',-20:0.2:20); %angle is limited to detect only vertical images
NHoodSize = [51 51]; %TODO Change this to something that makes actual sense, like a certain number of degrees and distance
P = houghpeaks(H,50,'threshold',ceil(0.5*max(H(:))),'NHoodSize', NHoodSize);
spine_lines = houghlines(books_gray,theta,rho,P,'FillGap',size(books_gray,2)/40,'MinLength',size(books_gray,1)/1.5); 
%drawHoughLines(books_gray,spine_lines);

% Find and display horizontal lines
[H,theta,rho] =  hough(books_edges,'RhoResolution',1,'Theta',-90:0.2:-87);
NHoodSize = [51 13];
P = houghpeaks(H,1,'threshold',ceil(0.5*max(H(:))),'NHoodSize', NHoodSize);
lines2 = houghlines(books_gray,theta,rho,P);
%drawHoughLines(books_gray,lines2);

% Calculate and display gradient
[Gx, Gy] = imgradientxy(books_gray);
[Gmag, Gdir] = imgradient(books_gray);
%figure; imshowpair(Gy, Gx, 'montage'); axis off;

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
steps = length(spine_lines)+1;
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
    crop_margin_w = spine_size(2)/10;
    spine_img = imcrop(spine_img, [crop_margin_w, 1, spine_size(2)-2*crop_margin_w, spine_size(1)]);
    
    % append to an array of spines
    spines = [spines, {spine_img}];
    %subplot(1,length(spine_lines),k), imshow(spine_img);
    % move the left border to next book
    start_line = flipud(end_line);
    waitbar(k / steps)
end

spine_img = spines{1};
position = [size(spine_img,2)/2, 1];
spine_img = insertText(spine_img,position,num2str(1),'AnchorPoint', 'CenterTop', 'FontSize', 30);
spines_image = padarray(spine_img, [0 5], 255, 'both');
for k=2:numel(spines)
    % place a number on each spine image
    spine_img = spines{k};
    position = [size(spine_img,2)/2, 1];
    spine_img = insertText(spine_img,position,num2str(k),'AnchorPoint', 'CenterTop', 'FontSize', 30);
    spines_image = horzcat(spines_image, padarray(spine_img, [0 5], 255, 'both')); 
end
spines_struct = spines;
waitbar(1);
close(h)
end

