classdef Rg < handle
    properties
        dataPath = Param().folderParent;
        resultPath = fullfile(Param().folderFigure, 'ReachingGrasping')
        objRegIMcorr;
        objRegIMcorrCopy;      
        actMapThre = 0.5;     
        figActMap;
        figActEdge;
    end
    methods
        %% Constructor
        function obj = Rg()
            
        end
        
        %% Export active map properties
        function obj = ExportActProps(obj, actMapThre)
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
            end
            
            fprintf('Exporting active map properties with threshold %.1f...\n', obj.actMapThre);
            
            % calculate active map properties
            obj.objRegIMcorrCopy = copy(obj.objRegIMcorr);
            obj.objRegIMcorrCopy.CalActMap(obj.actMapThre);
            obj.objRegIMcorrCopy.CalActProps();
            obj.objRegIMcorrCopy.CleanVar({'Edge','Component','Extrema','PixelIdxList','PixelList','PixelValues'});
            
        end
    end
end