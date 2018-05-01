%% Clear all video objects, variables, and background processes.
close all;
clear all;
clc;

%% Delete video objects
objects = imaqfind; %find video input objects in memory
delete(objects); %delete a video input object from memory

%% Open Webcam
webcamlist
camera = input('Select camera column number.\n');
% camera=1;

%% Selecting Capture Resolution
% Displays a list of the supported camera capture resolutions
camerainfo = imaqhwinfo('winvideo',camera);
reslist = camerainfo.SupportedFormats

% User selects desired video capture resolution
usrvidres = input('Input the column number of the desired video resolution you would like to use.\n');
% usrvidres = 8;
res = char(reslist(usrvidres));

%% Setting camera capture settings
% Creating the video capture object using the user's selected camera and
% resolution that will be used.
vid = videoinput('winvideo',camera,res);

%% Setting how often a video frame is taken
% Sets the amount of frames that can be collected whenever the camera is triggered. Here it is set to infinity.
...Sets the returned frame images back as an RGB object.
set(vid,'FramesPerTrigger',Inf,'ReturnedColorspace','rgb');
% Sets how often a frame is grabbed from the video capture. Here it is set to capture every 8 frames.
vid.FrameGrabInterval=10;

%% Name of object
objName = input('Name of the object to be detected: ','s');

%% Creating the folders where the captured positive and negative images will be saved.

% Set target path for the folder to save the negative images
negFolder = [pwd '\Negative Images\']; 
objFol = [pwd '\' objName '\'];
% Creates the folders where the positive and negative instances will be saved.
mkdir(pwd, objName); 
mkdir(pwd, 'Negative Images'); 
% Adds the new folders' path to the MATLAB program. This allows access the folders where their contents can be used by the program.
addpath(objFol);
addpath(negFolder);

%% Taking positive instances from video
framesToSave = input('Input how many pictures of the object you would like to capture: ');
input('Press Enter to begin positive image aquisition.\n');  

% Starts the video capture object (the selected camera)
start(vid);

% Creates the figure window where the video will show. This figure window has been renamed as 'Captureing Positive Images Now'
...and the 'Figure 1:' text has been removed from the title.
posCapture=figure('Name','Capturing Positive Images Now','NumberTitle','off');

% Select the amount pictures (frames) that will be saved from the live video. These particular pictures will be saved
...into the 'Positive Images' folder where the ROI will be manually selected from each image. 
% framesToSave = 15;

% This while loop will run the video until it has reached the amount of 'framesToSave'
while(vid.FramesAcquired<=framesToSave)    
    hold on
    
    for i=1:framesToSave

        pospic=getsnapshot(vid);        
        posImageFileName = [objFol sprintf('posimg%d',i) '.jpg'];
        imwrite(pospic, posImageFileName);
        
        imshow(pospic);
    
    end
    
    hold off

end

% Stop video object to reduce lag
stop(vid);
close(posCapture);

%% Labeling the objects (selecting the ROIs from the positive instances
% We need to go through the images we just saved and label the object.
   
% Loading the MATLAB Image Labeler application.  
... Select positive ROIs from each captured image and export the positive ROIs as a table named "posdata"
trainingImageLabeler;
msgbox('Create a label. Select and label the object in each picture. EXPORT the labels to the WORKSPACE as a TABLE and name it "posdata".');  

%% Capture negative images from video (images that do not contain the object to be detected)
framestoSave = input('Negative images are images that do not contain the object that is to be detected.\nInput the number of negative images to take: ');

% Creating figure window and setting its name 
negcapture=figure('Name','Capturing Negative Images Now','NumberTitle','off');

% Restarting the video object to preparing it for recording
start(vid);

% Select the number of frames you would like to save as negative instances.
% framesToSave = 200;

% Runs the video and captures the desired number of negative images.
...Saves the negative images to the folder that was created earlier.
while(vid.FramesAcquired<=framesToSave)
    
    hold on
    
	% for loop to process each frame that is captured
    for i=1:framesToSave
		% Captures frame from video to be used
        negpic=getsnapshot(vid);        
	    % Prepares the name of the captured frame as 'negimg(1, 2, 3, and so on).jpg' which will be saved to the 'Negative Images' folder
        negImageFileName = [negFolder sprintf('negimg%d',i) '.jpg'];
		% Saves the captured frame using the created 'negImageFileName' information
        imwrite(negpic, negImageFileName);
        % Shows the frame that was captured and saved
        imshow(negpic);
    
    end
    
    hold off

end

% Stops the video object.
stop(vid);
% Closes the negcapture object to reduce ram used.
close(negcapture);

%% Loading the Classifier Training data
% Next we train a classifier using trainCascadeObjectDetector.

% Load the bounding box data (if it's not already in the workspace)...
...The 'posdata' file created earlier from exporting the positive ROIs
...The 'posdata' struct has the location of the positive image locations.

% Loading the object ROI data set 
% posdata = load('posdata.mat');  <<< UNCOMMENT IF IMAGE LABELS WERE EXPORTED TO FILE.

%% Training the 'trainCascadeObjectDetector'.

% trainCascadeObjectDetector('Name of the file you would like to save the training as *.xml',

...,the positive instances ROI file,

...,the image folder [path] saved previously containing the negative instances,

...'FalseAlarmRate', 0.2,  <---Note: Lower values for FalseAlarmRate increase complexity
...of each stage. Increased complexity can achieve fewer false detections but can
...result in longer training and detection times. Higher values for FalseAlarmRate
...can require a greater number of cascade stages to achieve reasonable
...detection accuracy, 
...'NumCascadeStages', 5); The number of stages the object detector will go through.
trainCascadeObjectDetector('ObjectDetector.xml',posdata,negFolder)

%% Testing the classifier on live video

% Reseting the number of frames 
vid.FrameGrabInterval=3;

% Create figure window for the live feed detection
liveFeedDetection = figure('Name','Live Feed Detection','NumberTitle','off');

% Load the newly-trained detector
objectDetector = vision.CascadeObjectDetector('ObjectDetector.xml');

% Start video object in the figure window
start(vid);

% Choose the duration of the live feed in frames captured 
% framesToView = 500;

% While loop that will process each frame from the live video feed.
...This loop will detect the object in each frame, framing and labeling the object.
while True
	hold on
	% Begin video processing
	for i=1:framesToView
		% Saves frame from video to be processed
		snip = getsnapshot(vid);
		% Collects coordinate data from the objectDetector surrounding the object in each frame
		bbox = objectDetector.step(snip);
		% Creates the box frame around each detected object and labels the box
		objLabeled = insertObjectAnnotation(snip,'rectangle',bbox,objName,'Color','blue');
		% Displays the frame that was processed
		imshow(objLabeled);
	end
	hold off
end

stop(vid);

%% Clear all variables and video object data once finished
flushdata(vid);
clear all
clc