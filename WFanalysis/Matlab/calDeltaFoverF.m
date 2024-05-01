function calDeltaFoverF(filePath, varargin)

    cellfun(@(X)calDeltaFoverFhelper(X, varargin{:}), filePath);

end

function calDeltaFoverFhelper(filePath, varargin)
    %% parse inputs
    P = inputParser;
    P.addRequired('filePath', @(x)ischar(x) || isstring(x));
    P.addParameter('overwrite', false, @(x)islogical(x));
    P.addParameter('param', Param, @(x)isa(x, 'Param'));
    parse(P, filePath, varargin{:});
    filePath = P.Results.filePath;
    overwrite = P.Results.overwrite;
    param = P.Results.param;

    %% load the filePath and calculate the deltaFoverF
    fileInfo = who('-file', filePath);

    % if overwrite is true or 'deltaFoverF' does not exist
    if (~ismember('deltaFoverF', fileInfo)) || overwrite

        % calculate the deltaFoverF
        indxBaseline = param.wfAlign.frameTime >= param.wfAlign.alignWin(1) & param.wfAlign.frameTime <= param.wfAlign.alignWin(2);
        
        % load data
        if contains(filePath, 'Raw')
            data = load(filePath, 'IMcorr');
            im = data.IMcorr;
        elseif contains(filePath, 'Reg')
            data = load(filePath, 'IMcorrREG');
            im = data.IMcorrREG;
        else
            error('The file name should contain ''raw'' or ''reg''');
        end

        % scale im to 0-1
        im = (im - min(im(:))) / (max(im(:)) - min(im(:)));

        % calculate the deltaFoverF
        meanFbaseline = mean(im(:, :, indxBaseline), 3);

        % calculate the deltaF/F
        deltaFoverF = (im - meanFbaseline) ./ meanFbaseline;

        % save the result
        save(filePath, 'deltaFoverF', '-append');

        % display the progress
        fprintf('   DeltaFoverF calculated: %s\n', filePath);
    end

end
