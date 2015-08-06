
function [ ang_arr] = get_angle_arr(word, cc_ang)
% Returns an array specifying the angles between adjacent
% letters in a word

% init angle array
ang_arr = zeros(1,numel(word)-1);

%populate angle array
for k=1:numel(word)-1
    curr_char = word(k);
    next_char = word(k+1);
    ang_arr(k) = cc_ang(curr_char, next_char);
end
end
