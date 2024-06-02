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
% Reg from raw act
objFileTableActRaw = FileTable_Act_Raw().Filter('mouse',{'m2376'});
objFileTableActRaw.Reg('cranialWindowVesselPattern')