clear

img = imread('image_file.jpg');
img = rgb2gray(img);
img = single(img);

[U,S,V] = svd(img);

for k = [5 30 200]
    
    for i = 1:k
        
        A(:,i) = U(:,i);
        C(i,i) = S(i,i);
        E(:,i) = V(:,i);
        
    end
    
D = A*C*E';

end

   
    