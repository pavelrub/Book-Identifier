function [ang_mat] = cc_ang_mat(cc_centers)
%Returns a matrix of angles between each two CCs
ang_mat = zeros(size(cc_centers,1));
for k=1:size(cc_centers,1)-1;
    for l=k+1:size(cc_centers,1)
        vec = cc_centers{l} - cc_centers{k};
        angle = abs(atan2(vec(2), vec(1))*180/pi);
        if angle > 90
            angle = 180 - angle;
        end
        ang_mat(k,l) = angle;
    end
end

ang_mat = ang_mat + ang_mat';    %set second half of matrix
ang_mat(logical(eye(size(ang_mat))))=NaN;     % set diagonal to NaN
    

end

