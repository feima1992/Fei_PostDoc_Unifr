mssg = judp('receive',21566,200,60000);
mouse = char(mssg(1:end-1)');
trial = double(mssg(end));
fprintf('Recording %s trial %s\n', mouse, num2str(trial+1));
WF = WFacq();WF.Initialize(mouse, trial+1, 1);WF.Start();