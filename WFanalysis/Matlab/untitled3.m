for k = 1:size(trigData.sigCells,1)
    plotDirTune(trigData, trigData.sigCells(k)) 
    i = num2str(trigData.sigCells(k));
    path='D:\Data\SingleCellData\New folder'; %Out folder
    saveas(figure(1),fullfile(path,[ num2str(i) 'Out' '.jpeg'])); %save Out figures
    close all
end