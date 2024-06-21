% modify the judp message sending from Bpod PC to match the message receiving in this script
% judp function is avaliable at [Stoolbotics/matlab/judp.m at master · Stonelinks/Stoolbotics · GitHub](https://github.com/Stonelinks/Stoolbotics/blob/master/matlab/judp.m)
mssg = judp('receive',21566,200,60000); % port 21566, timeout 200ms, 60s timeout
mouse = char(mssg(1:end-1)'); % convert to char
trial = double(mssg(end)); % convert to double
fprintf('Recording %s trial %s\n', mouse, num2str(trial+1)); 
WF = WFacq();WF.Initialize(mouse, trial+1, 1);WF.Start(); % start acquisition with the next trial