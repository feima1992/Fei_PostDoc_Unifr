%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mouse = 'b237[12456]'; % mouse selection
topFolder = 'WFW_B237X'; % folder in bigdata sever
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Param
objParamLimbMvt = Param_LimbMvt_CranialWin('folderName',topFolder);
% Wf tif files
objFileTableTifWf = FileTable_Tif_Wf('E:\Data\WFrecordings\',mouse);

% Bpod files
objFileTableBpodLimbMvt = FileTable_Bpod_LimbMvt('Z:\users\Fei\Bpod\',mouse);

% Align Wf tifs with Bpod
objActRawLimbMvt = Align_LimbMvt(objParamLimbMvt, objFileTableTifWf, objFileTableBpodLimbMvt);
objActRawLimbMvt.Align();
% Reg with Allen flat brain atlas
objActRawLimbMvt.Reg('cranialWindow');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reg from raw act
objFileTableActRaw = FileTableActRaw().Filter('mouse',mouse);
objFileTableActRaw.Reg('cranialWindow')

