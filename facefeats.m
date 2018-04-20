%% Clear all video objects, variables, and background processes.
objects = imaqfind; %find video input objects in memory
delete(objects); %delete a video input object from memory
close all;
clear all;
clc;
%%
FaceFolder = [pwd '\Faces\'];
mkdir(pwd, 'Faces'); 
addpath(FaceFolder);
%%
Facetmp = [pwd '\Facetmp\'];
mkdir(pwd, 'Facetmp'); 
addpath(Facetmp);
%%
addpath(pwd, 'FaceLib');
FLibdir = dir(['FaceLib' '/*.jpg']);
FLibsize = size(FLibdir,1);
%% 

camera = 1;
camerainfo = imaqhwinfo('winvideo',camera);
reslist = camerainfo.SupportedFormats;
% User selects desired video capture resolutionpportedFormats
% usrvidres = input('Input the column number of the desired video resolution you would like to use.\n');
usrvidres = 7;
res = char(reslist(usrvidres));
vid = videoinput('winvideo',camera,res);
set(vid,'FramesPerTrigger',Inf,'ReturnedColorspace','rgb');
% vid.FrameGrabInterval = 3;
videoFrame = getsnapshot(vid);
frameSize = size(videoFrame);

faceDetector = vision.CascadeObjectDetector();  % Create the face detector object.

% Create the video player object.
videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]+30]);

start(vid);
framesATime = 50;
runLoop = true;
status = 1;
c = 0;

while runLoop
    for i=1:framesATime
		snip = getsnapshot(vid);  % Saves frame from video to be processed
		gsnip = rgb2gray(snip);
		bbox = faceDetector.step(gsnip);  % Collects coordinate data from the objectDetector surrounding the object in each frame 
        if isempty(bbox) ~= true
            for k=1:size(bbox,1)
                face = imcrop(snip,bbox(k,:));
                c = c + 1;
                tmpfaceFile = [Facetmp sprintf('face%d',c) '.jpg'];
                imwrite(face,tmpfaceFile);
                Ftmp = dir(['Facetmp' '/*.jpg']);
                for j=1:FLibsize
                    f1 = rgb2gray(imread(Ftmp(k).name));
                    f2 = rgb2gray(imread(FLibdir(j).name));

                    f1r = detectMSERFeatures(f1);
                    f2r = detectMSERFeatures(f2);

                    f1features = extractFeatures(f1,f1r);
                    f2features = extractFeatures(f2,f2r);

                    indexPairs = matchFeatures(f1features,f2features);
                    try
                        matchedPoints1 = vpts1(indexPairs(:,1));
                        matchedPoints2 = vpts2(indexPairs(:,2));

                        [F,inliersIndex,status] = estimateFundamentalMatrix(matchedPoints1,matchedPoints2);
                    catch
                    end
                    if status == 0
                        faceLabeled = insertObjectAnnotation(snip,'rectangle',bbox,'Bad Guy','Color','red');  % Creates the box frame around each detected object and labels the box
                    else
                        faceLabeled = insertObjectAnnotation(snip,'rectangle',bbox,'Face','Color','blue');  % Creates the box frame around each detected object and labels the box
                    end
                end
            end
        end
        % Display the annotated video frame using the video player object.
        step(videoPlayer, faceLabeled);
        % Check whether the video player window has been closed.
        runLoop = isOpen(videoPlayer);
        if i == framesATime
            i = 1;
        end
    end
end

%% Clean up.
stop(vid);
objects = imaqfind; %find video input objects in memory
delete(objects); %delete a video input object from memory
release(videoPlayer);
release(faceDetector);
clc
