function [ dist_mat ] = word_dist_mat( words_cell_arr, cc_dist )
%Returns a matrix specifying the distances between each pair of words

dist_mat = zeros(numel(words_cell_arr));
for k=1:numel(words_cell_arr)
    for l=k+1:numel(words_cell_arr)
        curr_word1 = words_cell_arr{k};
        curr_word2 = words_cell_arr{l};
        dist_mat(k,l) = word_dist(curr_word1, curr_word2, cc_dist);
    end
end

dist_mat = dist_mat + dist_mat';    %set second half of matrix
dist_mat(logical(eye(size(dist_mat))))=NaN;     % set diagonal to NaN
end

