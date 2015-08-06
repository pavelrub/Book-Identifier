function [ dist_arr ] = Get_dist_arr(word, dist_mat)
%Returns an array specifying the distances between adjacent 
% letters in the word. 

% init distance array
dist_arr = zeros(numel(word)-1);

% populate distance array
for k=1:numel(word)-1
    curr_char = word(k);
    next_char = word(k+1);
    dist_arr(k) = dist_mat(curr_char, next_char);
end


end

function [ ang_arr] = Get_angle_Arr(word, centroids)
% Returns an array specifying the angles between adjacent
% letters in a word

% init angle array
ang_arr = zeros(numel(word)-1);

%populate angle array
for k=1:numel(word)-1
    curr_word = word(k);
    next_word = word(k+1);
    curr_vec = centroids(curr_word) - centroids(next_word);
    ang_arr(k) = atan2(curr_vec(1), curr_vec(0));
end
end


