function dist = word_dist(w1, w2, cc_dist)
%UNTITLED Find the distance between two "words"
%   Each word is given as an array of indexes of CCs
    dist_arr = [cc_dist(w1(1),w2(1)),...
        cc_dist(w1(1),w2(end)),...
        cc_dist(w1(end), w2(1)),...
        cc_dist(w1(end), w2(end))];
    dist = min(dist_arr);


end

