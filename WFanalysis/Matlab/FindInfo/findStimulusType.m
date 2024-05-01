function argout = findStimulusType(argin)
    % findStimulusType returns the stimulusType from a string or cell array of strings
    %   argin: string or cell array of strings
    %   argout: string or cell array of strings

    %% Validate input
    if ischar(argin)
        argin = {argin};
    elseif ~iscellstr(argin) && ~isstring(argin)
        error('findStimulusType:argin', 'argin must be a string or cell array of strings');
    end

    %% Main Function

    % find mouse name
    argout = cellfun(@(X)strsplit(X, '_'), argin, 'UniformOutput', 0);
    argout = cellfun(@(X)X{2}, argout, 'UniformOutput', 0);

    % if no match raise error
    if isempty(argout)
        error('findMouse:argout', 'No mouse name found in input string');
    end

end
