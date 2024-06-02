classdef Enrich_LimbVib < Enrich
    
    properties
        dataFilter = {'WFW_V', 'TrialAll'};
        expInfo = 'WF-CranialWindowVib'; 
    end
    
    methods
        %% Constructor
        function obj = Enrich_LimbVib()
            obj = obj@Enrich();
            obj.LoadIMcorr();
        end
        %% Load IMcorr data
        function obj = LoadIMcorr(obj)
            
            if exist(fullfile(obj.resultPath, 'Enrich_LimbVib_ActIMcorr.mat'), "file")
                fprintf('Loading IMcorr data from existing file...\n');
                load(fullfile(obj.resultPath, 'Enrich_LimbVib_ActIMcorr.mat'), 'objFileTableActReg');
                obj.objRegIMcorr = objFileTableActReg;
                fprintf('IMcorr data loaded.\n');
            else
                fprintf('Loading IMcorr data from raw file...\n');
                obj.objRegIMcorr = FileTable_Act_Reg_IMcorr(obj.dataPath, obj.dataFilter).AddGroupInfo(obj.expInfo).LoadIMcorr();
                objFileTableActReg = obj.objRegIMcorr;
                save(fullfile(obj.resultPath, 'Enrich_LimbVib_ActIMcorr.mat'), 'objFileTableActReg', '-v7.3');
                fprintf('IMcorr data loaded.\n');
            end
            
        end
        
        %% PlotActMap
        function obj = PlotActMap(obj, actMapThre)
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
                
            end
            
            PlotActMap@Enrich(obj);
            saveas(obj.figActMap, fullfile(obj.resultPath, ['Enrich_LimbVib_ActMap_', num2str(obj.actMapThre), '.svg']));
            
        end

        %% PlotActEdge
        function obj = PlotActEdge(obj, actMapThre)
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
                
            end
            
            PlotActEdge@Enrich(obj);
            saveas(obj.figActEdge, fullfile(obj.resultPath, ['Enrich_LimbVib_ActEdge_', num2str(obj.actMapThre), '.svg']));
            
        end
        
        function obj = ExportActProps(obj, actMapThre)
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
            end
                        
            % calculate active map properties
            ExportActProps@Enrich(obj);
            writetable(obj.objRegIMcorrCopy.fileTable, fullfile(obj.resultPath, ['Enrich_LimbVib_ActProps_', num2str(obj.actMapThre), '.csv']));
        end
    end
    
end
