%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mouse = 'm237[12456]'; % mouse selection
wfDataDrive = 'D'; % hard drive storing widefied imaging tiffs
topFolder = 'WFW_M237X'; % folder in bigdata sever
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Param
objParamLimbMvt = Param_LimbMvt_CranialWin('folderName',topFolder);
% Wf tif files
objFileTableTifWf = FileTable_Tif_Wf('D:\Data\WFrecordings\',mouse);

% Bpod files
objFileTableBpodLimbMvt = FileTableBpodLimbMvt('Z:\users\Fei\Bpod\',mouse);

% Align Wf tifs with Bpod
objActRawLimbMvt = ActRawLimbMvt(objParamLimbMvt, objFileTableTifWf, objFileTableBpodLimbMvt);
objActRawLimbMvt.Align();
% Reg with Allen flat brain atlas
objActRawLimbMvt.Reg('cranialWindow');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reg from raw act
objFileTableActRaw = FileTableActRaw().Filter('mouse',mouse);
objFileTableActRaw.Reg('cranialWindow')

