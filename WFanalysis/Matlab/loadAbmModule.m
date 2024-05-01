function [abmModuleMap, abmModuleLabel] = loadAbmModule

    % load the ABM template image
    abmTemplate = imread(Param().path.abmTemplate);

    % get outline of cortex modules from the ABM template image
    moduleOutline = double(bwskel(abmTemplate == 0));

    % label the modules in the ABM template image
    abmModuleMap = bwlabel(~moduleOutline, 4);

    % load name of the ABM template modules
    abmModuleLabel = readGoogleSheet('1kVuDSObVCEI02XG_x6lCCY1mDkVIL1ZuYyk42iSWnGQ');
    abmModuleLabel = convertvars(abmModuleLabel,'id',@(X)cellstr(string(X)));
    abmModuleLabel.id = cellfun(@(X,Y)[X,Y],abmModuleLabel.id,abmModuleLabel.iDs,'UniformOutput',false);
    abmModuleLabel.label = cellfun(@(X, Y) [X, '(', Y, ')'], abmModuleLabel.hemisphere, abmModuleLabel.moduleNameAbb, 'UniformOutput', false);
    abmModuleLabel = cleanVar(abmModuleLabel, {'id','label','hemisphere','moduleNameAbb'}, 'keep');

end
