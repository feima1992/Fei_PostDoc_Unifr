devices = imaqhwinfo('gentl'); % Get the information of the available devices
devicesName = {devices.DeviceInfo.DeviceName}; % Get the name of the devices
devicesID = [devices.DeviceInfo.DeviceID]; % Get the ID of the devices
camIDwfTrigger = devicesID(ismember(devicesName,'daA1280-54um (23579649)')); % Get the ID of the trigger camera
vid = videoinput('gentl', camIDwfTrigger, 'Mono8'); % Create the video object
src = getselectedsource(vid); % Get the source object
vid.FramesPerTrigger = 1; % Set the number of frames per trigger