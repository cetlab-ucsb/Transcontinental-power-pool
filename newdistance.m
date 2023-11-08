function D2 = newdistance(XI,XJ)  
 [m,~] = size(XJ);
 pstar = repmat(XI,[m,1]);
 dist1 =distance(pstar,XJ);
 D2 =deg2km(dist1); 
end