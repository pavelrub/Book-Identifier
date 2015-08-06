function dist = min_px_dist(pxls1, pxls2)
%Calculate the minimum eucledian distance between two sets of pixels
    min = 9999;
    for k=1:size(pxls1,1)
        for l=1:size(pxls2,1)
            curr_dist = sqrt((pxls1(k,1)-pxls2(l,1))^2+(pxls1(k,2)-pxls2(l,2))^2);
            if curr_dist < min
                min = curr_dist;
            end
        end
    end
    dist = min;
end

