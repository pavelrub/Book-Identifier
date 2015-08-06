function [ text ] = recognizeText(seg_spine, words_struct)
text = '';
CCs = bwconncomp(seg_spine);
cc_centers = regionprops(CCs,'Centroid');    
% Remove single-character words
words = words_struct;
words_f = words;
words_f(:) = [];
i = 1;
for k=1:size(words,1)
    if words(k).length > 1
        words_f(i) = words(k);
        i = i+1;
    end
end

% Specify words orientation (hor/ver), and flip words if needed
for k=1:numel(words_f)
    curr_word = words_f(k).word;
    first_char = curr_word(1);
    last_char = curr_word(end);
    p1 = cc_centers(first_char).Centroid;
    p2 = cc_centers(last_char).Centroid;
    xdiff = abs(p1(1)-p2(1));
    ydiff = abs(p1(2)-p2(2));
    if xdiff>ydiff
        words_f(k).orientation = 1;
        if p1(1) > p2(1)
            words_f(k).word = fliplr(words_f(k).word);
        end
    else 
        words_f(k).orientation = 0;
        if p1(2) > p2(2)
            words_f(k).word = fliplr(words_f(k).word);
        end
    end
end

% assign different colors to different words and display the result
words_label = labelmatrix(CCs);
pad_size = 30;
words_pad = padarray(seg_spine, [30 30], 'both');
for k=1:numel(words_f)
    curr_word = words_f(k).word;
    words_label(:) = 0;
    for l=1:numel(curr_word);
        curr_char = curr_word(l);
        %char_im = padarray(cc_stats(curr_sym).Image, [30 30], 'both');
        %figure, imshow(char_im);
        %ocrResults = ocr(char_im)
        words_label(CCs.PixelIdxList{curr_char})=1;
    end
    st = regionprops( uint8(words_label), 'BoundingBox'); %// cast to uint8
    rect = st.BoundingBox; %// the bounding box of all white pixels
    words_img = label2rgb(words_label,'hsv','k','shuffle');
        
    word_img = imcrop(words_img, rect);
    word_img = padarray(word_img, [5 5], 'both');
    if words_f(k).orientation == 0
        word_img = imrotate(word_img, 90);
    end
    ocrResults = ocr(word_img, 'TextLayout', 'Word');

    if ~isempty(ocrResults.WordConfidences) & ocrResults.WordConfidences > 0.2
         text = strcat(text, {' '}, ocrResults.Text);
    end
end


end

