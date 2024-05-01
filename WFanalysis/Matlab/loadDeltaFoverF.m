function fileTable = loadDeltaFoverF(fileTable, varargin)

    fileTable.deltaFoverF = cellfun(@loadDeltaFoverFhelper, fileTable.path, 'UniformOutput', false);

end

function result = loadDeltaFoverFhelper(filePath, varargin)
    % parse inputs
    p = inputParser;
    p.addRequired('filePath', @ischar);
    p.addParameter('frameIdx', 28, @isnumeric);
    parse(p, filePath, varargin{:});
    filePath = p.Results.filePath;
    frameIdx = p.Results.frameIdx;

    % load data
    load(filePath, 'deltaFoverF');
    result = deltaFoverF(:,:,frameIdx);
end