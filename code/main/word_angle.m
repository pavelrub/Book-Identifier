function angle = word_angle(w1, w2, cc_dist, cc_angles)
%UNTITLED Find the angle between two "words"
%   Each word is given as an array of indexes of CCs
    dist_arr = [cc_dist(w1(1),w2(1)),...
        cc_dist(w1(1),w2(end)),...
        cc_dist(w1(end), w2(1)),...
        cc_dist(w1(end), w2(end))];
    index = find(dist_arr==min(dist_arr(:)),1);
    
    if index == 1 
        angle = cc_angles(w1(1), w2(1));
    end
    if index == 2
        angle = cc_angles(w1(1), w2(end));
    end
    if index == 3
        angle = cc_angles(w1(end), w2(1));
    end
    if index == 4
        angle = cc_angles(w1(end), w2(end));
    end

end

