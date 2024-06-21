%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mouse = 'b237[12456]'; % mouse selection
topFolder = 'WFW_V237X'; % folder in bigdata sever
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Param
objParamLimbMvt = Param_LimbMvt_CranialWin('folderName',topFolder);
% Wf tif files
objFileTableTifWf = FileTable_Tif_Wf('D:\Data\WFrecordings\',mouse);

% Bpod files
objFileTableBpodLimbMvt = FileTable_Bpod_LimbMvt('Z:\users\Fei\Bpod\',mouse);

% Align Wf tifs with Bpod
objActRawLimbMvt = Align_LimbMvt(objParamLimbMvt, objFileTableTifWf, objFileTableBpodLimbMvt);
% Reg with Allen flat brain atlas
objActRawLimbMvt.Reg('cranialWindowVesselPattern');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reg from raw act LimbMvt
objFileTableActRaw = FileTable_Act_Raw().Filter('mouse',@(X)contains(X,'m237')).Remove('mouse','m2371');
objFileTableActRaw.Reg('cranialWindowVesselPattern')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reg from raw act Limbvib
objFileTableActRaw = FileTable_Act_Raw().Filter('mouse',@(X)contains(X,'b237')).Remove('mouse','b2371');
objFileTableActRaw.Reg('cranialWindowVesselPattern')

