function [ dist_arr ] = get_dist_arr(word, dist_mat)
%Returns an array specifying the distances between adjacent 
% letters in the word. 

% init distance array
dist_arr = zeros(1,numel(word)-1);

% populate distance array
for k=1:numel(word)-1
    curr_char = word(k);
    next_char = word(k+1);
    dist_arr(k) = dist_mat(curr_char, next_char);
end


end


