% function to load tiff files and convert to mp4 video

filePath1 = "Z:\users\Fei\Pub\Stability of cortical proprioceptive representation\Reaching grasping\CAM1_r1224_230223_001.tif";
filePath2 = "Z:\users\Fei\Pub\Stability of cortical proprioceptive representation\Reaching grasping\CAM2_r1224_230223_001.tif";

% load tiff files
info1 = imfinfo(filePath1);
info2 = imfinfo(filePath2);
num_images = min(length(info1), length(info2));

% create video object
outputVideo = VideoWriter('Z:\users\Fei\Pub\Stability of cortical proprioceptive representation\Reaching grasping\output.avi', 'Motion JPEG AVI');
outputVideo.FrameRate = 10;
open(outputVideo);

% load images frame 150-200 concatenate horizontally
for i = 140:200
    if i < 166
        add_text = 'Start';
    elseif i < 173
        add_text = 'Reach';
    elseif i < 175
        add_text = 'Grasp';
    elseif i < 190
        add_text = 'Retract';
    else
        add_text = 'Drink';
    end

    time_text = sprintf('Time: %.2fs', (i-140)/30);

    img1 = imread(filePath1, i);
    % add 'CAM1' to top left corner
    img1 = insertText(img1, [10 10], 'CAM1', 'FontSize', 18, 'BoxColor', 'black', 'BoxOpacity', 0.4, 'TextColor', 'white');
    % add add_text
    img1 = insertText(img1, [10 40], time_text, 'FontSize', 18, 'BoxColor', 'black', 'BoxOpacity', 0.4, 'TextColor', 'white');
    % add add_text
    img1 = insertText(img1, [10 70], add_text, 'FontSize', 18, 'BoxColor', 'black', 'BoxOpacity', 0.4, 'TextColor', 'white');

    img2 = imread(filePath2, i);
    % add 'CAM2' to top left corner
    img2 = insertText(img2, [10 10], 'CAM2', 'FontSize', 18, 'BoxColor', 'black', 'BoxOpacity', 0.4, 'TextColor', 'white');
    % add add_text
    img2 = insertText(img2, [10 40], time_text, 'FontSize', 18, 'BoxColor', 'black', 'BoxOpacity', 0.4, 'TextColor', 'white');
    % add add_text
    img2 = insertText(img2, [10 70], add_text, 'FontSize', 18, 'BoxColor', 'black', 'BoxOpacity', 0.4, 'TextColor', 'white');

    img = [img1, img2];
    writeVideo(outputVideo, img);
end

close(outputVideo);