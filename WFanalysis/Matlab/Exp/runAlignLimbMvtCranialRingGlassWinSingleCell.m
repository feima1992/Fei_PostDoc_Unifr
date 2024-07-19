%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mouse = 'v237[12456]'; % mouse selection
topFolder = 'WFW_V237X'; % folder in bigdata sever
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Param
objParamLimbMvt = Param_LimbMvt_CranialWin_SingleCell();

% Wf tif files
objFileTableTifWf = FileTable_Tif_Wf_SingleCell('E:\Data\WFrecordings\',mouse);

% Bpod files
objFileTableBpodLimbMvt = FileTable_Bpod_LimbMvt('Z:\users\Fei\Bpod\',mouse);

% Align Wf tifs with Bpod
objActRawLimbMvt = AlignLimbMvtSingleCell(objParamLimbMvt, objFileTableTifWf, objFileTableBpodLimbMvt);

