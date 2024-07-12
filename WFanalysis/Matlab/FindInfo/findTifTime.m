function argout = findTifTime(argin)

    %% Validate input
    if ischar(argin)
        argin = {argin};
    elseif ~iscellstr(argin) && ~isstring(argin)
        error('findTrial:argin', 'argin must be a string or cell array of strings');
    end

    %% Main Function

    % find trial name
    findTifTimeFun = @(X)str2double(regexp(X, '(?<=Relative time = )\d*\.\d*', 'match', 'once'));
    argout = findTifTimeFun(argin);

    % if no match raise error
    if isempty(argout)
        error('findTrial:argout', 'No tif time found in input string');
    end

end
