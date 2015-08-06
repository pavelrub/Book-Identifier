function [ ang_mat ] = word_ang_mat( words_cell_arr, cc_dist, cc_angles)
%Returns a matrix specifying the angle between every pair of words
ang_mat = zeros(numel(words_cell_arr));
for k=1:numel(words_cell_arr)-1
    for l=k+1:numel(words_cell_arr)
        curr_word1 = words_cell_arr{k};
        curr_word2 = words_cell_arr{l};
        ang_mat(k,l) = word_angle(curr_word1, curr_word2, cc_dist, cc_angles);
    end
end

ang_mat = ang_mat + ang_mat';    %set second half of matrix
ang_mat(logical(eye(size(ang_mat))))=NaN;     % set diagonal to NaN

end

