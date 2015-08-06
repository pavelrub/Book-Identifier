function [ res ] = checkMerge(w1, w2, word_stat, dist_mat, ang_mat)
%Checks if two words can be merges. Return 1 if yes, 0 otherwise.
    
    dist = dist_mat(w1, w2);
    ang = ang_mat(w1, w2);
    w1_md = word_stat(w1).dist_mean;
    w2_md = word_stat(w2).dist_mean;
    w1_stdd = word_stat(w1).dist_std;
    w2_stdd = word_stat(w2).dist_std;
    w1_ma = word_stat(w1).ang_mean;
    w2_ma = word_stat(w2).ang_mean;
    ang_diff = 13;
    std_fact = 1.6;
    if w1_stdd == 0
        d1_fact = 0.6;
    else 
        d1_fact = 0;
    end
    if w2_stdd == 0
        d2_fact = 0.6;
    else 
        d2_fact = 0;
    end
    
    res = 0;
    if (word_stat(w1).length == 1)
        if  ang <= w2_ma + ang_diff && ang >= w2_ma - ang_diff...
               && dist <= w2_md + d2_fact*w2_md + std_fact*w2_stdd && dist >= w2_md -d2_fact*w2_md - std_fact*w2_stdd
           res = 1;
           return;
        end    
    end
    
    if (word_stat(w2).length == 1)
         if  ang <= w1_ma + ang_diff && ang >= w1_ma - ang_diff...
               && dist <= w1_md + d1_fact*w1_md + std_fact*w1_stdd && dist >= w1_md - d1_fact*w1_md - std_fact*w1_stdd
           res = 1;
           return;
        end  
    end
    
    if ((ang <= w1_ma + ang_diff && ang >= w1_ma - ang_diff) ...
            || (ang <= w2_ma + ang_diff && ang >= w2_ma - ang_diff)) ...
            && ...
            ((dist <= w1_md + d1_fact*w1_md + std_fact*w1_stdd &&...
            dist >= w1_md - d1_fact*w1_md - std_fact*w1_stdd) || ...
             (dist <= w2_md +d2_fact*w2_md+ std_fact*w2_stdd &&...
             dist >= w2_md -d2_fact*w2_md- std_fact*w2_stdd))
         res = 1;
         return;
    end
        
    

end

