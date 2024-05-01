devices = imaqhwinfo('gentl');
devicesName = {devices.DeviceInfo.DeviceName};
devicesID = [devices.DeviceInfo.DeviceID];
camIDwfTrigger = devicesID(ismember(devicesName,'daA1280-54um (23579649)'));
vid = videoinput('gentl', camIDwfTrigger, 'Mono8');
src = getselectedsource(vid);
vid.FramesPerTrigger = 1;