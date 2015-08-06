function dist = box_dist_along_line(p1, box1, p2, box2)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%create matrix of box1 and box2 segments
x1 = box1(1);
y1 = box1(2);
x2 = x1 + box1(3);
y2 = y1 + box1(4);
box1_mat(1,:) = [x1 y1 x2 y1];
box1_mat(2,:) = [x2 y1 x2 y2];
box1_mat(3,:) = [x2 y2 x1 y2];
box1_mat(4,:) = [x1 y2 x1 y1];

x1 = box2(1);
y1 = box2(2);
x2 = x1 + box2(3);
y2 = y1 + box2(4);
box2_mat(1,:) = [x1 y1 x2 y1];
box2_mat(2,:) = [x2 y1 x2 y2];
box2_mat(3,:) = [x2 y2 x1 y2];
box2_mat(4,:) = [x1 y2 x1 y1];
segments = vertcat(box1_mat, box2_mat);
line = [p1,p2];

intersect = lineSegmentIntersect(line,segments);
cols = find([intersect.intAdjacencyMatrix]);
if length(cols)==2
    i1 = [intersect.intMatrixX(1,cols(1)),intersect.intMatrixY(1,cols(1))];
    i2 = [intersect.intMatrixX(1,cols(2)),intersect.intMatrixY(1,cols(2))];

    

    dist = sqrt((i1(1)-i2(1))^2+(i1(2)-i2(2))^2);        
else
    %plot(p1,p2,'LineWidth',2,'Color','yellow');
    %plot(i1(1),i1(2),'x','LineWidth',2,'Color','yellow');
    %plot(i2(1),i2(2),'x','LineWidth',2,'Color','yellow');
    dist= 0;%sqrt((p1(1)-p2(1))^2+(p1(2)-p2(2))^2);
    %plot(p1,p2,'LineWidth',2,'Color','yellow');

end

 %dist = sqrt((p1(1)-p2(1))^2+(p1(2)-p2(2))^2);
end

