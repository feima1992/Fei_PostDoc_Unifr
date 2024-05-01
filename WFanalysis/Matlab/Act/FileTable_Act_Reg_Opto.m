classdef FileTable_Act_Reg_Opto < FileTable_Act_Reg
    %% Properties
    properties
        pairedFileTable
    end

    %% Methods
    methods
        %% Construcctor
        function obj = FileTable_Act_Reg_Opto(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Act_Reg(varargin{:});
        end

        %% Function load IMcorr
        function obj = LoadIMcorr(obj)
            % Notify the user that files are being loaded
            fprintf('   Loading IMcorr from %d files\n', height(obj.fileTable))
            tic;
            % Load LoadIMcorr
            obj.fileTable = loadIMcorr(obj.fileTable, 'loadIMcorrType', 'IMcorrREG', 'drawMask', true);
            % Notify the user that loading is done and how long it took
            fprintf('   Loading IMcorr from %d files took %.2f seconds\n', height(obj.fileTable), toc)
        end

        %% Plot activation map for each mouse and session (NormIMcorr)
        function obj = PlotMap(obj, varargin)

            p = inputParser;
            addRequired(p, 'obj', @(x)isa(x, 'FileTable_Act_Reg_Opto'));
            addParameter(p, 'plotLevel', 'session', @(x)ismember(x, {'all', 'mouse', 'session'}));
            addParameter(p, 'plotFrame', 28:28, @(x)isnumeric(x));
            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            plotLevel = p.Results.plotLevel;
            plotFrame = p.Results.plotFrame;

            % If the IMcorr is not loaded, load it
            if ~ismember('IMcorr', obj.fileTable.Properties.VariableNames)
                obj.LoadIMcorr();
            end

            % Plot IMcorr
            switch plotLevel
                case 'session'
                    % Plot each session
                    G = findgroups(obj.pairedFileTable(:, {'mouse', 'session'}));

                    for i = 1:length(unique(G))
                        thisSessionTable = obj.pairedFileTable(G == i, :);
                        % Plot each frame of the NormIMcorr
                        for j = plotFrame
                            % Create frameData to be plotted and frameTime
                            frameDataLazerOff = thisSessionTable.IMcorr_lazerOff{1}(:, :, j);
                            frameDataLazerOn = thisSessionTable.IMcorr_lazerOn{1}(:, :, j);
                            frameTime = sprintf('%.2f', Param().wfAlign.frameTime(j));
                            % Create a figure
                            figure('Position', [100, 100, 1000, 1000], 'Color', 'w');
                            t = tiledlayout(1, 2);
                            % Create titleStr and sgtitleStr
                            sgtitleStr = [thisSessionTable.mouse{1}, '( ', thisSessionTable.session{1}, ' )', ' @ ', frameTime, 's'];
                            titleStr = {'LazerOff', 'LazerOn', 'LazerOn - LazerOff'};
                            % Plot the figure
                            nexttile(1)
                            imshowFrameOpto(frameDataLazerOff)
                            title(titleStr{1})
                            nexttile(2)
                            imshowFrameOpto(frameDataLazerOn)
                            title(titleStr{2})
                            % Add public title
                            title(t, sgtitleStr)
                            % Add public xlabel
                            xlabel(t, 'ML(mm)')
                            % Add public ylabel
                            ylabel(t, 'AP(mm)')
                            % save the figure
                            figName = [thisSessionTable.mouse{1}, '_', thisSessionTable.session{1}, '_Opto_frame', num2str(j), '.png'];
                            figPath = fullfile(Param().folderFigure, thisSessionTable.mouse{1}, figName);
                            % create folder if not exist
                            if ~isfolder(fileparts(figPath))
                                mkdir(fileparts(figPath));
                            end

                            % save the figure
                            exportgraphics(gcf, figPath, 'Resolution', 300);

                            % close the figure
                            close gcf;
                        end

                    end

                case 'mouse'
                    % Plot each mouse
                    G = findgroups(obj.pairedFileTable(:, {'mouse'}));

                    for i = 1:length(unique(G))
                        thisMouseTable = obj.pairedFileTable(G == i, :);
                        % Plot each frame of the NormIMcorr
                        for j = plotFrame
                            % Create frameData to be plotted and frameTime
                            frameDataLazerOff = cellfun(@(x) x(:, :, j), thisMouseTable.IMcorr_lazerOff, 'UniformOutput', false);
                            frameDataLazerOn = cellfun(@(x) x(:, :, j), thisMouseTable.IMcorr_lazerOn, 'UniformOutput', false);
                            frameDataLazerOff = cat(3, frameDataLazerOff{:});
                            frameDataLazerOn = cat(3, frameDataLazerOn{:});
                            frameDataLazerOffAvg = mean(frameDataLazerOff, 3);
                            frameDataLazerOnAvg = mean(frameDataLazerOn, 3);
                            frameTime = sprintf('%.2f', Param().wfAlign.frameTime(j));
                            % Create a figure
                            figure('Position', [100, 100, 1000, 1000], 'Color', 'w');
                            t = tiledlayout(1, 2);
                            % Create titleStr and sgtitleStr
                            sgtitleStr = [thisMouseTable.mouse{1}, ' @ ', frameTime, 's'];
                            titleStr = {'LazerOff', 'LazerOn'};
                            % Plot the figure
                            nexttile(1)
                            imshowFrameOpto(frameDataLazerOffAvg)
                            title(titleStr{1})
                            nexttile(2)
                            imshowFrameOpto(frameDataLazerOnAvg)
                            title(titleStr{2})
                            % Add public title
                            title(t, sgtitleStr)
                            % Add public xlabel
                            xlabel(t, 'ML(mm)')
                            % Add public ylabel
                            ylabel(t, 'AP(mm)')
                            % save the figure
                            figName = [thisMouseTable.mouse{1}, '_Opto_frame', num2str(j), '.png'];
                            figPath = fullfile(Param().folderFigure, thisMouseTable.mouse{1}, figName);
                            % create folder if not exist
                            if ~isfolder(fileparts(figPath))
                                mkdir(fileparts(figPath));
                            end

                            % save the figure
                            exportgraphics(gcf, figPath, 'Resolution', 300);

                            % close the figure
                            close gcf;
                        end

                    end
                case 'all'
            end

        end

        %% Plot IMcorr properties
        function obj = CalActProps(obj)

            if ~ismember('IMcorr', obj.fileTable.Properties.VariableNames)
                obj.LoadIMcorr();
            end

            for i = 1:height(obj.fileTable)
                obj.fileTable.IMcorr{i} = FramesIMcorr(obj.fileTable.IMcorr{i}, Param().wfAlign.frameTime).CalRegionProps().frameProps;
            end

            obj.fileTable = expendColumn(obj.fileTable, 'IMcorr');
        end

        %% getter
        % getters
        function pairedFileTable = get.pairedFileTable(obj)
            pairedFileTable = obj.PairLazerOnOff().pairedFileTable;
        end

        % function to pair lazerOn and lazerOff sessions
        function obj = PairLazerOnOff(obj)
            lazerOn = obj.fileTable(ismember(obj.fileTable.trialType, 'LazerOn'), :);
            lazerOff = obj.fileTable(ismember(obj.fileTable.trialType, 'LazerOff'), :);

            if height(lazerOn) ~= height(lazerOff)
                warning('lazerOn and lazerOff trials are not equal')
            end

            obj.pairedFileTable = innerjoin(lazerOn, lazerOff, 'Keys', {'namefull', 'mouse', 'session', 'actType', 'mvtDir'});
        end
        
        % function to export filetable
        function obj = ExportCsv(obj)
        
        % Load file if not already done
        if ~isfield(obj.fileTable, 'ComponentId')
            obj.CalActProps();
        end
        % Get current date as postfix
        datePostfix = datestr(now,'yyyymmdd');
        fileName = ['ActRegionProps_LimbMvtOpto_' datePostfix '.csv'];
        filePath = fullfile(Param().folderFigure, fileName);
        % Save to csv by calling superclass method
        ExportCsv@FileTable(obj, filePath);
        % Display message
        disp(['File saved as ' filePath]);
        end

    end

end
