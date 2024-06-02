objFileTableBpod = FileTable_Bpod_LimbMvt('Z:\users\Fei\Bpod\Bpod Local\Data','s237');
objFileTableWfTif = FileTable_Tif_Wf_SingleCell('E:\Data\WFrecordings\','s237');
objParam = Param_LimbMvt_CranialWin_SingleCell();
objFileTableBpodWf = AlignLimbMvtSingleCell(objParam, objFileTableWfTif, objFileTableBpod);