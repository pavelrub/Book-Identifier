function [ word_stat, cc_dist, cc_ang ] = mergeWords( word_stat, cc_dist, cc_ang )
%UNTITLED Get a table of word stats and return a new table of words
%after mergins all possible words
    words_mat = struct2cell(word_stat)';
    words_cell_arr = words_mat(:,1);
    w_dist_mat = word_dist_mat(words_cell_arr, cc_dist);
    w_ang_mat = word_ang_mat(words_cell_arr, cc_dist, cc_ang);
    for k=1:size(word_stat,1)-1
        for l=k+1:size(word_stat,1)
            if checkMerge(k,l,word_stat, w_dist_mat, w_ang_mat)==1
                w1 = word_stat(k).word;
                w2 = word_stat(l).word;
                w_new = getMergedWord(w1,w2,cc_dist);
                w_new_stat = getWordStats(w_new, cc_dist, cc_ang);
                word_stat(k) = w_new_stat;
                word_stat(l) = [];
                [word_stat, cc_dist, cc_ang] = mergeWords(word_stat, cc_dist, cc_ang);
                return;
            end           
        end
    end
end

