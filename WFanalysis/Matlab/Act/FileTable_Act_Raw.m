classdef FileTable_Act_Raw < FileTable_Act

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Act_Raw(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Act(varargin{:});
            % Filter rows to only include raw data
            obj.Filter('actType', 'Raw');
        end

        %% Function register with alle brain atlas
        function obj = Reg(obj, windowType)
            % validate input
            if nargin < 2
                windowType = 'clearSkull';
            end

            % construct path to corresponding output REG files
            funcRegActName = @(x) strrep(strrep(x, 'ACT', 'REG'), 'Raw', 'Reg');
            obj.fileTable.pathReg = cellfun(funcRegActName, obj.fileTable.path, 'UniformOutput', false);
            obj.fileTable.pathRegExist = cellfun(@(x) isfile(x), obj.fileTable.pathReg);
            % construct path to corresponding refrerence images
            funcRefActName = @(x) fullfile(Param().dir.refImage, strrep(x, 'ACT.mat', 'REF.tif'));
            obj.fileTable.pathRef = cellfun(funcRefActName, obj.fileTable.namefull, 'UniformOutput', false);
            % filter out files that already have a REG file
            obj.fileTable = obj.fileTable(~obj.fileTable.pathRegExist, :);

            % for each file in filesActPath register coordinates with allen atlas
            screenSize = get(0, 'Screensize');
            guiPosition = [screenSize(1) + 100, screenSize(2) + 100, screenSize(3) - 200, screenSize(4) - 200];

            for i = 1:height(obj.fileTable)

                close all
                fprintf('  Registration for \n    %s\n', obj.fileTable.path{i})

                switch windowType
                    case 'clearSkull'
                        objReg = regActRawClearSkull(obj.fileTable.pathRef{i}, strrep(obj.fileTable.path{i}, '.mat', '.tif'), Param());
                    case 'cranialWindow'
                        objReg = regActRawCranialWindow(obj.fileTable.pathRef{i}, strrep(obj.fileTable.path{i}, '.mat', '.tif'), Param());
                end

                set(findobj('Name', 'WF registration'), 'Position', guiPosition);
                waitfor(objReg, 'objButtonRegFlag', 1);
                pause(10)
            end

        end

        %% Create movie
        function obj = ActVideo(obj)

                options.frameRate  = 5;

            % create movie for each file in fileTable
            for i = 1:height(obj.fileTable)

                try
                    movieFile = strrep(obj.fileTable.path{i}, '.mat', '_movie.avi');
                    % skip if movie already exists
                    if isfile(movieFile)
                        fprintf('  Movie already exists for %d/%d: %s\n', i, height(obj.fileTable), movieFile);
                        continue
                    end

                    % load file
                    load(obj.fileTable.path{i}, 'IMcorr', 't');
                    % show movie
                    figure('Name', obj.fileTable.namefull{i}, 'NumberTitle', 'off', 'Position', [100, 100, 1000, 1000], 'Color', 'w');
                    % create movie avi file
                    objVideo = VideoWriter(movieFile, 'Uncompressed AVI'); %#ok<TNMLP>
                    objVideo.FrameRate = options.frameRate;
                    open(objVideo);
                    fprintf('  Creating movie for %d/%d: %s\n', i, height(obj.fileTable), movieFile);

                    for j = 1:size(IMcorr, 3)
                        % plot frame
                        imshow(im2uint8(rescale(IMcorr(:, :, j))));
                        % add time stamp
                        text(10, 15, sprintf('t = %.2f s', t(j)), 'Color', 'w', 'FontSize', 20, 'FontWeight', 'bold');
                        % get frame
                        frameData = getframe(gca);
                        % write frame to video
                        writeVideo(objVideo, frameData);
                        % pause to show frame
                        pause(1 / options.frameRate);
                    end

                    % close figure and video
                    close(gcf);
                    close(objVideo);
                catch
                    close(gcf);
                    fprintf('  Error creating movie for %d/%d: %s\n', i, height(obj.fileTable), movieFile);
                end

            end

        end

    end

end
