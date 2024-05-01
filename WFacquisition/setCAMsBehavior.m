devices = imaqhwinfo('gentl');
devicesName = {devices.DeviceInfo.DeviceName};
devicesID = [devices.DeviceInfo.DeviceID];
camIDsBehav = devicesID(~ismember(devicesName,'daA1280-54um (23579649)'));
% Lock the cameras by previewing
for i = 1:length(camIDsBehav)
    vid = videoinput('gentl', camIDsBehav(i), 'Mono8');
    src = getselectedsource(vid);
    vid.FramesPerTrigger = 1;
end