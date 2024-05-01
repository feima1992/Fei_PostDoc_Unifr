classdef FileTable_Act_Reg < FileTable_Act
    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Act_Reg(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Act(varargin{:});
            % Filter rows to only include raw data
            obj.Filter('actType', 'Reg');
        end

        %% Create movie
        function ActUnProcessedVideo(obj, varargin)
            % validate input
            if nargin < 2
                fileExt = 'avi';
            else
                fileExt = varargin{1};
            end
            
            % create movie for each file in fileTable
            for i = 1:height(obj.fileTable)
                % load file
                load(obj.fileTable.path{i}, 'IMcorrREG');
                % prepare allen brain atlas
                atlas = imread(Param().path.abmTemplate);
                % get brain outline with pixels value 0
                brainOutline = atlas == 0;
                % the brain outline should be a single line use bwskel to get the skeleton
                brainOutline = bwskel(brainOutline);
                % convert to double
                brainOutline = double(brainOutline);
                switch fileExt
                    case 'avi'
                        % create movie avi file
                        movieFile = strrep(obj.fileTable.path{i}, '.mat', '_movie.avi');
                        objVideo = VideoWriter(movieFile, 'Uncompressed AVI'); %#ok<TNMLP>
                        objVideo.FrameRate = 10;
                        open(objVideo);
                        fprintf('  Creating movie for %d/%d: %s\n', i, height(obj.fileTable), movieFile);
                        for j = 1:size(IMcorrREG, 3)
                            % rescale frame to [0, 255]
                            frameData = im2uint8(rescale(IMcorrREG(:,:,j)));
                            % make the brain outline black in the image
                            frameData(brainOutline == 1) = 0;
                            % write frame to video
                            writeVideo(objVideo, frameData);
                        end
                        close(objVideo);
                    case 'tif'
                        % create movie tif file
                        movieFile = strrep(obj.fileTable.path{i}, '.mat', '_movie.tif');
                        fprintf('  Creating movie for %d/%d: %s\n', i, height(obj.fileTable), movieFile);
                        for j = 1:size(IMcorrREG, 3)
                            % rescale frame to [0, 255]
                            frameData = im2uint8(rescale(IMcorrREG(:,:,j)));
                            % make the brain outline black in the image
                            frameData(brainOutline == 1) = 0;
                            % write frame to video
                            imwrite(frameData, movieFile, 'WriteMode', 'append');
                        end
                end
            end
        end
    end

end
