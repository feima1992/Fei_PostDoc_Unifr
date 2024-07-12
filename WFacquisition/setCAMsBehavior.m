devices = imaqhwinfo('gentl'); % Get the information of the connected cameras
devicesName = {devices.DeviceInfo.DeviceName}; % Get the name of the connected cameras
devicesID = [devices.DeviceInfo.DeviceID]; % Get the ID of the connected cameras
camIDsBehav = devicesID(~ismember(devicesName,'daA1280-54um (23579649)')); % Get the ID of the behavior cameras (cameras other than the widefield trigger camera)
% Lock the cameras by previewing
for i = 1:length(camIDsBehav) % Loop through the behavior cameras
    vid = videoinput('gentl', camIDsBehav(i), 'Mono8'); % Create the video object
    src = getselectedsource(vid); % Get the source object
    vid.FramesPerTrigger = 1; % Set the number of frames per trigger
end