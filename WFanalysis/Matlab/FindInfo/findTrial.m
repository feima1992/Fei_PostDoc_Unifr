function argout = findTrial(argin)
    % findTrial returns the trial from a string or cell array of strings
    %   argin: string or cell array of strings
    %   argout: string or cell array of strings

    %% Validate input
    if ischar(argin)
        argin = {argin};
    elseif ~iscellstr(argin) && ~isstring(argin)
        error('findTrial:argin', 'argin must be a string or cell array of strings');
    end

    %% Main Function

    % find trial name
    findTrialFun = @(X)str2double(regexp(X, '(?<=_)\d{3,4}(?=\.tif)', 'match', 'once'));
    argout = findTrialFun(argin);

    % if no match raise error
    if isempty(argout)
        error('findTrial:argout', 'No trial name found in input string');
    end

end