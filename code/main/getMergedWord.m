function [ merged ] = getMergedWord(w1,w2,cc_dist)
%merges w1 and w2 and returns the resulting word
    dist_arr = [cc_dist(w1(1),w2(1)),...
        cc_dist(w1(1),w2(end)),...
        cc_dist(w1(end), w2(1)),...
        cc_dist(w1(end), w2(end))];
    index = find(dist_arr==min(dist_arr(:)),1);
    
    if index == 1 
        merged = horzcat(fliplr(w1),w2);
    end
    if index == 2
        merged = horzcat(w2,w1);
    end
    if index == 3
       merged = horzcat(w1,w2);
    end
    if index == 4
       merged = horzcat(w1, fliplr(w2));
    end 


end

