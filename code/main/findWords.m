function [w_spine, word_stat] = findWords( seg_spine, merge )
h = waitbar(0,'Please wait...');
% calculate distance matrix between connected 
spine_th = seg_spine;

CCs = bwconncomp(spine_th);
%cc_stats = regionprops(CCs, 'Centroid', 'BoundingBox', 'PixelList', 'Image');
cc_centers = regionprops(CCs,'Centroid');                             % calculate centers 


cc_centers_mat = struct2cell(cc_centers);
cc_centers_mat = cc_centers_mat';
cc_centers_mat = cell2mat(cc_centers_mat);
cc_size = size(cc_centers_mat,1);
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

cc_poly_dist = temp;

% create path of nearest CCs
curr_cc = 1;
cc_path = zeros(1,cc_size);
i = 1;
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
    if dist_to_prev > dist_to_next*word_end_rat %|| (angle < 140 && angle > 40)
        if k-1>=word_start  % ignore empty words (happens only when the word was already found in the previos iteration)
            new_word = cc_path(word_start:k-1);
            word_start = k;
            words3 = [words3; {new_word}];  
            curr_center = cc_centers(curr_cc).Centroid;
            prev_center = cc_centers(prev_cc).Centroid;
            mx = (curr_center(1)+prev_center(1))/2;
            my = (curr_center(2)+prev_center(2))/2;
            %plot(mx,my,'.','MarkerSize', 10,'LineWidth',2,'Color','red');
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
        %plot(mx,my,'.','MarkerSize', 10,'LineWidth',2,'Color','red');
    end   
end
words3 = [words3; {cc_path(word_start:end)}]; %add the last word
word_stat = struct('word', words3, 'length', [], 'dist_arr', [], 'dist_mean', [], 'dist_std', [], 'ang_arr', [], 'ang_mean', []);

if merge == 0
    % assign different colors to different words and display the result
    words_label = labelmatrix(CCs);

    for k=1:size(words3,1)
        curr_word = words3{k};
        word_stat(k).word = words3{k};
        word_stat(k).length = numel(words3{k});
        for l=1:size(curr_word,2)
            curr_sym = curr_word(l);
            words_label(CCs.PixelIdxList{curr_sym})=k;
        end
    end

    w_spine = label2rgb(words_label,'hsv','k','shuffle');
end

if merge == 1
    % merge words
    % create words struct
    cc_dist = temp;
    centers = {cc_centers.Centroid}';
    cc_angles = cc_ang_mat(centers);

    for i=1:size(word_stat,1)
        word_stat(i) = getWordStats(word_stat(i).word, cc_dist, cc_angles);
    end

    words_merged = mergeWords(word_stat, cc_dist, cc_angles);

    % assign different colors to different words and display the result
    words = struct2cell(words_merged)';
    words = words(:,1);
    words_label = labelmatrix(CCs);
    for k=1:size(words,1)
        curr_word = words{k};
        for l=1:size(curr_word,2)
            curr_sym = curr_word(l);
            words_label(CCs.PixelIdxList{curr_sym})=k;
        end
    end
    w_spine = label2rgb(words_label,'hsv','k','shuffle');
    word_stat = words_merged;
end
close(h);
end

