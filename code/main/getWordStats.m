function [ word_stat ] = getWordStats( word, cc_dist, cc_ang )
%Return a structure with word statistics (word length, mean distance, distance standard
%deviation, mean angle)
    curr_dist_arr = get_dist_arr(word, cc_dist);
    curr_ang_arr = get_angle_arr(word, cc_ang);
    word_stat.word = word;
    word_stat.length = numel(word);
    word_stat.dist_arr = curr_dist_arr;
    word_stat.dist_mean = mean(curr_dist_arr);
    word_stat.dist_std = std(curr_dist_arr);
    word_stat.ang_arr = curr_ang_arr;
    word_stat.ang_mean = mean(curr_ang_arr);
end

